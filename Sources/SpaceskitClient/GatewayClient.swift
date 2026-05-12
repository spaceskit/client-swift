// GatewayClient.swift — Spaceskit WebSocket client (Swift)
//
// Actor-based, async/await throughout, zero external dependencies.
// Uses URLSessionWebSocketTask for transport, CryptoKit for Ed25519 auth.

import Foundation

// MARK: - Configuration

/// Configuration options for the gateway client.
public struct GatewayClientOptions: Sendable {
    /// WebSocket URL of the gateway (e.g. "ws://localhost:9320").
    public let url: URL

    /// Client type identifier sent during authentication.
    public let clientType: String

    /// Client version string.
    public let clientVersion: String

    /// Ed25519 key pair for challenge-response authentication (optional).
    public let authKeyPair: AuthKeyPair?

    /// Optional stable device identifier included in auth/join flows.
    public let deviceId: String?

    /// Optional device identity public key.
    public let devicePublicKey: String?

    /// Optional signature proving possession of device key material.
    public let deviceProofSignature: String?

    /// Whether to auto-reconnect on disconnect. Default: true.
    public let reconnect: Bool

    /// Base reconnect interval in seconds. Default: 3.
    public let reconnectIntervalSec: TimeInterval

    /// Maximum reconnection attempts. Default: 10.
    public let maxReconnectAttempts: Int

    /// Maximum reconnect delay in seconds (caps exponential backoff). Default: 30.
    public let maxReconnectDelaySec: TimeInterval

    /// Request timeout in seconds. Default: 30.
    public let requestTimeoutSec: TimeInterval

    public init(
        url: URL,
        clientType: String = "swift-sdk",
        clientVersion: String = "1.0.0",
        authKeyPair: AuthKeyPair? = nil,
        deviceId: String? = nil,
        devicePublicKey: String? = nil,
        deviceProofSignature: String? = nil,
        reconnect: Bool = true,
        reconnectIntervalSec: TimeInterval = 3,
        maxReconnectAttempts: Int = 10,
        maxReconnectDelaySec: TimeInterval = 30,
        requestTimeoutSec: TimeInterval = 30
    ) {
        self.url = url
        self.clientType = clientType
        self.clientVersion = clientVersion
        self.authKeyPair = authKeyPair
        self.deviceId = deviceId
        self.devicePublicKey = devicePublicKey
        self.deviceProofSignature = deviceProofSignature
        self.reconnect = reconnect
        self.reconnectIntervalSec = reconnectIntervalSec
        self.maxReconnectAttempts = maxReconnectAttempts
        self.maxReconnectDelaySec = maxReconnectDelaySec
        self.requestTimeoutSec = requestTimeoutSec
    }
}

// MARK: - Gateway Event

/// Events emitted by the client.
public enum GatewayEvent: Sendable {
    case turnEvent(TurnEvent)
    case turnStream(TurnStream)
    case spaceState(SpaceState)
    case spaceAgentUpdated(SpaceAgentUpdatedEvent)
    case capabilityInvoke(AdapterCapabilityInvokePayload)
    case notification(GatewayNotification)
    case appNavigate(AppNavigateEvent)
    case conciergeActionRequest(AppConciergeActionRequestPayload)
    case agentMessage(AgentMessage)
    case agentPoke(AgentPoke)
    case agentIdle(AgentIdle)
    case taskDependencyResolved(TaskDependencyResolved)
    case orchestratorEvent(OrchestratorEvent)
    case speechEvent(SpeechSessionEvent)
    case conciergeCallEvent(ConciergeCallEvent)
    case error(GatewayError)
    case connectionStateChanged(ConnectionState)
}

// MARK: - Pending Request

/// Tracks an in-flight request awaiting a response.
struct PendingRequest: Sendable {
    let continuation: UnsafeContinuation<Data, Error>
}

// MARK: - GatewayClient Actor

/// Spaceskit WebSocket client.
///
/// Usage:
/// ```swift
/// let keyPair = AuthKeyPair()
/// let client = GatewayClient(options: .init(
///     url: URL(string: "ws://localhost:9320")!,
///     authKeyPair: keyPair
/// ))
///
/// let events = client.events
/// try await client.connect()
///
/// let result = try await client.executeTurn(.init(
///     spaceUid: "11111111-2222-3333-4444-555555555555",
///     input: "Hello!"
/// ))
/// print(result.output ?? "No output")
///
/// for await event in events {
///     switch event {
///     case .turnStream(let stream): print(stream.delta)
///     default: break
///     }
/// }
/// ```
public actor GatewayClient {
    let options: GatewayClientOptions
    let session: URLSession
    var task: URLSessionWebSocketTask?
    var receiveTask: Task<Void, Never>?

    var state: ConnectionState = .disconnected
    var reconnectAttempts: Int = 0
    var reconnectAllowed = true

    var pendingRequests: [String: PendingRequest] = [:]
    let eventContinuations = EventContinuations()

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    // MARK: - Init

    public init(options: GatewayClientOptions) {
        self.options = options
        self.session = URLSession(configuration: .default)
    }

    // MARK: - Events Stream

    /// An AsyncStream of gateway events. Multiple consumers are supported.
    nonisolated public var events: AsyncStream<GatewayEvent> {
        eventContinuations.makeStream()
    }

    // MARK: - Connection
}
