import Foundation

public struct AdapterInvocationError: Error, Sendable {
    public let code: String
    public let message: String
    public let details: AnyCodable?

    public init(code: String, message: String, details: Any? = nil) {
        self.code = code
        self.message = message
        self.details = details.map(AnyCodable.init)
    }
}

public typealias AdapterOperationHandler =
    @Sendable (_ args: [String: AnyCodable], _ request: AdapterCapabilityInvokePayload) async throws -> AnyCodable?

public struct GatewayAdapterProviderRegistration: Sendable {
    public let provider: AdapterCapabilityProvider
    public let handlers: [String: AdapterOperationHandler]

    public init(
        provider: AdapterCapabilityProvider,
        handlers: [String: AdapterOperationHandler]
    ) {
        self.provider = provider
        self.handlers = handlers
    }
}

public struct GatewayAdapterClientOptions: Sendable {
    public let url: URL
    public let clientVersion: String
    public let authKeyPair: AuthKeyPair?
    public let deviceId: String?
    public let devicePublicKey: String?
    public let deviceProofSignature: String?
    public let reconnect: Bool
    public let reconnectIntervalSec: TimeInterval
    public let maxReconnectAttempts: Int
    public let requestTimeoutSec: TimeInterval

    public init(
        url: URL,
        clientVersion: String = "1.0.0",
        authKeyPair: AuthKeyPair? = nil,
        deviceId: String? = nil,
        devicePublicKey: String? = nil,
        deviceProofSignature: String? = nil,
        reconnect: Bool = true,
        reconnectIntervalSec: TimeInterval = 3,
        maxReconnectAttempts: Int = 10,
        requestTimeoutSec: TimeInterval = 30
    ) {
        self.url = url
        self.clientVersion = clientVersion
        self.authKeyPair = authKeyPair
        self.deviceId = deviceId
        self.devicePublicKey = devicePublicKey
        self.deviceProofSignature = deviceProofSignature
        self.reconnect = reconnect
        self.reconnectIntervalSec = reconnectIntervalSec
        self.maxReconnectAttempts = maxReconnectAttempts
        self.requestTimeoutSec = requestTimeoutSec
    }
}

public actor GatewayAdapterClient {
    private let gatewayClient: GatewayClient
    private var providers: [String: GatewayAdapterProviderRegistration] = [:]
    private var invokeTask: Task<Void, Never>?
    private var providerSyncInFlight = false
    private var providerSyncDirty = false
    private var providerSyncRecoveryTask: Task<Void, Never>?
    private static let providerSyncMaxAttempts = 8
    private static let providerSyncRetryDelayNanoseconds: UInt64 = 150_000_000
    private static let providerSyncRecoveryMaxAttempts = 12
    private static let providerSyncRecoveryRetryDelayNanoseconds: UInt64 = 300_000_000

    public init(options: GatewayAdapterClientOptions) {
        self.gatewayClient = GatewayClient(options: .init(
            url: options.url,
            clientType: "adapter",
            clientVersion: options.clientVersion,
            authKeyPair: options.authKeyPair,
            deviceId: options.deviceId,
            devicePublicKey: options.devicePublicKey,
            deviceProofSignature: options.deviceProofSignature,
            reconnect: options.reconnect,
            reconnectIntervalSec: options.reconnectIntervalSec,
            maxReconnectAttempts: options.maxReconnectAttempts,
            requestTimeoutSec: options.requestTimeoutSec
        ))
    }

    public var isConnected: Bool {
        get async {
            await gatewayClient.connectionState == .connected
        }
    }

    public func connect() async throws {
        try await gatewayClient.connect()
        startInvocationListener()
        try await requestProviderSync()
    }

    public func disconnect() async {
        invokeTask?.cancel()
        invokeTask = nil
        providerSyncRecoveryTask?.cancel()
        providerSyncRecoveryTask = nil

        if await gatewayClient.connectionState == .connected, !providers.isEmpty {
            try? await gatewayClient.deregisterCapabilities(Array(providers.keys))
        }

        await gatewayClient.disconnect()
    }

    public func registerProvider(_ registration: GatewayAdapterProviderRegistration) async throws {
        providers[registration.provider.id] = registration
        try await requestProviderSync()
    }

    public func registerProviders(_ registrations: [GatewayAdapterProviderRegistration]) async throws {
        for registration in registrations {
            providers[registration.provider.id] = registration
        }
        try await requestProviderSync()
    }

    public func deregisterProvider(providerId: String) async throws {
        providers.removeValue(forKey: providerId)
        if await gatewayClient.connectionState == .connected {
            try await gatewayClient.deregisterCapabilities([providerId])
        }
    }

    public func sendCapabilityResult(_ payload: CapabilityResultPayload) async throws {
        try await gatewayClient.sendCapabilityResult(payload)
    }

    public func sendCapabilityError(_ payload: CapabilityErrorPayload) async throws {
        try await gatewayClient.sendCapabilityError(payload)
    }

    private func startInvocationListener() {
        invokeTask?.cancel()
        let events = gatewayClient.events
        invokeTask = Task { [weak self] in
            for await event in events {
                guard let self else { break }
                switch event {
                case .capabilityInvoke(let request):
                    await self.handleInvocation(request)
                case .connectionStateChanged(let state):
                    guard state == .connected else { continue }
                    await self.kickProviderSyncRecovery()
                default:
                    continue
                }
            }
        }
    }

    private func handleInvocation(_ request: AdapterCapabilityInvokePayload) async {
        let provider = providerRegistration(for: request)
        guard let provider else {
            try? await gatewayClient.sendCapabilityError(CapabilityErrorPayload(
                invocationId: request.invocationId,
                providerId: request.targetProvider,
                code: "PROVIDER_NOT_FOUND",
                message: "No adapter provider found for invocation (\(request.capability).\(request.operation))."
            ))
            return
        }

        guard let handler = provider.handlers[request.operation] else {
            try? await gatewayClient.sendCapabilityError(CapabilityErrorPayload(
                invocationId: request.invocationId,
                providerId: provider.provider.id,
                code: "OPERATION_NOT_SUPPORTED",
                message: "Operation not supported: \(request.operation)"
            ))
            return
        }

        let started = Date()
        do {
            let data = try await handler(request.args, request)
            let durationMs = Date().timeIntervalSince(started) * 1000
            try await gatewayClient.sendCapabilityResult(CapabilityResultPayload(
                invocationId: request.invocationId,
                providerId: provider.provider.id,
                dataCodable: data,
                durationMs: durationMs
            ))
        } catch {
            if let invocationError = error as? AdapterInvocationError {
                try? await gatewayClient.sendCapabilityError(CapabilityErrorPayload(
                    invocationId: request.invocationId,
                    providerId: provider.provider.id,
                    code: invocationError.code,
                    message: invocationError.message,
                    details: invocationError.details?.value
                ))
                return
            }

            try? await gatewayClient.sendCapabilityError(CapabilityErrorPayload(
                invocationId: request.invocationId,
                providerId: provider.provider.id,
                code: "INVOKE_FAILED",
                message: error.localizedDescription
            ))
        }
    }

    private func providerRegistration(for request: AdapterCapabilityInvokePayload) -> GatewayAdapterProviderRegistration? {
        if let targetProvider = request.targetProvider {
            return providers[targetProvider]
        }

        return providers.values.first(where: { registration in
            registration.provider.capabilityType == request.capability
        })
    }

    private func requestProviderSync() async throws {
        guard await gatewayClient.connectionState == .connected else { return }
        guard !providers.isEmpty else { return }

        if providerSyncInFlight {
            providerSyncDirty = true
            return
        }

        repeat {
            providerSyncDirty = false
            providerSyncInFlight = true
            defer { providerSyncInFlight = false }
            try await syncProvidersWithRetry()
        } while providerSyncDirty
    }

    private func syncProvidersWithRetry() async throws {
        let providerList = Array(providers.values).map(\.provider)
        var lastError: Error?

        for attempt in 0..<Self.providerSyncMaxAttempts {
            guard await gatewayClient.connectionState == .connected else { return }
            do {
                try await gatewayClient.registerCapabilities(providerList)
                return
            } catch {
                lastError = error
                guard isAuthRaceError(error) else { throw error }
                let backoff = Self.providerSyncRetryDelayNanoseconds * UInt64(attempt + 1)
                try? await Task.sleep(nanoseconds: backoff)
            }
        }

        if let lastError {
            throw lastError
        }
    }

    private func kickProviderSyncRecovery() {
        guard providerSyncRecoveryTask == nil else {
            providerSyncDirty = true
            return
        }

        providerSyncRecoveryTask = Task { [weak self] in
            guard let self else { return }
            await self.runProviderSyncRecoveryLoop()
        }
    }

    private func runProviderSyncRecoveryLoop() async {
        defer {
            providerSyncRecoveryTask = nil
        }

        var attempt = 0
        while attempt < Self.providerSyncRecoveryMaxAttempts {
            do {
                try await requestProviderSync()
                return
            } catch {
                guard await gatewayClient.connectionState == .connected else {
                    return
                }
                attempt += 1
                let backoff = Self.providerSyncRecoveryRetryDelayNanoseconds * UInt64(attempt)
                try? await Task.sleep(nanoseconds: backoff)
            }
        }
    }

    private func isAuthRaceError(_ error: Error) -> Bool {
        if let gatewayError = error as? GatewayError {
            if gatewayError.code.uppercased() == "UNAUTHENTICATED" {
                return true
            }
            let message = gatewayError.message.lowercased()
            return message.contains("unauthenticated") || message.contains("authentication")
        }

        let message = error.localizedDescription.lowercased()
        return message.contains("unauthenticated") || message.contains("authentication")
    }
}
