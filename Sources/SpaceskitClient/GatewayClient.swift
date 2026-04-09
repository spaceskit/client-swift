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
private struct PendingRequest: Sendable {
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
    private let options: GatewayClientOptions
    private let session: URLSession
    private var task: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?

    private var state: ConnectionState = .disconnected
    private var reconnectAttempts: Int = 0
    private var reconnectAllowed = true

    private var pendingRequests: [String: PendingRequest] = [:]
    private let eventContinuations = EventContinuations()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

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

    /// Connect to the Spaceskit.
    public func connect() async throws {
        reconnectAllowed = true
        guard state == .disconnected || {
            if case .reconnecting = state { return true }
            return false
        }() else {
            return // Already connected or connecting
        }

        setState(.connecting)

        let request = URLRequest(url: options.url)
        task = session.webSocketTask(with: request)
        task?.resume()

        // Confirm the WebSocket handshake by attempting the first receive.
        // URLSessionWebSocketTask.resume() is non-blocking — the connection
        // may fail immediately (e.g. -1004 Connection Refused). Only move
        // to .connected once we know the transport is alive.
        guard let ws = task else {
            setState(.disconnected)
            return
        }

        do {
            let firstMessage = try await ws.receive()
            // Handshake succeeded — transport is up, but auth hasn't completed yet.
            // The authResult handler will promote state to .connected
            // after the Ed25519 challenge/response succeeds.
            setState(.authenticating)
            reconnectAttempts = 0

            // Process the first message we already received
            switch firstMessage {
            case .string(let text):
                if let data = text.data(using: .utf8) {
                    await handleMessage(data)
                }
            case .data(let data):
                await handleMessage(data)
            @unknown default:
                break
            }

            // Continue receiving
            receiveTask = Task { [weak self] in
                await self?.receiveLoop()
            }
        } catch {
            // Connection failed during handshake — don't set .connected
            task?.cancel(with: .abnormalClosure, reason: nil)
            task = nil
            throw error
        }
    }

    /// Disconnect from the gateway.
    public func disconnect() {
        reconnectAllowed = false
        receiveTask?.cancel()
        receiveTask = nil
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        setState(.disconnected)

        // Reject all pending requests
        for (_, pending) in pendingRequests {
            pending.continuation.resume(throwing: GatewayError(
                code: "DISCONNECTED",
                message: "Client disconnected",
                details: nil
            ))
        }
        pendingRequests.removeAll()
    }

    /// Current connection state.
    public var connectionState: ConnectionState { state }

    // MARK: - API Methods

    /// Execute a turn in a space.
    public func executeTurn(
        _ options: ExecuteTurnOptions
    ) async throws -> TurnResult {
        let payload = ExecuteTurnPayload(options)
        let data = try await sendAndWait(type: MessageType.executeTurn, payload: payload)
        return try decoder.decode(TurnResult.self, from: data)
    }

    /// Cancel an active or paused turn.
    public func cancelTurn(
        spaceUid: String,
        turnId: String
    ) async throws {
        let payload: [String: String] = ["spaceUid": spaceUid, "turnId": turnId]
        _ = try await sendAndWait(type: MessageType.cancelTurn, payload: payload)
    }

    /// Execute a turn in a space.
    public func executeTurn(
        spaceUid: String,
        input: String,
        targetAgentId: String? = nil,
        replyToTurnId: String? = nil,
        mode: String? = nil,
        effort: String? = nil,
        accessMode: String? = nil
    ) async throws -> TurnResult {
        try await executeTurn(
            ExecuteTurnOptions(
                spaceUid: spaceUid,
                input: input,
                targetAgentId: targetAgentId,
                replyToTurnId: replyToTurnId,
                mode: mode,
                effort: effort,
                accessMode: accessMode
            )
        )
    }

    /// Execute a turn and return the immediate lifecycle event ack.
    public func executeTurnEvent(
        _ options: ExecuteTurnOptions
    ) async throws -> TurnEvent {
        let payload = ExecuteTurnPayload(options)
        let data = try await sendAndWait(type: MessageType.executeTurn, payload: payload)
        do {
            return try decoder.decode(TurnEvent.self, from: data)
        } catch {
            // Backward compatibility: some gateways can reply with a minimal
            // ack shape lacking full TurnEvent fields.
            if let compat = try? decoder.decode(ExecuteTurnAckCompat.self, from: data),
               !compat.turnId.isEmpty {
                let ackSpaceUid = compat.spaceUid ?? options.spaceUid
                let ackSpaceId = compat.spaceId ?? ackSpaceUid
                return TurnEvent(
                    spaceId: ackSpaceId,
                    spaceUid: ackSpaceUid,
                    turnId: compat.turnId,
                    eventType: compat.eventType ?? "started",
                    data: compat.data
                )
            }
            throw error
        }
    }

    /// Execute a turn and return the immediate lifecycle event ack.
    public func executeTurnEvent(
        spaceUid: String,
        input: String,
        targetAgentId: String? = nil,
        replyToTurnId: String? = nil,
        mode: String? = nil,
        effort: String? = nil,
        accessMode: String? = nil
    ) async throws -> TurnEvent {
        try await executeTurnEvent(
            ExecuteTurnOptions(
                spaceUid: spaceUid,
                input: input,
                targetAgentId: targetAgentId,
                replyToTurnId: replyToTurnId,
                mode: mode,
                effort: effort,
                accessMode: accessMode
            )
        )
    }

    /// Resume a paused turn with feedback.
    public func resumeFeedback(
        spaceUid: String,
        turnId: String,
        response: FeedbackResponse,
        revision: String? = nil,
        approvalGrant: ApprovalGrantPayload? = nil
    ) async throws {
        let payload = ResumeFeedbackPayload(
            spaceUid: spaceUid,
            turnId: turnId,
            response: response,
            revision: revision,
            approvalGrant: approvalGrant
        )
        _ = try await sendAndWait(type: MessageType.resumeFeedback, payload: payload)
    }

    /// Subscribe to space events.
    public func subscribe(spaceUids: [String]) async throws {
        let payload = SubscribePayload(spaceUids: spaceUids)
        let data = try await sendAndWait(type: MessageType.subscribe, payload: payload)
        let normalizedRequested = Set(
            spaceUids
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
        if normalizedRequested.isEmpty {
            return
        }

        let response = try decoder.decode(SubscribeResponsePayload.self, from: data)
        let normalizedSubscribed = Set(
            response.subscribedSpaceUids
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )

        if normalizedRequested.isDisjoint(with: normalizedSubscribed) {
            throw GatewayError(
                code: "SUBSCRIBE_DENIED",
                message: "Subscription denied for requested spaces: \(normalizedRequested.sorted().joined(separator: ", "))",
                details: nil
            )
        }
    }

    public func subscribeNotifications(categories: [String]) async throws -> [String] {
        let payload = SubscribeNotificationsPayload(categories: categories)
        let data = try await sendAndWait(type: MessageType.subscribeNotifications, payload: payload)
        let response = try decoder.decode(NotificationSubscriptionResponsePayload.self, from: data)
        return response.categories
    }

    public func unsubscribeNotifications(categories: [String]) async throws -> [String] {
        let payload = UnsubscribeNotificationsPayload(categories: categories)
        let data = try await sendAndWait(type: MessageType.unsubscribeNotifications, payload: payload)
        let response = try decoder.decode(NotificationSubscriptionResponsePayload.self, from: data)
        return response.categories
    }

    public func sendConciergeActionResult(_ payload: ConciergeActionResultPayload) async throws {
        let data = try await sendAndWait(type: MessageType.conciergeActionResult, payload: payload)
        _ = try decoder.decode(ConciergeActionResultAckPayload.self, from: data)
    }

    /// Invoke a capability on the gateway.
    public func invokeCapability(
        capability: String,
        method: String,
        params: [String: Any],
        targetProvider: String? = nil
    ) async throws -> CapabilityResult {
        let payload = CapabilityInvokePayload(
            capability: capability,
            method: method,
            params: params,
            targetProvider: targetProvider
        )
        let data = try await sendAndWait(type: MessageType.capabilityInvoke, payload: payload)
        return try decoder.decode(CapabilityResult.self, from: data)
    }

    /// Register native adapter providers with the gateway.
    public func registerCapabilities(_ providers: [AdapterCapabilityProvider]) async throws {
        let payload = CapabilitiesRegisterPayload(providers: providers)
        _ = try await sendAndWait(type: MessageType.capabilitiesRegister, payload: payload)
    }

    /// Deregister native adapter providers from the gateway.
    public func deregisterCapabilities(_ providerIds: [String]) async throws {
        let payload = CapabilitiesDeregisterPayload(providerIds: providerIds)
        _ = try await sendAndWait(type: MessageType.capabilitiesDeregister, payload: payload)
    }

    /// Send invocation success for a previously received `capability.invoke`.
    public func sendCapabilityResult(_ payload: CapabilityResultPayload) async throws {
        _ = try await send(type: MessageType.capabilityResult, payload: payload)
    }

    /// Send invocation failure for a previously received `capability.invoke`.
    public func sendCapabilityError(_ payload: CapabilityErrorPayload) async throws {
        _ = try await send(type: MessageType.capabilityError, payload: payload)
    }

    /// Create a new space on the gateway.
    public func createSpace(_ payload: SpaceCreatePayload) async throws -> SpaceConfig {
        let data = try await sendAndWait(type: MessageType.spaceCreate, payload: payload)
        let response = try decoder.decode(SpaceCreateResponsePayload.self, from: data)
        return response.space
    }

    /// Get a single space by ID.
    public func getSpace(spaceId: String, apiVersion: String? = nil) async throws -> SpaceConfig {
        let payload = SpaceGetPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceGet, payload: payload)
        let response = try decoder.decode(SpaceGetResponsePayload.self, from: data)
        return response.space
    }

    /// List spaces with optional filters.
    public func listSpaces(
        apiVersion: String? = nil,
        statuses: [String]? = nil,
        resourceId: String? = nil,
        limit: Int? = nil
    ) async throws -> [SpaceConfig] {
        let payload = SpaceListPayload(
            apiVersion: apiVersion,
            statuses: statuses,
            resourceId: resourceId,
            limit: limit
        )
        let data = try await sendAndWait(type: MessageType.spaceList, payload: payload)
        let response = try decoder.decode(SpaceListResponsePayload.self, from: data)
        return response.spaces
    }

    /// Archive a space on the gateway.
    public func archiveSpace(_ payload: SpaceArchivePayload) async throws -> SpaceArchiveResponsePayload {
        let data = try await sendAndWait(type: MessageType.spaceArchive, payload: payload)
        return try decoder.decode(SpaceArchiveResponsePayload.self, from: data)
    }

    /// Soft-delete a space on the gateway.
    public func deleteSpace(_ payload: SpaceDeletePayload) async throws -> SpaceDeleteResponsePayload {
        let data = try await sendAndWait(type: MessageType.spaceDelete, payload: payload)
        return try decoder.decode(SpaceDeleteResponsePayload.self, from: data)
    }

    /// Update the editable metadata for a space.
    public func updateSpaceMetadata(_ payload: SpaceUpdateMetadataPayload) async throws -> SpaceConfig {
        let data = try await sendAndWait(type: MessageType.spaceUpdateMetadata, payload: payload)
        let response = try decoder.decode(SpaceUpdateMetadataResponsePayload.self, from: data)
        return response.space
    }

    /// Add an agent assignment to a space.
    public func addAgent(_ payload: SpaceAddAgentPayload) async throws -> SpaceAddAgentResult {
        let data = try await sendAndWait(type: MessageType.spaceAddAgent, payload: payload)
        let response = try decoder.decode(SpaceAddAgentResponsePayload.self, from: data)
        return SpaceAddAgentResult(assignment: response.assignment, space: response.space)
    }

    /// Remove an agent assignment from a space.
    public func removeAgent(_ payload: SpaceRemoveAgentPayload) async throws -> SpaceRemoveAgentResult {
        let data = try await sendAndWait(type: MessageType.spaceRemoveAgent, payload: payload)
        let response = try decoder.decode(SpaceRemoveAgentResponsePayload.self, from: data)
        return SpaceRemoveAgentResult(
            removed: response.removed,
            spaceId: response.spaceId,
            spaceUid: response.spaceUid,
            agentId: response.agentId,
            space: response.space
        )
    }

    /// Update an existing agent assignment in a space.
    public func updateAgentAssignment(
        _ payload: SpaceUpdateAgentAssignmentPayload
    ) async throws -> SpaceUpdateAgentAssignmentResult {
        let data = try await sendAndWait(type: MessageType.spaceUpdateAgentAssignment, payload: payload)
        let response = try decoder.decode(SpaceUpdateAgentAssignmentResponsePayload.self, from: data)
        return SpaceUpdateAgentAssignmentResult(assignment: response.assignment, space: response.space)
    }

    /// Set the orchestrator profile for a space.
    public func setSpaceOrchestrator(_ payload: SpaceSetOrchestratorPayload) async throws -> SpaceConfig {
        let data = try await sendAndWait(type: MessageType.spaceSetOrchestrator, payload: payload)
        let response = try decoder.decode(SpaceGetResponsePayload.self, from: data)
        return response.space
    }

    /// Set the thinking-capture persistence policy for a space.
    public func setThinkingCapturePolicy(_ payload: SpaceSetThinkingCapturePolicyPayload) async throws -> SpaceConfig {
        let data = try await sendAndWait(type: MessageType.spaceSetThinkingCapturePolicy, payload: payload)
        let response = try decoder.decode(SpaceSetThinkingCapturePolicyResponsePayload.self, from: data)
        return response.space
    }

    public func getSpaceMemoryPolicy(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> SpaceMemoryPolicy {
        let payload = SpaceGetMemoryPolicyPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceGetMemoryPolicy, payload: payload)
        let response = try decoder.decode(SpaceGetMemoryPolicyResponsePayload.self, from: data)
        return response.memoryPolicy
    }

    public func setSpaceMemoryPolicy(_ payload: SpaceSetMemoryPolicyPayload) async throws -> SpaceConfig {
        let data = try await sendAndWait(type: MessageType.spaceSetMemoryPolicy, payload: payload)
        let response = try decoder.decode(SpaceSetMemoryPolicyResponsePayload.self, from: data)
        return response.space
    }

    public func endIncognitoSession(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> SpaceEndIncognitoSessionResponsePayload {
        let payload = SpaceEndIncognitoSessionPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceEndIncognitoSession, payload: payload)
        return try decoder.decode(SpaceEndIncognitoSessionResponsePayload.self, from: data)
    }

    /// List all agent assignments for a space.
    public func listAgentAssignments(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> [SpaceAgentAssignment] {
        let payload = SpaceListAgentAssignmentsPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceListAgentAssignments, payload: payload)
        let response = try decoder.decode(SpaceListAgentAssignmentsResponsePayload.self, from: data)
        return response.assignments
    }

    /// Fetch the configured MCP endpoint for one space, if any.
    public func getMcpEndpoint(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> SpaceMcpEndpoint? {
        let payload = SpaceGetMcpEndpointPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceGetMcpEndpoint, payload: payload)
        let response = try decoder.decode(SpaceGetMcpEndpointResponsePayload.self, from: data)
        return response.endpoint
    }

    /// Create or update the MCP endpoint configuration for one space.
    public func setMcpEndpoint(_ payload: SpaceSetMcpEndpointPayload) async throws -> SpaceMcpEndpoint {
        let data = try await sendAndWait(type: MessageType.spaceSetMcpEndpoint, payload: payload)
        let response = try decoder.decode(SpaceSetMcpEndpointResponsePayload.self, from: data)
        return response.endpoint
    }

    /// Remove the MCP endpoint configuration for one space.
    public func clearMcpEndpoint(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> Bool {
        let payload = SpaceClearMcpEndpointPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceClearMcpEndpoint, payload: payload)
        let response = try decoder.decode(SpaceClearMcpEndpointResponsePayload.self, from: data)
        return response.cleared
    }

    /// Add one skill assignment to a space.
    public func addSkillToSpace(_ payload: SpaceAddSkillPayload) async throws -> SpaceAddSkillResponsePayload {
        let data = try await sendAndWait(type: MessageType.spaceAddSkill, payload: payload)
        return try decoder.decode(SpaceAddSkillResponsePayload.self, from: data)
    }

    /// Remove one skill assignment from a space.
    public func removeSkillFromSpace(_ payload: SpaceRemoveSkillPayload) async throws -> SpaceRemoveSkillResponsePayload {
        let data = try await sendAndWait(type: MessageType.spaceRemoveSkill, payload: payload)
        return try decoder.decode(SpaceRemoveSkillResponsePayload.self, from: data)
    }

    /// List all skills assigned to a space.
    public func listSpaceSkills(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> [String] {
        let payload = SpaceListSkillsPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceListSkills, payload: payload)
        let response = try decoder.decode(SpaceListSkillsResponsePayload.self, from: data)
        return response.skills
    }

    /// Fetch effective workspace layout/binding for one space.
    public func getSpaceWorkspace(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> SpaceWorkspace {
        let payload = SpaceGetWorkspacePayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceGetWorkspace, payload: payload)
        let response = try decoder.decode(SpaceGetWorkspaceResponsePayload.self, from: data)
        return response.workspace
    }

    /// Set or clear the folder binding for one space.
    public func setSpaceWorkspace(_ payload: SpaceSetWorkspacePayload) async throws -> SpaceWorkspace {
        let data = try await sendAndWait(type: MessageType.spaceSetWorkspace, payload: payload)
        let response = try decoder.decode(SpaceSetWorkspaceResponsePayload.self, from: data)
        return response.workspace
    }

    /// Open an existing folder/repo on the gateway host and resolve it to a space binding.
    public func openSpaceWorkspace(_ payload: SpaceOpenWorkspacePayload) async throws -> SpaceOpenWorkspaceResult {
        let data = try await sendAndWait(type: MessageType.spaceOpenWorkspace, payload: payload)
        let response = try decoder.decode(SpaceOpenWorkspaceResponsePayload.self, from: data)
        return response.result
    }

    /// Add one resource assignment to a space.
    public func addSpaceResource(_ payload: SpaceAddResourcePayload) async throws -> SpaceResource {
        let data = try await sendAndWait(type: MessageType.spaceAddResource, payload: payload)
        let response = try decoder.decode(SpaceAddResourceResponsePayload.self, from: data)
        return response.resource
    }

    /// Remove one resource assignment from a space.
    public func removeSpaceResource(_ payload: SpaceRemoveResourcePayload) async throws -> Bool {
        let data = try await sendAndWait(type: MessageType.spaceRemoveResource, payload: payload)
        let response = try decoder.decode(SpaceRemoveResourceResponsePayload.self, from: data)
        return response.removed
    }

    /// List all resources assigned to a space.
    public func listSpaceResources(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> [SpaceResource] {
        let payload = SpaceListResourcesPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceListResources, payload: payload)
        let response = try decoder.decode(SpaceListResourcesResponsePayload.self, from: data)
        return response.resources
    }

    /// List persisted turns for a space with deterministic pagination.
    public func listSpaceTurns(
        spaceId: String? = nil,
        spaceUid: String? = nil,
        limit: Int = 100,
        offset: Int = 0,
        lastSeenTurnId: String? = nil,
        apiVersion: String? = nil
    ) async throws -> SpaceListTurnsResult {
        let normalizedSpaceIdRaw = spaceId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSpaceUidRaw = spaceUid?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedLastSeenTurnIdRaw = lastSeenTurnId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSpaceId = (normalizedSpaceIdRaw?.isEmpty == false) ? normalizedSpaceIdRaw : nil
        let normalizedSpaceUid = (normalizedSpaceUidRaw?.isEmpty == false) ? normalizedSpaceUidRaw : nil
        let normalizedLastSeenTurnId = (normalizedLastSeenTurnIdRaw?.isEmpty == false) ? normalizedLastSeenTurnIdRaw : nil
        guard normalizedSpaceId != nil || normalizedSpaceUid != nil else {
            throw GatewayError(
                code: "INVALID_ARGUMENT",
                message: "spaceId or spaceUid is required",
                details: nil
            )
        }
        guard limit > 0 else {
            throw GatewayError(
                code: "INVALID_ARGUMENT",
                message: "limit must be greater than 0",
                details: nil
            )
        }
        guard normalizedLastSeenTurnId != nil || offset >= 0 else {
            throw GatewayError(
                code: "INVALID_ARGUMENT",
                message: "offset must be >= 0",
                details: nil
            )
        }

        let payload = SpaceListTurnsPayload(
            apiVersion: apiVersion,
            spaceId: normalizedSpaceId,
            spaceUid: normalizedSpaceUid,
            limit: limit,
            offset: offset,
            lastSeenTurnId: normalizedLastSeenTurnId
        )
        let data = try await sendAndWait(type: MessageType.spaceListTurns, payload: payload)
        let response = try decoder.decode(SpaceListTurnsResponsePayload.self, from: data)
        return SpaceListTurnsResult(
            spaceId: response.spaceId,
            spaceUid: response.spaceUid,
            turns: response.turns,
            total: response.total,
            nextOffset: response.nextOffset
        )
    }

    /// List redacted orchestration journal entries for a space with deterministic pagination.
    public func listOrchestrationJournal(
        spaceId: String? = nil,
        spaceUid: String? = nil,
        turnId: String? = nil,
        limit: Int = 50,
        offset: Int = 0,
        apiVersion: String? = nil
    ) async throws -> SpaceListOrchestrationJournalResult {
        let normalizedSpaceIdRaw = spaceId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSpaceUidRaw = spaceUid?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTurnIdRaw = turnId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSpaceId = (normalizedSpaceIdRaw?.isEmpty == false) ? normalizedSpaceIdRaw : nil
        let normalizedSpaceUid = (normalizedSpaceUidRaw?.isEmpty == false) ? normalizedSpaceUidRaw : nil
        let normalizedTurnId = (normalizedTurnIdRaw?.isEmpty == false) ? normalizedTurnIdRaw : nil

        guard normalizedSpaceId != nil || normalizedSpaceUid != nil else {
            throw GatewayError(
                code: "INVALID_ARGUMENT",
                message: "spaceId or spaceUid is required",
                details: nil
            )
        }
        guard limit > 0 else {
            throw GatewayError(
                code: "INVALID_ARGUMENT",
                message: "limit must be greater than 0",
                details: nil
            )
        }
        guard offset >= 0 else {
            throw GatewayError(
                code: "INVALID_ARGUMENT",
                message: "offset must be >= 0",
                details: nil
            )
        }

        let payload = SpaceListOrchestrationJournalPayload(
            apiVersion: apiVersion,
            spaceId: normalizedSpaceId,
            spaceUid: normalizedSpaceUid,
            turnId: normalizedTurnId,
            limit: limit,
            offset: offset
        )
        let data = try await sendAndWait(type: MessageType.spaceListOrchestrationJournal, payload: payload)
        let response = try decoder.decode(SpaceListOrchestrationJournalResponsePayload.self, from: data)
        return SpaceListOrchestrationJournalResult(
            spaceId: response.spaceId,
            spaceUid: response.spaceUid,
            entries: response.entries,
            total: response.total,
            nextOffset: response.nextOffset
        )
    }

    /// Read space usage snapshot, including optional per-agent sessions and global lifetime totals.
    public func getSpaceUsage(_ payload: SpaceGetUsagePayload) async throws -> SpaceGetUsageResult {
        let data = try await sendAndWait(type: MessageType.spaceGetUsage, payload: payload)
        return try decoder.decode(SpaceGetUsageResult.self, from: data)
    }

    /// Read merged activity-log entries for one space, optionally scoped to one turn.
    public func listActivityLog(_ payload: SpaceListActivityLogPayload) async throws -> SpaceListActivityLogResult {
        let data = try await sendAndWait(type: MessageType.spaceListActivityLog, payload: payload)
        return try decoder.decode(SpaceListActivityLogResult.self, from: data)
    }

    /// Read sanitized turn trace for one turn.
    public func getTurnTrace(_ payload: SpaceGetTurnTracePayload) async throws -> SpaceTurnTrace {
        let data = try await sendAndWait(type: MessageType.spaceGetTurnTrace, payload: payload)
        let response = try decoder.decode(SpaceGetTurnTraceResult.self, from: data)
        return response.trace
    }

    public func listExperiences(_ payload: SpaceListExperiencesPayload) async throws -> SpaceListExperiencesResult {
        let data = try await sendAndWait(type: MessageType.spaceListExperiences, payload: payload)
        return try decoder.decode(SpaceListExperiencesResult.self, from: data)
    }

    public func getExperience(_ payload: SpaceGetExperiencePayload) async throws -> SpaceExperienceRecord {
        let data = try await sendAndWait(type: MessageType.spaceGetExperience, payload: payload)
        let response = try decoder.decode(SpaceGetExperienceResult.self, from: data)
        return response.experience
    }

    public func listInsights(_ payload: SpaceListInsightsPayload) async throws -> SpaceListInsightsResult {
        let data = try await sendAndWait(type: MessageType.spaceListInsights, payload: payload)
        return try decoder.decode(SpaceListInsightsResult.self, from: data)
    }

    public func getInsight(_ payload: SpaceGetInsightPayload) async throws -> SpacePersonalityInsightRecord {
        let data = try await sendAndWait(type: MessageType.spaceGetInsight, payload: payload)
        let response = try decoder.decode(SpaceGetInsightResult.self, from: data)
        return response.insight
    }

    public func acceptInsight(_ payload: SpaceAcceptInsightPayload) async throws -> SpacePersonalityInsightRecord {
        let data = try await sendAndWait(type: MessageType.spaceAcceptInsight, payload: payload)
        let response = try decoder.decode(SpaceInsightActionResult.self, from: data)
        return response.insight
    }

    public func rejectInsight(_ payload: SpaceRejectInsightPayload) async throws -> SpacePersonalityInsightRecord {
        let data = try await sendAndWait(type: MessageType.spaceRejectInsight, payload: payload)
        let response = try decoder.decode(SpaceInsightActionResult.self, from: data)
        return response.insight
    }

    public func dismissInsight(_ payload: SpaceDismissInsightPayload) async throws -> SpacePersonalityInsightRecord {
        let data = try await sendAndWait(type: MessageType.spaceDismissInsight, payload: payload)
        let response = try decoder.decode(SpaceInsightActionResult.self, from: data)
        return response.insight
    }

    public func getSpaceAgentNotes(_ payload: SpaceGetSpaceAgentNotesPayload) async throws -> SpaceAgentNotesRecord? {
        let data = try await sendAndWait(type: MessageType.spaceGetSpaceAgentNotes, payload: payload)
        let response = try decoder.decode(SpaceAgentNotesResult.self, from: data)
        return response.notes
    }

    public func updateSpaceAgentNotes(_ payload: SpaceUpdateSpaceAgentNotesPayload) async throws -> SpaceAgentNotesRecord? {
        let data = try await sendAndWait(type: MessageType.spaceUpdateSpaceAgentNotes, payload: payload)
        let response = try decoder.decode(SpaceAgentNotesResult.self, from: data)
        return response.notes
    }

    public func getUserProfile(_ payload: SpaceGetUserProfilePayload = SpaceGetUserProfilePayload()) async throws -> SpaceUserProfileRecord? {
        let data = try await sendAndWait(type: MessageType.spaceGetUserProfile, payload: payload)
        let response = try decoder.decode(SpaceUserProfileResult.self, from: data)
        return response.profile
    }

    public func updateUserProfile(_ payload: SpaceUpdateUserProfilePayload) async throws -> SpaceUserProfileRecord? {
        let data = try await sendAndWait(type: MessageType.spaceUpdateUserProfile, payload: payload)
        let response = try decoder.decode(SpaceUserProfileResult.self, from: data)
        return response.profile
    }

    public func listMemories(_ payload: SpaceListMemoriesPayload) async throws -> SpaceListMemoriesResult {
        let data = try await sendAndWait(type: MessageType.spaceListMemories, payload: payload)
        return try decoder.decode(SpaceListMemoriesResult.self, from: data)
    }

    public func deleteMemory(_ payload: SpaceDeleteMemoryPayload) async throws -> SpaceDeleteMemoryResult {
        let data = try await sendAndWait(type: MessageType.spaceDeleteMemory, payload: payload)
        return try decoder.decode(SpaceDeleteMemoryResult.self, from: data)
    }

    public func updateMemoryImportance(_ payload: SpaceUpdateMemoryImportancePayload) async throws -> SpaceMemoryRecord {
        let data = try await sendAndWait(type: MessageType.spaceUpdateMemoryImportance, payload: payload)
        let response = try decoder.decode(SpaceUpdateMemoryImportanceResult.self, from: data)
        return response.memory
    }

    /// List artifacts in a space, optionally scoped to one turn.
    public func listSpaceArtifacts(_ payload: SpaceListArtifactsPayload) async throws -> SpaceListArtifactsResult {
        let data = try await sendAndWait(type: MessageType.spaceListArtifacts, payload: payload)
        return try decoder.decode(SpaceListArtifactsResult.self, from: data)
    }

    /// Fetch one artifact in a space.
    public func getSpaceArtifact(_ payload: SpaceGetArtifactPayload) async throws -> SpaceArtifactDetail {
        let data = try await sendAndWait(type: MessageType.spaceGetArtifact, payload: payload)
        let response = try decoder.decode(SpaceGetArtifactResult.self, from: data)
        return response.artifact
    }

    /// Fetch one debug-only artifact in a space, bypassing the normal preview cap.
    public func getSpaceDebugArtifact(_ payload: SpaceGetDebugArtifactPayload) async throws -> SpaceArtifactDetail {
        let data = try await sendAndWait(type: MessageType.spaceGetDebugArtifact, payload: payload)
        let response = try decoder.decode(SpaceGetDebugArtifactResult.self, from: data)
        return response.artifact
    }

    /// Reset one space's scoped state via gateway transport.
    public func resetSpace(_ payload: SpaceResetPayload) async throws -> SpaceResetResult {
        // Space reset can also be expensive on large persisted datasets.
        let data = try await sendAndWait(
            type: MessageType.spaceReset,
            payload: payload,
            timeoutSec: max(options.requestTimeoutSec, 180)
        )
        return try decoder.decode(SpaceResetResult.self, from: data)
    }

    /// Reset the active usage session for one agent in a space.
    public func resetAgentUsageSession(_ payload: SpaceResetAgentUsageSessionPayload) async throws -> SpaceResetAgentUsageSessionResult {
        let data = try await sendAndWait(type: MessageType.spaceResetAgentUsageSession, payload: payload)
        return try decoder.decode(SpaceResetAgentUsageSessionResult.self, from: data)
    }

    /// Read the effective tool matrix for one space/agent.
    public func getEffectiveTools(_ payload: SpaceGetEffectiveToolsPayload) async throws -> EffectiveToolMatrix {
        let data = try await sendAndWait(type: MessageType.spaceGetEffectiveTools, payload: payload)
        let response = try decoder.decode(SpaceGetEffectiveToolsResponsePayload.self, from: data)
        return response.matrix
    }

    /// Read the unified effective tool access matrix for one space/agent.
    public func getEffectiveToolAccess(_ payload: SpaceGetEffectiveToolAccessPayload) async throws -> EffectiveToolAccess {
        let data = try await sendAndWait(type: MessageType.spaceGetEffectiveToolAccess, payload: payload)
        let response = try decoder.decode(SpaceGetEffectiveToolAccessResponsePayload.self, from: data)
        return response.access
    }

    /// Read the unified tool policy for one space.
    public func getToolPolicy(_ payload: SpaceGetToolPolicyPayload) async throws -> ToolAccessPolicy {
        let data = try await sendAndWait(type: MessageType.spaceGetToolPolicy, payload: payload)
        let response = try decoder.decode(SpaceGetToolPolicyResponsePayload.self, from: data)
        return response.policy
    }

    /// Update the unified tool policy for one space.
    public func updateToolPolicy(_ payload: SpaceUpdateToolPolicyPayload) async throws -> ToolAccessPolicy {
        let data = try await sendAndWait(type: MessageType.spaceUpdateToolPolicy, payload: payload)
        let response = try decoder.decode(SpaceUpdateToolPolicyResponsePayload.self, from: data)
        return response.policy
    }

    /// Read the connector policy for one space.
    public func getConnectorPolicy(_ payload: SpaceGetConnectorPolicyPayload) async throws -> SpaceConnectorPolicy {
        let data = try await sendAndWait(type: MessageType.spaceGetConnectorPolicy, payload: payload)
        let response = try decoder.decode(SpaceGetConnectorPolicyResponsePayload.self, from: data)
        return response.policy
    }

    /// Update the connector policy for one space.
    public func updateConnectorPolicy(_ payload: SpaceUpdateConnectorPolicyPayload) async throws -> SpaceConnectorPolicy {
        let data = try await sendAndWait(type: MessageType.spaceUpdateConnectorPolicy, payload: payload)
        let response = try decoder.decode(SpaceUpdateConnectorPolicyResponsePayload.self, from: data)
        return response.policy
    }

    public func listAgentDefinitions(
        apiVersion: String? = nil,
        includeArchived: Bool? = nil
    ) async throws -> [AgentDefinitionSummary] {
        let payload = IdentityListAgentDefinitionsPayload(
            apiVersion: apiVersion,
            includeArchived: includeArchived
        )
        let data = try await sendAndWait(type: MessageType.identityListAgentDefinitions, payload: payload)
        let response = try decoder.decode(IdentityListAgentDefinitionsResponsePayload.self, from: data)
        return response.agentDefinitions
    }

    public func getAgentDefinition(
        agentDefinitionId: String,
        apiVersion: String? = nil
    ) async throws -> AgentDefinitionSummary {
        let payload = IdentityGetAgentDefinitionPayload(
            apiVersion: apiVersion,
            agentDefinitionId: agentDefinitionId
        )
        let data = try await sendAndWait(type: MessageType.identityGetAgentDefinition, payload: payload)
        let response = try decoder.decode(IdentityGetAgentDefinitionResponsePayload.self, from: data)
        return response.agentDefinition
    }

    public func createAgentDefinition(
        _ payload: IdentityCreateAgentDefinitionPayload
    ) async throws -> AgentDefinitionCreateResult {
        let data = try await sendAndWait(type: MessageType.identityCreateAgentDefinition, payload: payload)
        let response = try decoder.decode(IdentityCreateAgentDefinitionResponsePayload.self, from: data)
        return AgentDefinitionCreateResult(
            agentDefinition: response.agentDefinition,
            created: response.created
        )
    }

    public func updateAgentDefinition(
        _ payload: IdentityUpdateAgentDefinitionPayload
    ) async throws -> AgentDefinitionUpdateResult {
        let data = try await sendAndWait(type: MessageType.identityUpdateAgentDefinition, payload: payload)
        let response = try decoder.decode(IdentityUpdateAgentDefinitionResponsePayload.self, from: data)
        return AgentDefinitionUpdateResult(
            agentDefinition: response.agentDefinition,
            newRevision: response.newRevision
        )
    }

    public func archiveAgentDefinition(
        _ payload: IdentityArchiveAgentDefinitionPayload
    ) async throws -> AgentDefinitionArchiveResult {
        let data = try await sendAndWait(type: MessageType.identityArchiveAgentDefinition, payload: payload)
        let response = try decoder.decode(IdentityArchiveAgentDefinitionResponsePayload.self, from: data)
        return AgentDefinitionArchiveResult(
            agentDefinition: response.agentDefinition,
            archived: response.archived
        )
    }

    public func listPersonas(
        apiVersion: String? = nil,
        includeArchived: Bool? = nil
    ) async throws -> [PersonaSummary] {
        let payload = IdentityListPersonasPayload(apiVersion: apiVersion, includeArchived: includeArchived)
        let data = try await sendAndWait(type: MessageType.identityListPersonas, payload: payload)
        let response = try decoder.decode(IdentityListPersonasResponsePayload.self, from: data)
        return response.personas
    }

    public func getPersona(personaId: String, apiVersion: String? = nil) async throws -> PersonaSummary {
        let payload = IdentityGetPersonaPayload(apiVersion: apiVersion, personaId: personaId)
        let data = try await sendAndWait(type: MessageType.identityGetPersona, payload: payload)
        let response = try decoder.decode(IdentityGetPersonaResponsePayload.self, from: data)
        return response.persona
    }

    public func createPersona(_ payload: IdentityCreatePersonaPayload) async throws -> PersonaCreateResult {
        let data = try await sendAndWait(type: MessageType.identityCreatePersona, payload: payload)
        let response = try decoder.decode(IdentityCreatePersonaResponsePayload.self, from: data)
        return PersonaCreateResult(persona: response.persona, created: response.created)
    }

    public func updatePersona(_ payload: IdentityUpdatePersonaPayload) async throws -> PersonaUpdateResult {
        let data = try await sendAndWait(type: MessageType.identityUpdatePersona, payload: payload)
        let response = try decoder.decode(IdentityUpdatePersonaResponsePayload.self, from: data)
        return PersonaUpdateResult(persona: response.persona, newRevision: response.newRevision)
    }

    public func archivePersona(_ payload: IdentityArchivePersonaPayload) async throws -> PersonaArchiveResult {
        let data = try await sendAndWait(type: MessageType.identityArchivePersona, payload: payload)
        let response = try decoder.decode(IdentityArchivePersonaResponsePayload.self, from: data)
        return PersonaArchiveResult(persona: response.persona, archived: response.archived)
    }

    public func previewCompiledInstructions(
        agentDefinitionId: String,
        apiVersion: String? = nil,
        workspaceContext: String? = nil
    ) async throws -> CompiledInstructionsPreview {
        let payload = IdentityPreviewCompiledInstructionsPayload(
            apiVersion: apiVersion,
            agentDefinitionId: agentDefinitionId,
            workspaceContext: workspaceContext
        )
        let data = try await sendAndWait(
            type: MessageType.identityPreviewCompiledInstructions,
            payload: payload
        )
        let response = try decoder.decode(IdentityPreviewCompiledInstructionsResponsePayload.self, from: data)
        return response.preview
    }

    public func previewRuntimeSystemPrompt(
        _ payload: IdentityPreviewRuntimeSystemPromptPayload
    ) async throws -> RuntimeSystemPromptPreview {
        let data = try await sendAndWait(
            type: MessageType.identityPreviewRuntimeSystemPrompt,
            payload: payload
        )
        let response = try decoder.decode(IdentityPreviewRuntimeSystemPromptResponsePayload.self, from: data)
        return response.preview
    }

    /// Preview the composed system prompt across all budget classes for an agent definition.
    public func previewSystemPromptMatrix(
        agentDefinitionId: String,
        spaceId: String? = nil,
        agentId: String? = nil,
        apiVersion: String? = nil
    ) async throws -> SystemPromptMatrix {
        let payload = IdentityPreviewSystemPromptMatrixPayload(
            apiVersion: apiVersion,
            agentDefinitionId: agentDefinitionId,
            spaceId: spaceId,
            agentId: agentId
        )
        let data = try await sendAndWait(
            type: MessageType.identityPreviewSystemPromptMatrix,
            payload: payload
        )
        let response = try decoder.decode(IdentityPreviewSystemPromptMatrixResponsePayload.self, from: data)
        return response.matrix
    }

    public func previewTemplate(_ payload: SpacePreviewTemplatePayload) async throws -> SpacePreviewTemplateResult {
        let data = try await sendAndWait(type: MessageType.spacePreviewTemplate, payload: payload)
        let response = try decoder.decode(SpacePreviewTemplateResponsePayload.self, from: data)
        return SpacePreviewTemplateResult(
            template: response.template,
            resolved: response.resolved,
            warnings: response.warnings
        )
    }

    public func createSpaceFromTemplate(_ payload: SpaceCreateFromTemplatePayload) async throws -> SpaceCreateFromTemplateResult {
        let data = try await sendAndWait(type: MessageType.spaceCreateFromTemplate, payload: payload)
        return try decoder.decode(SpaceCreateFromTemplateResult.self, from: data)
    }

    public func saveSpaceTemplate(_ payload: SpaceSaveTemplatePayload) async throws -> SpaceSaveTemplateResult {
        let data = try await sendAndWait(type: MessageType.spaceSaveTemplate, payload: payload)
        return try decoder.decode(SpaceSaveTemplateResult.self, from: data)
    }

    public func listSpaceTemplates(
        apiVersion: String? = nil,
        includeArchived: Bool? = nil,
        includeSystem: Bool? = nil
    ) async throws -> [SpaceTemplateRecord] {
        let payload = SpaceTemplateListPayload(apiVersion: apiVersion, includeArchived: includeArchived, includeSystem: includeSystem)
        let data = try await sendAndWait(type: MessageType.spaceListTemplates, payload: payload)
        let response = try decoder.decode(SpaceTemplateListResponsePayload.self, from: data)
        return response.templates
    }

    public func getSpaceTemplate(
        templateId: String,
        apiVersion: String? = nil
    ) async throws -> SpaceTemplateRecord {
        let payload = SpaceTemplateGetPayload(apiVersion: apiVersion, templateId: templateId)
        let data = try await sendAndWait(type: MessageType.spaceGetTemplate, payload: payload)
        let response = try decoder.decode(SpaceTemplateGetResponsePayload.self, from: data)
        return response.template
    }

    public func previewSpaceTemplateRecord(
        _ payload: SpaceTemplatePreviewPayload
    ) async throws -> SpaceTemplatePreviewResult {
        async let template = getSpaceTemplate(
            templateId: payload.templateId,
            apiVersion: payload.apiVersion
        )
        async let preview = previewTemplate(
            SpacePreviewTemplatePayload(
                apiVersion: payload.apiVersion,
                templateId: payload.templateId,
                resourceId: payload.resourceId,
                name: payload.name,
                goal: payload.goal
            )
        )
        let (record, resolvedPreview) = try await (template, preview)
        return SpaceTemplatePreviewResult(
            template: record,
            resolved: resolvedPreview.resolved,
            warnings: resolvedPreview.warnings
        )
    }

    public func createSpaceFromManagedTemplate(
        _ payload: SpaceTemplateCreateSpacePayload
    ) async throws -> SpaceTemplateCreateSpaceResult {
        async let template = getSpaceTemplate(
            templateId: payload.templateId,
            apiVersion: payload.apiVersion
        )
        async let created = createSpaceFromTemplate(
            SpaceCreateFromTemplatePayload(
                apiVersion: payload.apiVersion,
                idempotencyKey: payload.idempotencyKey,
                templateId: payload.templateId,
                spaceId: payload.spaceId,
                resourceId: payload.resourceId,
                name: payload.name,
                goal: payload.goal,
                workspaceRoot: payload.workspaceRoot,
                visibility: payload.visibility
            )
        )
        let (record, result) = try await (template, created)
        return SpaceTemplateCreateSpaceResult(template: record, space: result.space)
    }

    public func saveManagedSpaceTemplate(
        _ payload: SpaceTemplateSavePayload
    ) async throws -> SpaceTemplateSaveResult {
        let result = try await saveSpaceTemplate(
            SpaceSaveTemplatePayload(
                apiVersion: payload.apiVersion,
                templateId: payload.templateId,
                title: payload.name,
                description: payload.description,
                communicationMode: payload.communicationMode,
                conversationTopology: payload.conversationTopology,
                promptPackId: payload.promptPackId,
                baseAgents: payload.baseAgents,
                sourceSpaceId: payload.sourceSpaceId
            )
        )
        let template = try await getSpaceTemplate(
            templateId: result.template.templateId,
            apiVersion: payload.apiVersion
        )
        return SpaceTemplateSaveResult(template: template, created: result.created)
    }

    public func archiveSpaceTemplate(
        _ payload: SpaceTemplateArchivePayload
    ) async throws -> SpaceTemplateArchiveResult {
        let data = try await sendAndWait(type: MessageType.spaceArchiveTemplate, payload: payload)
        let response = try decoder.decode(SpaceTemplateArchiveResponsePayload.self, from: data)
        return SpaceTemplateArchiveResult(template: response.template, archived: response.archived)
    }

    public func registerDevice(_ payload: AuthRegisterDevicePayload) async throws -> AuthRegisterDeviceResult {
        let data = try await sendAndWait(type: MessageType.authRegisterDevice, payload: payload)
        return try decoder.decode(AuthRegisterDeviceResult.self, from: data)
    }

    public func rotateDeviceKey(_ payload: AuthRotateDeviceKeyPayload) async throws -> AuthRotateDeviceKeyResult {
        let data = try await sendAndWait(type: MessageType.authRotateDeviceKey, payload: payload)
        return try decoder.decode(AuthRotateDeviceKeyResult.self, from: data)
    }

    public func revokeDevice(_ payload: AuthRevokeDevicePayload) async throws -> AuthRevokeDeviceResult {
        let data = try await sendAndWait(type: MessageType.authRevokeDevice, payload: payload)
        return try decoder.decode(AuthRevokeDeviceResult.self, from: data)
    }

    public func listDevices(
        apiVersion: String? = nil,
        includeRevoked: Bool? = nil
    ) async throws -> [DeviceIdentity] {
        let payload = AuthListDevicesPayload(apiVersion: apiVersion, includeRevoked: includeRevoked)
        let data = try await sendAndWait(type: MessageType.authListDevices, payload: payload)
        let response = try decoder.decode(AuthListDevicesResponsePayload.self, from: data)
        return response.devices
    }

    public func issueHttpPrincipalToken(
        apiVersion: String? = nil,
        ttlSeconds: Int? = nil
    ) async throws -> AuthIssueHttpPrincipalTokenResponsePayload {
        let payload = AuthIssueHttpPrincipalTokenPayload(
            apiVersion: apiVersion,
            ttlSeconds: ttlSeconds
        )
        let data = try await sendAndWait(type: MessageType.authIssueHttpPrincipalToken, payload: payload)
        return try decoder.decode(AuthIssueHttpPrincipalTokenResponsePayload.self, from: data)
    }

    /// Discover supported local CLI executors and local runtimes available on this gateway host.
    public func discoverLocalAgents(apiVersion: String? = nil) async throws -> [DiscoveredLocalAgent] {
        let payload = GatewayDiscoverLocalAgentsPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.gatewayDiscoverLocalAgents, payload: payload)
        let response = try decoder.decode(GatewayDiscoverLocalAgentsResponsePayload.self, from: data)
        return response.agents
    }

    /// List model runtime configurations currently loaded by the gateway.
    public func listProviderConfigs(apiVersion: String? = nil) async throws -> [GatewayProviderRuntimeConfig] {
        let payload = GatewayListProviderConfigsPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.gatewayListProviderConfigs, payload: payload)
        let response = try decoder.decode(GatewayListProviderConfigsResponsePayload.self, from: data)
        return response.configs
    }

    /// Read canonical main-agent state for the configured main space.
    public func getMainAgent(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        repairIfMissing: Bool? = true
    ) async throws -> GatewayMainAgentState {
        let payload = GatewayGetMainAgentPayload(
            apiVersion: apiVersion,
            spaceId: spaceId,
            repairIfMissing: repairIfMissing
        )
        let data = try await sendAndWait(type: MessageType.gatewayGetMainAgent, payload: payload)
        let response = try decoder.decode(GatewayGetMainAgentResponsePayload.self, from: data)
        return response.state
    }

    /// Update canonical main-agent runtime selection for the configured main space.
    public func setMainAgent(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        selectionMode: MainAgentSelectionMode,
        providerId: String? = nil,
        modelId: String? = nil,
        sourceAgentDefinitionId: String? = nil,
        applyPersonaInstructions: Bool? = nil
    ) async throws -> GatewayMainAgentState {
        let payload = GatewaySetMainAgentPayload(
            apiVersion: apiVersion,
            spaceId: spaceId,
            selectionMode: selectionMode,
            providerId: providerId,
            modelId: modelId,
            sourceAgentDefinitionId: sourceAgentDefinitionId,
            applyPersonaInstructions: applyPersonaInstructions
        )
        return try await setMainAgent(payload)
    }

    /// Update canonical main-agent runtime selection with a fully-formed payload.
    public func setMainAgent(_ payload: GatewaySetMainAgentPayload) async throws -> GatewayMainAgentState {
        let data = try await sendAndWait(type: MessageType.gatewaySetMainAgent, payload: payload)
        let response = try decoder.decode(GatewaySetMainAgentResponsePayload.self, from: data)
        return response.state
    }

    /// Read canonical concierge-agent state for the configured concierge backing space.
    public func getConciergeAgent(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        repairIfMissing: Bool? = true
    ) async throws -> GatewayConciergeAgentState {
        let payload = GatewayGetConciergeAgentPayload(
            apiVersion: apiVersion,
            spaceId: spaceId,
            repairIfMissing: repairIfMissing
        )
        let data = try await sendAndWait(type: MessageType.gatewayGetConciergeAgent, payload: payload)
        let response = try decoder.decode(GatewayGetConciergeAgentResponsePayload.self, from: data)
        return response.state
    }

    /// Update canonical concierge-agent runtime selection for the configured concierge backing space.
    public func setConciergeAgent(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        selectionMode: ConciergeAgentSelectionMode,
        providerId: String? = nil,
        modelId: String? = nil,
        sourceAgentDefinitionId: String? = nil,
        applyPersonaInstructions: Bool? = nil
    ) async throws -> GatewayConciergeAgentState {
        let payload = GatewaySetConciergeAgentPayload(
            apiVersion: apiVersion,
            spaceId: spaceId,
            selectionMode: selectionMode,
            providerId: providerId,
            modelId: modelId,
            sourceAgentDefinitionId: sourceAgentDefinitionId,
            applyPersonaInstructions: applyPersonaInstructions
        )
        return try await setConciergeAgent(payload)
    }

    /// Update canonical concierge-agent runtime selection with a fully-formed payload.
    public func setConciergeAgent(_ payload: GatewaySetConciergeAgentPayload) async throws -> GatewayConciergeAgentState {
        let data = try await sendAndWait(type: MessageType.gatewaySetConciergeAgent, payload: payload)
        let response = try decoder.decode(GatewaySetConciergeAgentResponsePayload.self, from: data)
        return response.state
    }

    /// List runtime model catalogs discovered by the gateway.
    public func listAvailableModels(
        apiVersion: String? = nil,
        providerId: String? = nil,
        refresh: Bool? = nil
    ) async throws -> [GatewayModelProviderCatalog] {
        let payload = GatewayListAvailableModelsPayload(
            apiVersion: apiVersion,
            providerId: providerId,
            refresh: refresh
        )
        let data = try await sendAndWait(type: MessageType.gatewayListAvailableModels, payload: payload)
        let response = try decoder.decode(GatewayListAvailableModelsResponsePayload.self, from: data)
        return response.providers
    }

    /// List runtime catalogs grouped by integration class.
    public func listProviderCatalogs(
        apiVersion: String? = nil,
        providerId: String? = nil,
        refresh: Bool? = nil
    ) async throws -> [GatewayModelProviderCatalog] {
        let payload = GatewayListProviderCatalogsPayload(
            apiVersion: apiVersion,
            providerId: providerId,
            refresh: refresh
        )
        let data = try await sendAndWait(type: MessageType.gatewayListProviderCatalogs, payload: payload)
        let response = try decoder.decode(GatewayListProviderCatalogsResponsePayload.self, from: data)
        return response.providers
    }

    /// List registered external CLI tools known to the gateway.
    public func listTools(apiVersion: String? = nil) async throws -> [GatewayTool] {
        let payload = GatewayListToolsPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.toolList, payload: payload)
        let response = try decoder.decode(GatewayListToolsResponsePayload.self, from: data)
        return response.tools
    }

    /// Fetch one CLI tool bundle by ID.
    public func getTool(
        toolId: String,
        apiVersion: String? = nil
    ) async throws -> GatewayTool? {
        let payload = GatewayGetToolPayload(apiVersion: apiVersion, toolId: toolId)
        let data = try await sendAndWait(type: MessageType.toolGet, payload: payload)
        let response = try decoder.decode(GatewayGetToolResponsePayload.self, from: data)
        return response.tool
    }

    /// List supported interconnector bundles and their current availability state.
    public func listInterconnectors(
        apiVersion: String? = nil
    ) async throws -> [GatewayInterconnectorBundle] {
        let payload = GatewayListInterconnectorsPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.gatewayListInterconnectors, payload: payload)
        let response = try decoder.decode(GatewayListInterconnectorsResponsePayload.self, from: data)
        return response.interconnectors
    }

    /// Generate a starter CLI tool bundle manifest and README.
    public func scaffoldTool(_ payload: GatewayScaffoldToolPayload) async throws -> GatewayScaffoldedToolBundle {
        let data = try await sendAndWait(type: MessageType.toolScaffold, payload: payload)
        let response = try decoder.decode(GatewayScaffoldToolResponsePayload.self, from: data)
        return GatewayScaffoldedToolBundle(manifest: response.manifest, readme: response.readme)
    }

    /// Register or update one CLI tool bundle on the gateway.
    public func registerTool(_ payload: GatewayRegisterToolPayload) async throws -> GatewayTool {
        let data = try await sendAndWait(type: MessageType.toolRegister, payload: payload)
        let response = try decoder.decode(GatewayRegisterToolResponsePayload.self, from: data)
        return response.tool
    }

    /// Remove one registered CLI tool bundle by ID.
    public func removeTool(
        toolId: String,
        apiVersion: String? = nil
    ) async throws -> Bool {
        let payload = GatewayRemoveToolPayload(apiVersion: apiVersion, toolId: toolId)
        let data = try await sendAndWait(type: MessageType.toolRemove, payload: payload)
        let response = try decoder.decode(GatewayRemoveToolResponsePayload.self, from: data)
        return response.removed
    }

    /// Enable or disable a CLI tool bundle by representative tool id.
    public func setToolEnabled(
        toolId: String,
        enabled: Bool,
        apiVersion: String? = nil
    ) async throws -> [GatewayTool] {
        let payload = GatewaySetToolEnabledPayload(apiVersion: apiVersion, toolId: toolId, enabled: enabled)
        let data = try await sendAndWait(type: MessageType.toolSetEnabled, payload: payload)
        let response = try decoder.decode(GatewaySetToolEnabledResponsePayload.self, from: data)
        return response.tools
    }

    /// Rescan supported interconnector bundles and refresh the gateway-managed bundle catalog.
    public func rescanInterconnectors(
        apiVersion: String? = nil
    ) async throws -> [GatewayInterconnectorBundle] {
        let payload = GatewayRescanInterconnectorsPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.gatewayRescanInterconnectors, payload: payload)
        let response = try decoder.decode(GatewayRescanInterconnectorsResponsePayload.self, from: data)
        return response.interconnectors
    }

    /// Compatibility alias for `rescanInterconnectors()` kept for older clients.
    public func rescanJiraCliTools(
        apiVersion: String? = nil
    ) async throws -> GatewayRescanJiraCliToolsResponsePayload {
        let payload = GatewayRescanJiraCliToolsPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.toolRescanJira, payload: payload)
        return try decoder.decode(GatewayRescanJiraCliToolsResponsePayload.self, from: data)
    }

    /// List active or historical CLI tool approval grants.
    public func listToolApprovalGrants(
        apiVersion: String? = nil,
        principalId: String? = nil,
        deviceId: String? = nil,
        spaceId: String? = nil,
        toolId: String? = nil,
        includeRevoked: Bool? = nil,
        includeExpired: Bool? = nil
    ) async throws -> [GatewayToolApprovalGrant] {
        let payload = GatewayListToolApprovalGrantsPayload(
            apiVersion: apiVersion,
            principalId: principalId,
            deviceId: deviceId,
            spaceId: spaceId,
            toolId: toolId,
            includeRevoked: includeRevoked,
            includeExpired: includeExpired
        )
        let data = try await sendAndWait(type: MessageType.toolListGrants, payload: payload)
        let response = try decoder.decode(GatewayListToolApprovalGrantsResponsePayload.self, from: data)
        return response.grants
    }

    /// Revoke a CLI tool approval grant for one space/tool scope.
    public func revokeToolApprovalGrant(
        _ payload: GatewayRevokeToolApprovalGrantPayload
    ) async throws -> GatewayRevokeToolApprovalGrantResult {
        let data = try await sendAndWait(type: MessageType.toolRevokeGrant, payload: payload)
        return try decoder.decode(GatewayRevokeToolApprovalGrantResponsePayload.self, from: data)
    }

    /// Read telemetry for configured model runtimes.
    public func getProviderTelemetry(
        apiVersion: String? = nil,
        providerId: String? = nil
    ) async throws -> [ProviderTelemetry] {
        let payload = GatewayGetProviderTelemetryPayload(
            apiVersion: apiVersion,
            providerId: providerId
        )
        let data = try await sendAndWait(type: MessageType.gatewayGetProviderTelemetry, payload: payload)
        let response = try decoder.decode(GatewayGetProviderTelemetryResponsePayload.self, from: data)
        return response.telemetry
    }

    /// Read local runtime telemetry (quota windows + local token/session aggregates).
    public func getLocalUsageTelemetry(
        apiVersion: String? = nil,
        providerId: String? = nil
    ) async throws -> [LocalProviderUsageTelemetry] {
        let payload = GatewayGetLocalUsageTelemetryPayload(
            apiVersion: apiVersion,
            providerId: providerId
        )
        let data = try await sendAndWait(type: MessageType.gatewayGetLocalUsageTelemetry, payload: payload)
        let response = try decoder.decode(GatewayGetLocalUsageTelemetryResponsePayload.self, from: data)
        return response.telemetry
    }

    /// Read the gateway-owned managed space home root.
    public func getWorkspaceDefaults(
        apiVersion: String? = nil
    ) async throws -> GatewayWorkspaceDefaults {
        let payload = GatewayGetWorkspaceDefaultsPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.gatewayGetWorkspaceDefaults, payload: payload)
        let response = try decoder.decode(GatewayGetWorkspaceDefaultsResponsePayload.self, from: data)
        return response.defaults
    }

    /// Update the gateway-owned managed space home root.
    public func setWorkspaceDefaults(
        apiVersion: String? = nil,
        spaceHomeRoot: String? = nil
    ) async throws -> GatewayWorkspaceDefaults {
        let payload = GatewaySetWorkspaceDefaultsPayload(
            apiVersion: apiVersion,
            spaceHomeRoot: spaceHomeRoot
        )
        let data = try await sendAndWait(type: MessageType.gatewaySetWorkspaceDefaults, payload: payload)
        let response = try decoder.decode(GatewaySetWorkspaceDefaultsResponsePayload.self, from: data)
        return response.defaults
    }

    public func getMemoryDefaults(
        apiVersion: String? = nil
    ) async throws -> GatewayMemoryDefaults {
        let payload = GatewayGetMemoryDefaultsPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.gatewayGetMemoryDefaults, payload: payload)
        let response = try decoder.decode(GatewayGetMemoryDefaultsResponsePayload.self, from: data)
        return response.defaults
    }

    public func setMemoryDefaults(
        apiVersion: String? = nil,
        defaultExperienceCapture: SpaceExperienceCaptureMode,
        defaultSpacePrivacyMode: SpacePrivacyMode = .standard
    ) async throws -> GatewayMemoryDefaults {
        let payload = GatewaySetMemoryDefaultsPayload(
            apiVersion: apiVersion,
            defaultExperienceCapture: defaultExperienceCapture,
            defaultSpacePrivacyMode: defaultSpacePrivacyMode
        )
        let data = try await sendAndWait(type: MessageType.gatewaySetMemoryDefaults, payload: payload)
        let response = try decoder.decode(GatewaySetMemoryDefaultsResponsePayload.self, from: data)
        return response.defaults
    }

    /// Read gateway-owned external connectivity settings and live status.
    public func getExternalConnectivity(
        apiVersion: String? = nil
    ) async throws -> GatewayGetExternalConnectivityResponsePayload {
        let payload = GatewayGetExternalConnectivityPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.gatewayGetExternalConnectivity, payload: payload)
        return try decoder.decode(GatewayGetExternalConnectivityResponsePayload.self, from: data)
    }

    /// Update the desired external connectivity mode and return the live status snapshot.
    public func setExternalConnectivity(
        apiVersion: String? = nil,
        mode: String
    ) async throws -> GatewaySetExternalConnectivityResponsePayload {
        let payload = GatewaySetExternalConnectivityPayload(apiVersion: apiVersion, mode: mode)
        let data = try await sendAndWait(type: MessageType.gatewaySetExternalConnectivity, payload: payload)
        return try decoder.decode(GatewaySetExternalConnectivityResponsePayload.self, from: data)
    }

    /// Fetch full runtime settings for one configured runtime.
    public func getProviderSettings(
        apiVersion: String? = nil,
        providerId: String
    ) async throws -> GatewayProviderRuntimeConfig {
        let payload = GatewayGetProviderSettingsPayload(apiVersion: apiVersion, providerId: providerId)
        let data = try await sendAndWait(type: MessageType.gatewayGetProviderSettings, payload: payload)
        let response = try decoder.decode(GatewayGetProviderSettingsResponsePayload.self, from: data)
        return response.settings
    }

    /// Set or update one model runtime configuration.
    public func setProviderConfig(
        apiVersion: String? = nil,
        providerId: String,
        model: String? = nil,
        apiKey: String? = nil,
        apiKeySecretRef: String? = nil,
        authMode: GatewayProviderAuthMode? = nil,
        baseURL: String? = nil,
        executablePath: String? = nil,
        allowedModels: [String]? = nil,
        allowCustomModel: Bool? = nil
    ) async throws -> GatewayProviderRuntimeConfig {
        let payload = GatewaySetProviderConfigPayload(
            apiVersion: apiVersion,
            providerId: providerId,
            model: model,
            apiKey: apiKey,
            apiKeySecretRef: apiKeySecretRef,
            authMode: authMode,
            baseURL: baseURL,
            executablePath: executablePath,
            allowedModels: allowedModels,
            allowCustomModel: allowCustomModel
        )
        let data = try await sendAndWait(type: MessageType.gatewaySetProviderConfig, payload: payload)
        let response = try decoder.decode(GatewaySetProviderConfigResponsePayload.self, from: data)
        return response.config
    }

    /// Update gateway-level runtime settings (catalog + allowlist).
    public func updateProviderSettings(
        apiVersion: String? = nil,
        providerId: String,
        model: String? = nil,
        apiKey: String? = nil,
        apiKeySecretRef: String? = nil,
        authMode: GatewayProviderAuthMode? = nil,
        baseURL: String? = nil,
        executablePath: String? = nil,
        allowedModels: [String]? = nil,
        allowCustomModel: Bool? = nil
    ) async throws -> GatewayProviderRuntimeConfig {
        let payload = GatewayUpdateProviderSettingsPayload(
            apiVersion: apiVersion,
            providerId: providerId,
            model: model,
            apiKey: apiKey,
            apiKeySecretRef: apiKeySecretRef,
            authMode: authMode,
            baseURL: baseURL,
            executablePath: executablePath,
            allowedModels: allowedModels,
            allowCustomModel: allowCustomModel
        )
        let data = try await sendAndWait(type: MessageType.gatewayUpdateProviderSettings, payload: payload)
        let response = try decoder.decode(GatewayUpdateProviderSettingsResponsePayload.self, from: data)
        return response.settings
    }

    /// Remove one model runtime configuration by runtime ID.
    public func removeProviderConfig(
        apiVersion: String? = nil,
        providerId: String
    ) async throws {
        let payload = GatewayRemoveProviderConfigPayload(apiVersion: apiVersion, providerId: providerId)
        _ = try await sendAndWait(type: MessageType.gatewayRemoveProviderConfig, payload: payload)
    }

    /// Destructively reset one gateway runtime after typed confirmation.
    public func factoryResetGateway(
        confirmation: String,
        apiVersion: String? = nil
    ) async throws -> GatewayFactoryResetResult {
        let payload = GatewayFactoryResetPayload(
            apiVersion: apiVersion,
            confirmation: confirmation
        )
        // Factory reset can legitimately take longer than standard request paths
        // when the gateway has a large persisted state.
        let data = try await sendAndWait(
            type: MessageType.gatewayFactoryReset,
            payload: payload,
            timeoutSec: max(options.requestTimeoutSec, 180)
        )
        let response = try decoder.decode(GatewayFactoryResetResponsePayload.self, from: data)
        return GatewayFactoryResetResult(
            gatewayId: response.gatewayId,
            gatewayUuid: response.gatewayUuid,
            resetAt: response.resetAt,
            tablesCleared: response.tablesCleared,
            rowsDeleted: response.rowsDeleted
        )
    }

    /// Provision or reuse a local-client profile and optionally assign it to a space agent.
    public func provisionLocalProfile(
        _ payload: GatewayProvisionLocalProfilePayload
    ) async throws -> GatewayProvisionLocalProfileResult {
        let data = try await sendAndWait(type: MessageType.gatewayProvisionLocalProfile, payload: payload)
        let response = try decoder.decode(GatewayProvisionLocalProfileResponsePayload.self, from: data)
        return GatewayProvisionLocalProfileResult(
            profileId: response.profileId,
            profileName: response.profileName,
            created: response.created,
            providerId: response.providerId,
            model: response.model,
            agentId: response.agentId,
            assignmentCreated: response.assignmentCreated
        )
    }

    /// Create or update a provider secret reference.
    public func putSecretRef(_ payload: GatewayPutSecretRefPayload) async throws -> GatewayPutSecretRefResult {
        let data = try await sendAndWait(type: MessageType.gatewayPutSecretRef, payload: payload)
        return try decoder.decode(GatewayPutSecretRefResult.self, from: data)
    }

    /// List provider secret references. Response never includes raw secret material.
    public func listSecretRefs(
        apiVersion: String? = nil,
        providerId: String? = nil
    ) async throws -> [GatewaySecretRef] {
        let payload = GatewayListSecretRefsPayload(apiVersion: apiVersion, providerId: providerId)
        let data = try await sendAndWait(type: MessageType.gatewayListSecretRefs, payload: payload)
        let response = try decoder.decode(GatewayListSecretRefsResponsePayload.self, from: data)
        return response.secretRefs
    }

    /// Delete one provider secret reference by ID.
    public func deleteSecretRef(
        secretRef: String,
        apiVersion: String? = nil
    ) async throws -> Bool {
        let payload = GatewayDeleteSecretRefPayload(apiVersion: apiVersion, secretRef: secretRef)
        let data = try await sendAndWait(type: MessageType.gatewayDeleteSecretRef, payload: payload)
        let response = try decoder.decode(GatewayDeleteSecretRefResult.self, from: data)
        return response.deleted
    }

    /// Read the canonical grouped integrations snapshot for one gateway.
    public func getIntegrationsSnapshot(
        apiVersion: String? = nil
    ) async throws -> GatewayIntegrationsSnapshot {
        let payload = GatewayGetIntegrationsSnapshotPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.gatewayGetIntegrationsSnapshot, payload: payload)
        let response = try decoder.decode(GatewayGetIntegrationsSnapshotResponsePayload.self, from: data)
        return response.snapshot
    }

    /// List registered connector families available in the current gateway profile.
    public func listConnectorFamilies(apiVersion: String? = nil) async throws -> [GatewayConnectorFamily] {
        let payload = GatewayListConnectorFamiliesPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.gatewayListConnectorFamilies, payload: payload)
        let response = try decoder.decode(GatewayListConnectorFamiliesResponsePayload.self, from: data)
        return response.families
    }

    /// List configured connector instances, optionally filtered by family.
    public func listConnectors(
        apiVersion: String? = nil,
        familyId: String? = nil
    ) async throws -> [GatewayConnector] {
        let payload = GatewayListConnectorsPayload(apiVersion: apiVersion, familyId: familyId)
        let data = try await sendAndWait(type: MessageType.gatewayListConnectors, payload: payload)
        let response = try decoder.decode(GatewayListConnectorsResponsePayload.self, from: data)
        return response.connectors
    }

    /// Create or update a connector instance.
    public func upsertConnector(_ payload: GatewayUpsertConnectorPayload) async throws -> GatewayConnector {
        let data = try await sendAndWait(type: MessageType.gatewayUpsertConnector, payload: payload)
        let response = try decoder.decode(GatewayUpsertConnectorResponsePayload.self, from: data)
        return response.connector
    }

    /// Remove a connector instance by connector ID.
    public func removeConnector(
        connectorId: String,
        apiVersion: String? = nil
    ) async throws -> Bool {
        let payload = GatewayRemoveConnectorPayload(apiVersion: apiVersion, connectorId: connectorId)
        let data = try await sendAndWait(type: MessageType.gatewayRemoveConnector, payload: payload)
        let response = try decoder.decode(GatewayRemoveConnectorResponsePayload.self, from: data)
        return response.removed
    }

    /// Submit one inbound connector event and receive routing directives.
    public func submitConnectorInboundEvent(
        _ payload: ConnectorSubmitInboundEventPayload
    ) async throws -> ConnectorInboundEventResultPayload {
        let data = try await sendAndWait(type: MessageType.connectorSubmitInboundEvent, payload: payload)
        return try decoder.decode(ConnectorInboundEventResultPayload.self, from: data)
    }

    /// List connector bindings, optionally filtered to one connector instance.
    public func listConnectorBindings(
        apiVersion: String? = nil,
        connectorId: String? = nil
    ) async throws -> [GatewayConnectorBinding] {
        let payload = GatewayListConnectorBindingsPayload(apiVersion: apiVersion, connectorId: connectorId)
        let data = try await sendAndWait(type: MessageType.gatewayListConnectorBindings, payload: payload)
        let response = try decoder.decode(GatewayListConnectorBindingsResponsePayload.self, from: data)
        return response.bindings
    }

    /// Create or update one connector binding.
    public func upsertConnectorBinding(_ payload: GatewayUpsertConnectorBindingPayload) async throws -> GatewayConnectorBinding {
        let data = try await sendAndWait(type: MessageType.gatewayUpsertConnectorBinding, payload: payload)
        let response = try decoder.decode(GatewayUpsertConnectorBindingResponsePayload.self, from: data)
        return response.binding
    }

    /// Remove one connector binding by binding ID.
    public func removeConnectorBinding(
        bindingId: String,
        apiVersion: String? = nil
    ) async throws -> Bool {
        let payload = GatewayRemoveConnectorBindingPayload(apiVersion: apiVersion, bindingId: bindingId)
        let data = try await sendAndWait(type: MessageType.gatewayRemoveConnectorBinding, payload: payload)
        let response = try decoder.decode(GatewayRemoveConnectorBindingResponsePayload.self, from: data)
        return response.removed
    }

    /// Read effective connector policy for a policy scope.
    public func getConnectorPolicy(
        scopeType: GatewayConnectorPolicyScopeType,
        scopeId: String,
        apiVersion: String? = nil
    ) async throws -> GatewayConnectorPolicy {
        let payload = GatewayGetConnectorPolicyPayload(
            apiVersion: apiVersion,
            scopeType: scopeType,
            scopeId: scopeId
        )
        let data = try await sendAndWait(type: MessageType.gatewayGetConnectorPolicy, payload: payload)
        let response = try decoder.decode(GatewayGetConnectorPolicyResponsePayload.self, from: data)
        return response.policy
    }

    /// Update connector policy for a policy scope.
    public func updateConnectorPolicy(_ payload: GatewayUpdateConnectorPolicyPayload) async throws -> GatewayConnectorPolicy {
        let data = try await sendAndWait(type: MessageType.gatewayUpdateConnectorPolicy, payload: payload)
        let response = try decoder.decode(GatewayUpdateConnectorPolicyResponsePayload.self, from: data)
        return response.policy
    }

    /// Read the unified gateway tool policy.
    public func getToolPolicy(apiVersion: String? = nil) async throws -> ToolAccessPolicy {
        let payload = GatewayGetToolPolicyPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.gatewayGetToolPolicy, payload: payload)
        let response = try decoder.decode(GatewayGetToolPolicyResponsePayload.self, from: data)
        return response.policy
    }

    /// Update the unified gateway tool policy.
    public func updateToolPolicy(_ payload: GatewayUpdateToolPolicyPayload) async throws -> ToolAccessPolicy {
        let data = try await sendAndWait(type: MessageType.gatewayUpdateToolPolicy, payload: payload)
        let response = try decoder.decode(GatewayUpdateToolPolicyResponsePayload.self, from: data)
        return response.policy
    }

    /// List seeded gateway safety profiles.
    public func listSafetyProfiles(apiVersion: String? = nil) async throws -> [SafetyProfileDefinition] {
        let payload = GatewayListSafetyProfilesPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.gatewayListSafetyProfiles, payload: payload)
        let response = try decoder.decode(GatewayListSafetyProfilesResponsePayload.self, from: data)
        return response.profiles
    }

    /// Run a connector self-check with policy and inbound-route diagnostics.
    public func testConnector(
        connectorId: String,
        apiVersion: String? = nil
    ) async throws -> GatewayTestConnectorResult {
        let payload = GatewayTestConnectorPayload(apiVersion: apiVersion, connectorId: connectorId)
        let data = try await sendAndWait(type: MessageType.gatewayTestConnector, payload: payload)
        let response = try decoder.decode(GatewayTestConnectorResponsePayload.self, from: data)
        return GatewayTestConnectorResult(
            ok: response.ok,
            reason: response.reason,
            connector: response.connector,
            inboundRoute: response.inboundRoute,
            policy: response.policy
        )
    }

    /// Read gateway usage snapshot (windowed token usage + budget).
    public func getUsageSnapshot(apiVersion: String? = nil) async throws -> UsageSnapshot {
        let payload = UsageGetSnapshotPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.usageGetSnapshot, payload: payload)
        let response = try decoder.decode(UsageGetSnapshotResponsePayload.self, from: data)
        return response.snapshot
    }

    /// Read gateway-wide capability/skill policy.
    public func getGatewayPolicy(apiVersion: String? = nil) async throws -> GatewayPolicy {
        let payload = GatewayGetPolicyPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.gatewayGetPolicy, payload: payload)
        let response = try decoder.decode(GatewayGetPolicyResponsePayload.self, from: data)
        return response.policy
    }

    /// Update gateway-wide capability/skill policy.
    public func updateGatewayPolicy(_ patch: GatewayPolicyUpdate) async throws -> GatewayPolicy {
        let payload = GatewayUpdatePolicyPayload(
            apiVersion: patch.apiVersion,
            allowedCapabilityTypes: patch.allowedCapabilityTypes,
            deniedCapabilityTypes: patch.deniedCapabilityTypes,
            allowedSkillIds: patch.allowedSkillIds,
            deniedSkillIds: patch.deniedSkillIds,
            globalFlags: patch.globalFlags
        )
        let data = try await sendAndWait(type: MessageType.gatewayUpdatePolicy, payload: payload)
        let response = try decoder.decode(GatewayUpdatePolicyResponsePayload.self, from: data)
        return response.policy
    }

    public func listGatewaySkills(
        query: String? = nil,
        tags: [String]? = nil,
        status: String? = nil,
        limit: Int? = nil
    ) async throws -> [GatewaySkillEntry] {
        let payload = GatewaySkillListPayload(query: query, tags: tags, status: status, limit: limit)
        let data = try await sendAndWait(type: MessageType.gatewaySkillList, payload: payload)
        let response = try decoder.decode(GatewaySkillListResponsePayload.self, from: data)
        return response.skills
    }

    public func listLibraryEntries(
        apiVersion: String? = nil,
        query: String? = nil,
        tags: [String]? = nil,
        status: LibraryEntryStatus? = nil,
        sourceKinds: [LibrarySourceKind]? = nil,
        includeArchived: Bool? = nil,
        includeContent: Bool? = nil,
        limit: Int? = nil
    ) async throws -> [LibraryEntry] {
        let payload = LibraryListEntriesPayload(
            apiVersion: apiVersion,
            query: query,
            tags: tags,
            status: status,
            sourceKinds: sourceKinds,
            includeArchived: includeArchived,
            includeContent: includeContent,
            limit: limit
        )
        let data = try await sendAndWait(type: MessageType.libraryListEntries, payload: payload)
        let response = try decoder.decode(LibraryListEntriesResponsePayload.self, from: data)
        return response.entries
    }

    public func getLibraryEntry(
        entryId: String,
        apiVersion: String? = nil,
        includeContent: Bool? = nil
    ) async throws -> LibraryEntry {
        let payload = LibraryGetEntryPayload(
            apiVersion: apiVersion,
            entryId: entryId,
            includeContent: includeContent
        )
        let data = try await sendAndWait(type: MessageType.libraryGetEntry, payload: payload)
        let response = try decoder.decode(LibraryGetEntryResponsePayload.self, from: data)
        return response.entry
    }

    public func saveLibrarySkill(_ payload: LibrarySaveSkillPayload) async throws -> LibrarySaveSkillResult {
        let data = try await sendAndWait(type: MessageType.librarySaveSkill, payload: payload)
        let response = try decoder.decode(LibrarySaveSkillResponsePayload.self, from: data)
        return LibrarySaveSkillResult(entry: response.entry, created: response.created)
    }

    public func importLibraryEntry(_ payload: LibraryImportEntryPayload) async throws -> LibraryImportEntryResult {
        let data = try await sendAndWait(type: MessageType.libraryImportEntry, payload: payload)
        let response = try decoder.decode(LibraryImportEntryResponsePayload.self, from: data)
        return LibraryImportEntryResult(entry: response.entry, created: response.created)
    }

    public func archiveLibraryEntry(_ payload: LibraryArchiveEntryPayload) async throws -> LibraryArchiveEntryResult {
        let data = try await sendAndWait(type: MessageType.libraryArchiveEntry, payload: payload)
        let response = try decoder.decode(LibraryArchiveEntryResponsePayload.self, from: data)
        return LibraryArchiveEntryResult(entry: response.entry, archived: response.archived)
    }

    public func setLibraryEntryEnabled(_ payload: LibrarySetEntryEnabledPayload) async throws -> LibraryEntry {
        let data = try await sendAndWait(type: MessageType.librarySetEntryEnabled, payload: payload)
        let response = try decoder.decode(LibrarySetEntryEnabledResponsePayload.self, from: data)
        return response.entry
    }

    public func deleteLibraryEntry(_ payload: LibraryDeleteEntryPayload) async throws -> LibraryDeleteEntryResult {
        let data = try await sendAndWait(type: MessageType.libraryDeleteEntry, payload: payload)
        let response = try decoder.decode(LibraryDeleteEntryResponsePayload.self, from: data)
        return LibraryDeleteEntryResult(entryId: response.entryId, deleted: response.deleted)
    }

    public func scanLibraryEntries(apiVersion: String? = nil) async throws -> LibraryScanEntriesResult {
        let payload = LibraryScanEntriesPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.libraryScanEntries, payload: payload)
        let response = try decoder.decode(LibraryScanEntriesResponsePayload.self, from: data)
        return LibraryScanEntriesResult(entries: response.entries, scannedAt: response.scannedAt)
    }

    public func listSkillDrafts(apiVersion: String? = nil) async throws -> [SkillDraft] {
        let payload = LibraryListSkillDraftsPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.libraryListSkillDrafts, payload: payload)
        let response = try decoder.decode(LibraryListSkillDraftsResponsePayload.self, from: data)
        return response.drafts
    }

    public func getSkillDraft(draftId: String, apiVersion: String? = nil) async throws -> SkillDraft {
        let payload = LibraryGetSkillDraftPayload(apiVersion: apiVersion, draftId: draftId)
        let data = try await sendAndWait(type: MessageType.libraryGetSkillDraft, payload: payload)
        let response = try decoder.decode(LibraryGetSkillDraftResponsePayload.self, from: data)
        return response.draft
    }

    public func createSkillDraft(
        _ payload: LibraryCreateSkillDraftPayload
    ) async throws -> LibraryCreateSkillDraftResult {
        let data = try await sendAndWait(type: MessageType.libraryCreateSkillDraft, payload: payload)
        let response = try decoder.decode(LibraryCreateSkillDraftResponsePayload.self, from: data)
        return LibraryCreateSkillDraftResult(draft: response.draft, created: response.created)
    }

    public func deleteSkillDraft(
        _ payload: LibraryDeleteSkillDraftPayload
    ) async throws -> LibraryDeleteSkillDraftResult {
        let data = try await sendAndWait(type: MessageType.libraryDeleteSkillDraft, payload: payload)
        let response = try decoder.decode(LibraryDeleteSkillDraftResponsePayload.self, from: data)
        return LibraryDeleteSkillDraftResult(draftId: response.draftId, deleted: response.deleted)
    }

    /// List gateway knowledge base entries (global + optional space-scoped).
    public func listKnowledgeBaseEntries(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        query: String? = nil,
        tags: [String]? = nil,
        kinds: [GatewayKnowledgeBaseEntryKind]? = nil,
        limit: Int? = nil
    ) async throws -> [GatewayKnowledgeBaseEntry] {
        let payload = GatewayListKnowledgeBaseEntriesPayload(
            apiVersion: apiVersion,
            spaceId: spaceId,
            query: query,
            tags: tags,
            kinds: kinds,
            limit: limit
        )
        let data = try await sendAndWait(type: MessageType.gatewayKbListEntries, payload: payload)
        let response = try decoder.decode(GatewayListKnowledgeBaseEntriesResponsePayload.self, from: data)
        return response.entries
    }

    /// Create or update one gateway knowledge base entry.
    public func upsertKnowledgeBaseEntry(
        _ payload: GatewayUpsertKnowledgeBaseEntryPayload
    ) async throws -> GatewayKnowledgeBaseEntry {
        let data = try await sendAndWait(type: MessageType.gatewayKbUpsertEntry, payload: payload)
        let response = try decoder.decode(GatewayUpsertKnowledgeBaseEntryResponsePayload.self, from: data)
        return response.entry
    }

    /// Delete one gateway knowledge base entry by ID.
    public func deleteKnowledgeBaseEntry(
        entryId: String,
        apiVersion: String? = nil
    ) async throws -> Bool {
        let payload = GatewayDeleteKnowledgeBaseEntryPayload(apiVersion: apiVersion, entryId: entryId)
        let data = try await sendAndWait(type: MessageType.gatewayKbDeleteEntry, payload: payload)
        let response = try decoder.decode(GatewayDeleteKnowledgeBaseEntryResponsePayload.self, from: data)
        return response.deleted
    }

    /// List capability grants, optionally filtered by principal/device and grant status.
    public func listCapabilityGrants(
        apiVersion: String? = nil,
        principalId: String? = nil,
        deviceId: String? = nil,
        includeRevoked: Bool? = nil,
        includeExpired: Bool? = nil
    ) async throws -> [GatewayCapabilityGrant] {
        let payload = GatewayListCapabilityGrantsPayload(
            apiVersion: apiVersion,
            principalId: principalId,
            deviceId: deviceId,
            includeRevoked: includeRevoked,
            includeExpired: includeExpired
        )
        let data = try await sendAndWait(type: MessageType.gatewayListCapabilityGrants, payload: payload)
        let response = try decoder.decode(GatewayListCapabilityGrantsResponsePayload.self, from: data)
        return response.grants
    }

    /// Grant capability access for a principal/device scope.
    public func grantCapability(_ payload: GatewayGrantCapabilityPayload) async throws -> GatewayCapabilityGrant {
        let data = try await sendAndWait(type: MessageType.gatewayGrantCapability, payload: payload)
        let response = try decoder.decode(GatewayGrantCapabilityResponsePayload.self, from: data)
        return response.grant
    }

    /// Revoke capability access for a principal/device scope.
    public func revokeCapability(_ payload: GatewayRevokeCapabilityPayload) async throws -> GatewayRevokeCapabilityResult {
        let data = try await sendAndWait(type: MessageType.gatewayRevokeCapability, payload: payload)
        let response = try decoder.decode(GatewayRevokeCapabilityResponsePayload.self, from: data)
        return GatewayRevokeCapabilityResult(
            revoked: response.revoked,
            capabilityId: response.capabilityId,
            principalId: response.principalId,
            deviceId: response.deviceId,
            grant: response.grant
        )
    }

    /// Submit an orchestrator intent-level command.
    public func sendOrchestratorCommand(
        _ payload: OrchestratorCommandPayload
    ) async throws -> OrchestratorCommandResult {
        let data = try await sendAndWait(type: MessageType.orchestratorCommand, payload: payload)
        let response = try decoder.decode(OrchestratorCommandResponsePayload.self, from: data)
        return response.command
    }

    /// Get orchestrator command state by command ID.
    public func getOrchestratorCommand(
        commandId: String,
        apiVersion: String? = nil
    ) async throws -> OrchestratorCommandResult {
        let payload = OrchestratorGetCommandPayload(apiVersion: apiVersion, commandId: commandId)
        let data = try await sendAndWait(type: MessageType.orchestratorGetCommand, payload: payload)
        let response = try decoder.decode(OrchestratorCommandResponsePayload.self, from: data)
        return response.command
    }

    /// Fetch a concise digest for a target space through the orchestrator control plane.
    public func getSpaceDigest(
        spaceId: String,
        sourceSpaceId: String? = nil,
        window: String = "latest"
    ) async throws -> SpaceDigestResult {
        let command = try await sendOrchestratorCommand(
            OrchestratorCommandPayload(
                commandType: "get_space_digest",
                targetSpaceId: sourceSpaceId ?? spaceId,
                payload: [
                    "spaceId": spaceId,
                    "window": window,
                ]
            )
        )
        return try decodeOrchestratorResult(command, as: SpaceDigestResult.self)
    }

    public func createSchedulerJob(_ payload: SchedulerCreateJobPayload) async throws -> SchedulerJob {
        let data = try await sendAndWait(type: MessageType.schedulerCreateJob, payload: payload)
        let response = try decoder.decode(SchedulerCreateJobResponsePayload.self, from: data)
        return response.job
    }

    public func getSchedulerJob(
        jobId: String,
        apiVersion: String? = nil
    ) async throws -> SchedulerJob {
        let payload = SchedulerGetJobPayload(apiVersion: apiVersion, jobId: jobId)
        let data = try await sendAndWait(type: MessageType.schedulerGetJob, payload: payload)
        let response = try decoder.decode(SchedulerGetJobResponsePayload.self, from: data)
        return response.job
    }

    public func listSchedulerJobs(payload: SchedulerListJobsPayload = .init(
        apiVersion: nil,
        statuses: nil,
        gatewayId: nil,
        limit: nil
    )) async throws -> [SchedulerJob] {
        let data = try await sendAndWait(type: MessageType.schedulerListJobs, payload: payload)
        let response = try decoder.decode(SchedulerListJobsResponsePayload.self, from: data)
        return response.jobs
    }

    public func updateSchedulerJob(_ payload: SchedulerUpdateJobPayload) async throws -> SchedulerJob {
        let data = try await sendAndWait(type: MessageType.schedulerUpdateJob, payload: payload)
        let response = try decoder.decode(SchedulerUpdateJobResponsePayload.self, from: data)
        return response.job
    }

    public func deleteSchedulerJob(_ payload: SchedulerDeleteJobPayload) async throws -> SchedulerDeleteJobResult {
        let data = try await sendAndWait(type: MessageType.schedulerDeleteJob, payload: payload)
        let response = try decoder.decode(SchedulerDeleteJobResponsePayload.self, from: data)
        return SchedulerDeleteJobResult(jobId: response.jobId, deleted: response.deleted)
    }

    public func linkSchedulerJobSpace(_ payload: SchedulerLinkSpacePayload) async throws -> SchedulerJob {
        let data = try await sendAndWait(type: MessageType.schedulerLinkSpace, payload: payload)
        let response = try decoder.decode(SchedulerLinkSpaceResponsePayload.self, from: data)
        return response.job
    }

    public func unlinkSchedulerJobSpace(_ payload: SchedulerUnlinkSpacePayload) async throws -> SchedulerJob {
        let data = try await sendAndWait(type: MessageType.schedulerUnlinkSpace, payload: payload)
        let response = try decoder.decode(SchedulerUnlinkSpaceResponsePayload.self, from: data)
        return response.job
    }

    public func listSchedulerJobRuns(_ payload: SchedulerListRunsPayload) async throws -> SchedulerListRunsResult {
        let data = try await sendAndWait(type: MessageType.schedulerListRuns, payload: payload)
        let response = try decoder.decode(SchedulerListRunsResponsePayload.self, from: data)
        return SchedulerListRunsResult(runs: response.runs, total: response.total, nextOffset: response.nextOffset)
    }

    public func runSchedulerJobNow(_ payload: SchedulerRunNowPayload) async throws -> SchedulerRunNowResult {
        let data = try await sendAndWait(type: MessageType.schedulerRunNow, payload: payload)
        let response = try decoder.decode(SchedulerRunNowResponsePayload.self, from: data)
        return SchedulerRunNowResult(run: response.run, job: response.job)
    }

    public func linkSpaces(
        sourceSpaceId: String,
        targetSpaceId: String,
        mode: String? = nil,
        apiVersion: String? = nil
    ) async throws -> SpaceLinkResult {
        let payload = SpaceLinkPayload(
            apiVersion: apiVersion,
            sourceSpaceId: sourceSpaceId,
            targetSpaceId: targetSpaceId,
            mode: mode
        )
        let data = try await sendAndWait(type: MessageType.spaceLink, payload: payload)
        let response = try decoder.decode(SpaceLinkResponsePayload.self, from: data)
        return response.link
    }

    public func unlinkSpaces(
        sourceSpaceId: String,
        targetSpaceId: String,
        apiVersion: String? = nil
    ) async throws -> Bool {
        let payload = SpaceUnlinkPayload(
            apiVersion: apiVersion,
            sourceSpaceId: sourceSpaceId,
            targetSpaceId: targetSpaceId
        )
        let data = try await sendAndWait(type: MessageType.spaceUnlink, payload: payload)
        let response = try decoder.decode(SpaceUnlinkResponsePayload.self, from: data)
        return response.removed
    }

    public func shareSpaceContext(
        sourceSpaceId: String,
        targetSpaceId: String,
        artifactId: String,
        apiVersion: String? = nil
    ) async throws -> SharedContextRef {
        let payload = SpaceShareContextPayload(
            apiVersion: apiVersion,
            sourceSpaceId: sourceSpaceId,
            targetSpaceId: targetSpaceId,
            artifactId: artifactId
        )
        let data = try await sendAndWait(type: MessageType.spaceShareContext, payload: payload)
        let response = try decoder.decode(SpaceShareContextResponsePayload.self, from: data)
        return response.transfer
    }

    public func pullSharedContext(
        sourceSpaceId: String,
        targetSpaceId: String,
        limit: Int? = nil,
        apiVersion: String? = nil
    ) async throws -> SpacePullSharedContextResult {
        let payload = SpacePullSharedContextPayload(
            apiVersion: apiVersion,
            sourceSpaceId: sourceSpaceId,
            targetSpaceId: targetSpaceId,
            limit: limit
        )
        let data = try await sendAndWait(type: MessageType.spacePullSharedContext, payload: payload)
        return try decoder.decode(SpacePullSharedContextResult.self, from: data)
    }

    public func createSpaceShareInvite(
        spaceId: String,
        mode: SpaceShareAccessMode,
        expiresInSeconds: Int? = nil,
        apiVersion: String? = nil
    ) async throws -> SpaceShareInvite {
        let payload = SpaceShareCreateInvitePayload(
            apiVersion: apiVersion,
            spaceId: spaceId,
            mode: mode,
            expiresInSeconds: expiresInSeconds
        )
        let data = try await sendAndWait(type: MessageType.spaceShareCreateInvite, payload: payload)
        let response = try decoder.decode(SpaceShareCreateInviteResponsePayload.self, from: data)
        return response.invite
    }

    public func joinSpaceShareInvite(
        spaceId: String,
        inviteToken: String,
        deviceId: String? = nil,
        devicePublicKey: String? = nil,
        identityModeHint: SpaceShareIdentityModeHint? = nil,
        appleIdAssertion: String? = nil,
        joinRoute: SpaceShareJoinRoute? = nil,
        relaySessionToken: String? = nil,
        apiVersion: String? = nil
    ) async throws -> SpaceParticipant {
        let payload = SpaceShareJoinPayload(
            apiVersion: apiVersion,
            spaceId: spaceId,
            inviteToken: inviteToken,
            deviceId: deviceId,
            devicePublicKey: devicePublicKey,
            identityModeHint: identityModeHint,
            appleIdAssertion: appleIdAssertion,
            joinRoute: joinRoute,
            relaySessionToken: relaySessionToken
        )
        let data = try await sendAndWait(type: MessageType.spaceShareJoin, payload: payload)
        let response = try decoder.decode(SpaceShareJoinResponsePayload.self, from: data)
        return response.participant
    }

    public func revokeSpaceShareAccess(
        spaceId: String,
        inviteId: String? = nil,
        participantId: String? = nil,
        apiVersion: String? = nil
    ) async throws -> SpaceShareRevokeResult {
        let payload = SpaceShareRevokePayload(
            apiVersion: apiVersion,
            spaceId: spaceId,
            inviteId: inviteId,
            participantId: participantId
        )
        let data = try await sendAndWait(type: MessageType.spaceShareRevoke, payload: payload)
        return try decoder.decode(SpaceShareRevokeResult.self, from: data)
    }

    public func listSpaceParticipants(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> [SpaceParticipant] {
        let payload = SpaceShareListParticipantsPayload(
            apiVersion: apiVersion,
            spaceId: spaceId
        )
        let data = try await sendAndWait(type: MessageType.spaceShareListParticipants, payload: payload)
        let response = try decoder.decode(SpaceShareListParticipantsResponsePayload.self, from: data)
        return response.participants
    }

    /// Announce sync peer/resource capability without constructing payloads in callers.
    public func announceSyncPeer(
        apiVersion: String? = nil,
        peerId: String,
        resourceId: String,
        gatewayVersion: String,
        endpointUrl: String? = nil,
        authSecretHash: String? = nil,
        skillCount: Int? = nil,
        actionCount: Int? = nil,
        experienceCount: Int? = nil,
        profileCount: Int? = nil
    ) async throws -> SyncAnnounceResult {
        let payload = SyncAnnouncePayload(
            apiVersion: apiVersion,
            peerId: peerId,
            resourceId: resourceId,
            gatewayVersion: gatewayVersion,
            endpointUrl: endpointUrl,
            authSecretHash: authSecretHash,
            skillCount: skillCount,
            actionCount: actionCount,
            experienceCount: experienceCount,
            profileCount: profileCount
        )
        return try await announceSyncPeer(payload)
    }

    /// Query sync resources without constructing payloads in callers.
    public func querySyncResources(
        apiVersion: String? = nil,
        peerId: String,
        resourceId: String? = nil,
        types: [String]? = nil,
        tags: [String]? = nil,
        updatedAfter: String? = nil,
        cursor: String? = nil,
        limit: Int? = nil
    ) async throws -> SyncQueryResourcesResult {
        let payload = SyncQueryResourcesPayload(
            apiVersion: apiVersion,
            peerId: peerId,
            resourceId: resourceId,
            types: types,
            tags: tags,
            updatedAfter: updatedAfter,
            cursor: cursor,
            limit: limit
        )
        return try await querySyncResources(payload)
    }

    /// Pull sync resources without constructing payloads in callers.
    public func pullSyncResources(
        apiVersion: String? = nil,
        peerId: String,
        idempotencyKey: String,
        refs: [SyncResourceRef]
    ) async throws -> SyncPullResourcesResult {
        let payload = SyncPullResourcesPayload(
            apiVersion: apiVersion,
            peerId: peerId,
            idempotencyKey: idempotencyKey,
            refs: refs
        )
        return try await pullSyncResources(payload)
    }

    public func announceSyncPeer(_ payload: SyncAnnouncePayload) async throws -> SyncAnnounceResult {
        let data = try await sendAndWait(type: MessageType.syncAnnounce, payload: payload)
        return try decoder.decode(SyncAnnounceResult.self, from: data)
    }

    public func querySyncResources(_ payload: SyncQueryResourcesPayload) async throws -> SyncQueryResourcesResult {
        let data = try await sendAndWait(type: MessageType.syncQueryResources, payload: payload)
        return try decoder.decode(SyncQueryResourcesResult.self, from: data)
    }

    public func pullSyncResources(_ payload: SyncPullResourcesPayload) async throws -> SyncPullResourcesResult {
        let data = try await sendAndWait(type: MessageType.syncPullResources, payload: payload)
        return try decoder.decode(SyncPullResourcesResult.self, from: data)
    }

    /// Start speech session without constructing payloads in callers.
    public func startSpeechSession(
        apiVersion: String? = nil,
        spaceId: String,
        spaceUid: String? = nil,
        sessionId: String? = nil,
        locale: String? = nil,
        sourceDevice: String? = nil,
        enableTranscription: Bool? = nil,
        enablePlayback: Bool? = nil,
        agentId: String? = nil,
        autoSubmitTurns: Bool? = nil,
        preferredSource: String? = nil,
        preferredProviderId: String? = nil,
        byokProviderId: String? = nil,
        localModelProviderId: String? = nil,
        appleSpeechProviderId: String? = nil,
        allowByokFallback: Bool? = nil,
        allowLocalFallback: Bool? = nil,
        allowAppleSpeechFallback: Bool? = nil,
        sttPreferences: SpeechRoutePreferences? = nil,
        ttsPreferences: SpeechRoutePreferences? = nil
    ) async throws -> SpeechSessionEvent {
        let payload = SpeechStartPayload(
            apiVersion: apiVersion,
            spaceId: spaceId,
            spaceUid: spaceUid,
            sessionId: sessionId,
            locale: locale,
            sourceDevice: sourceDevice,
            enableTranscription: enableTranscription,
            enablePlayback: enablePlayback,
            agentId: agentId,
            autoSubmitTurns: autoSubmitTurns,
            preferredSource: preferredSource,
            preferredProviderId: preferredProviderId,
            byokProviderId: byokProviderId,
            localModelProviderId: localModelProviderId,
            appleSpeechProviderId: appleSpeechProviderId,
            allowByokFallback: allowByokFallback,
            allowLocalFallback: allowLocalFallback,
            allowAppleSpeechFallback: allowAppleSpeechFallback,
            sttPreferences: sttPreferences,
            ttsPreferences: ttsPreferences
        )
        return try await startSpeechSession(payload)
    }

    public func startSpeechSession(_ payload: SpeechStartPayload) async throws -> SpeechSessionEvent {
        let data = try await sendAndWait(type: MessageType.speechStart, payload: payload)
        let response = try decoder.decode(SpeechEventResponsePayload.self, from: data)
        return response.event
    }

    public func sendSpeechAudioChunk(_ payload: SpeechAudioChunkPayload) async throws -> [SpeechSessionEvent] {
        let data = try await sendAndWait(type: MessageType.speechAudioChunk, payload: payload)
        let response = try decoder.decode(SpeechEventsResponsePayload.self, from: data)
        return response.events
    }

    /// Control speech session without constructing payloads in callers.
    public func controlSpeechSession(
        sessionId: String,
        command: String,
        reason: String? = nil,
        apiVersion: String? = nil
    ) async throws -> SpeechSessionEvent {
        let payload = SpeechControlPayload(
            apiVersion: apiVersion,
            sessionId: sessionId,
            command: command,
            reason: reason
        )
        return try await controlSpeechSession(payload)
    }

    public func controlSpeechSession(_ payload: SpeechControlPayload) async throws -> SpeechSessionEvent {
        let data = try await sendAndWait(type: MessageType.speechControl, payload: payload)
        let response = try decoder.decode(SpeechEventResponsePayload.self, from: data)
        return response.event
    }

    public func startConciergeCall(
        apiVersion: String? = nil,
        callId: String,
        deviceId: String? = nil,
        platform: String,
        ttsMode: String? = nil,
        targetGatewayId: String? = nil,
        displayName: String? = nil,
        handoffContext: ConciergeCallHandoffContext? = nil,
        spaceId: String? = nil,
        spaceUid: String? = nil,
        targetAgentId: String? = nil
    ) async throws -> ConciergeCallEvent {
        let payload = ConciergeCallStartPayload(
            apiVersion: apiVersion,
            callId: callId,
            deviceId: deviceId,
            platform: platform,
            ttsMode: ttsMode,
            targetGatewayId: targetGatewayId,
            displayName: displayName,
            handoffContext: handoffContext,
            spaceId: spaceId,
            spaceUid: spaceUid,
            targetAgentId: targetAgentId
        )
        return try await startConciergeCall(payload)
    }

    public func startConciergeCall(_ payload: ConciergeCallStartPayload) async throws -> ConciergeCallEvent {
        let data = try await sendAndWait(type: MessageType.conciergeCallStart, payload: payload)
        let response = try decoder.decode(ConciergeCallEventResponsePayload.self, from: data)
        return response.event
    }

    public func answerConciergeCall(
        callId: String,
        deviceId: String? = nil,
        platform: String? = nil,
        apiVersion: String? = nil
    ) async throws -> ConciergeCallEvent {
        let payload = ConciergeCallAnswerPayload(
            apiVersion: apiVersion,
            callId: callId,
            deviceId: deviceId,
            platform: platform
        )
        return try await answerConciergeCall(payload)
    }

    public func answerConciergeCall(_ payload: ConciergeCallAnswerPayload) async throws -> ConciergeCallEvent {
        let data = try await sendAndWait(type: MessageType.conciergeCallAnswer, payload: payload)
        let response = try decoder.decode(ConciergeCallEventResponsePayload.self, from: data)
        return response.event
    }

    public func endConciergeCall(
        callId: String,
        reason: String? = nil,
        apiVersion: String? = nil
    ) async throws -> ConciergeCallEvent {
        let payload = ConciergeCallEndPayload(
            apiVersion: apiVersion,
            callId: callId,
            reason: reason
        )
        return try await endConciergeCall(payload)
    }

    public func endConciergeCall(_ payload: ConciergeCallEndPayload) async throws -> ConciergeCallEvent {
        let data = try await sendAndWait(type: MessageType.conciergeCallEnd, payload: payload)
        let response = try decoder.decode(ConciergeCallEventResponsePayload.self, from: data)
        return response.event
    }

    public func setConciergeCallMuted(
        callId: String,
        muted: Bool,
        apiVersion: String? = nil
    ) async throws -> ConciergeCallEvent {
        let payload = ConciergeCallSetMutedPayload(
            apiVersion: apiVersion,
            callId: callId,
            muted: muted
        )
        return try await setConciergeCallMuted(payload)
    }

    public func setConciergeCallMuted(_ payload: ConciergeCallSetMutedPayload) async throws -> ConciergeCallEvent {
        let data = try await sendAndWait(type: MessageType.conciergeCallSetMuted, payload: payload)
        let response = try decoder.decode(ConciergeCallEventResponsePayload.self, from: data)
        return response.event
    }

    public func appendConciergeCallAudio(
        callId: String,
        sequence: Int,
        audioBase64: String,
        audioDurationSeconds: Double? = nil,
        sampleRateHz: Int? = nil,
        channels: Int? = nil,
        codec: String? = nil,
        transcriptText: String? = nil,
        isFinal: Bool? = nil,
        apiVersion: String? = nil
    ) async throws -> [ConciergeCallEvent] {
        let payload = ConciergeCallAudioChunkPayload(
            apiVersion: apiVersion,
            callId: callId,
            sequence: sequence,
            audioBase64: audioBase64,
            audioDurationSeconds: audioDurationSeconds,
            sampleRateHz: sampleRateHz,
            channels: channels,
            codec: codec,
            transcriptText: transcriptText,
            isFinal: isFinal
        )
        return try await appendConciergeCallAudio(payload)
    }

    public func appendConciergeCallAudio(_ payload: ConciergeCallAudioChunkPayload) async throws -> [ConciergeCallEvent] {
        let data = try await sendAndWait(type: MessageType.conciergeCallAudioChunk, payload: payload)
        let response = try decoder.decode(ConciergeCallEventsResponsePayload.self, from: data)
        return response.events
    }

    public func controlConciergeCall(
        callId: String,
        command: String,
        reason: String? = nil,
        apiVersion: String? = nil
    ) async throws -> ConciergeCallEvent {
        let payload = ConciergeCallControlPayload(
            apiVersion: apiVersion,
            callId: callId,
            command: command,
            reason: reason
        )
        return try await controlConciergeCall(payload)
    }

    public func controlConciergeCall(_ payload: ConciergeCallControlPayload) async throws -> ConciergeCallEvent {
        let data = try await sendAndWait(type: MessageType.conciergeCallControl, payload: payload)
        let response = try decoder.decode(ConciergeCallEventResponsePayload.self, from: data)
        return response.event
    }

    public func prepareConciergeCallHandoff(
        callId: String,
        sourceDeviceId: String? = nil,
        destinationPlatform: String,
        destinationDeviceId: String? = nil,
        destinationClientId: String? = nil,
        resumeUrl: String? = nil,
        apiVersion: String? = nil
    ) async throws -> ConciergeCallHandoffPreparation {
        let payload = ConciergeCallHandoffPreparePayload(
            apiVersion: apiVersion,
            callId: callId,
            sourceDeviceId: sourceDeviceId,
            destinationPlatform: destinationPlatform,
            destinationDeviceId: destinationDeviceId,
            destinationClientId: destinationClientId,
            resumeUrl: resumeUrl
        )
        return try await prepareConciergeCallHandoff(payload)
    }

    public func prepareConciergeCallHandoff(_ payload: ConciergeCallHandoffPreparePayload) async throws -> ConciergeCallHandoffPreparation {
        let data = try await sendAndWait(type: MessageType.conciergeCallHandoffPrepare, payload: payload)
        return try decoder.decode(ConciergeCallHandoffPreparation.self, from: data)
    }

    public func acceptConciergeCallHandoff(
        callId: String,
        handoffToken: String,
        deviceId: String? = nil,
        platform: String? = nil,
        apiVersion: String? = nil
    ) async throws -> ConciergeCallEvent {
        let payload = ConciergeCallHandoffAcceptPayload(
            apiVersion: apiVersion,
            callId: callId,
            handoffToken: handoffToken,
            deviceId: deviceId,
            platform: platform
        )
        return try await acceptConciergeCallHandoff(payload)
    }

    public func acceptConciergeCallHandoff(_ payload: ConciergeCallHandoffAcceptPayload) async throws -> ConciergeCallEvent {
        let data = try await sendAndWait(type: MessageType.conciergeCallHandoffAccept, payload: payload)
        let response = try decoder.decode(ConciergeCallEventResponsePayload.self, from: data)
        return response.event
    }

    public func registerConciergeCallPush(
        deviceId: String? = nil,
        platform: String,
        pushToken: String,
        voipTopic: String? = nil,
        proactiveOptIn: Bool? = nil,
        apiVersion: String? = nil
    ) async throws -> ConciergeVoipPushRegistration {
        let payload = ConciergeCallRegisterPushPayload(
            apiVersion: apiVersion,
            deviceId: deviceId,
            platform: platform,
            pushToken: pushToken,
            voipTopic: voipTopic,
            proactiveOptIn: proactiveOptIn
        )
        return try await registerConciergeCallPush(payload)
    }

    public func registerConciergeCallPush(_ payload: ConciergeCallRegisterPushPayload) async throws -> ConciergeVoipPushRegistration {
        let data = try await sendAndWait(type: MessageType.conciergeCallRegisterPush, payload: payload)
        let response = try decoder.decode(ConciergeCallRegisterPushResponsePayload.self, from: data)
        return response.registration
    }

    /// Ensure a main space exists and optionally subscribe to it.
    public func ensureMainSpace(
        _ options: MainSpaceBootstrapOptions = .init()
    ) async throws -> MainSpaceBootstrapResult {
        let spaces = try await listSpaces(
            apiVersion: options.apiVersion,
            statuses: nil,
            resourceId: options.resourceId,
            limit: 200
        )

        var space = spaces.first(where: { $0.id == options.spaceId })
        var created = false

        if space == nil && options.createIfMissing {
            let payload = SpaceCreatePayload(
                apiVersion: options.apiVersion,
                spaceId: options.spaceId,
                resourceId: options.resourceId,
                name: options.name,
                goal: options.goal,
                visibility: "shared",
                thinkingCapturePolicy: options.thinkingCapturePolicy,
                initialAgents: options.initialAgents
            )
            space = try await createSpace(payload)
            created = true
        }

        guard let resolvedSpace = space else {
            throw GatewayError(
                code: "NOT_FOUND",
                message: "Main space not found: \(options.spaceId)",
                details: nil
            )
        }

        var subscribed = false
        if options.subscribe {
            try await subscribe(spaceUids: [resolvedSpace.spaceUid])
            subscribed = true
        }

        return MainSpaceBootstrapResult(
            space: resolvedSpace,
            created: created,
            subscribed: subscribed
        )
    }

    /// Connect (if needed), then ensure/subscribe main space.
    public func connectAndBootstrapMainSpace(
        _ options: MainSpaceBootstrapOptions = .init()
    ) async throws -> ConnectAndBootstrapResult {
        let connected: Bool
        switch state {
        case .connected, .authenticating:
            connected = false
        default:
            try await connect()
            connected = true
        }

        let result = try await ensureMainSpace(options)
        return ConnectAndBootstrapResult(
            space: result.space,
            created: result.created,
            subscribed: result.subscribed,
            connected: connected
        )
    }

    /// Send a direct message to another agent in a space.
    public func sendAgentMessage(
        spaceId: String,
        spaceUid: String? = nil,
        fromAgentId: String,
        toAgentId: String,
        content: String,
        metadata: [String: Any]? = nil
    ) async throws {
        let payload = AgentMessagePayload(
            spaceId: spaceId,
            spaceUid: spaceUid ?? spaceId,
            fromAgentId: fromAgentId,
            toAgentId: toAgentId,
            content: content,
            metadata: metadata
        )
        _ = try await send(type: MessageType.agentMessage, payload: payload)
    }

    /// Poke an idle agent to resume work.
    public func pokeAgent(
        spaceId: String,
        spaceUid: String? = nil,
        targetAgentId: String,
        reason: String,
        unblockedByTurnId: String? = nil
    ) async throws {
        let payload = AgentPokePayload(
            spaceId: spaceId,
            spaceUid: spaceUid ?? spaceId,
            targetAgentId: targetAgentId,
            reason: reason,
            unblockedByTurnId: unblockedByTurnId
        )
        _ = try await send(type: MessageType.agentPoke, payload: payload)
    }

    /// Declare a task dependency between turns.
    public func declareTaskDependency(
        spaceId: String,
        spaceUid: String? = nil,
        blockedTurnId: String,
        dependsOnTurnId: String
    ) async throws {
        let payload = TaskDependencyPayload(
            spaceId: spaceId,
            spaceUid: spaceUid ?? spaceId,
            blockedTurnId: blockedTurnId,
            dependsOnTurnId: dependsOnTurnId
        )
        _ = try await send(type: MessageType.taskDependency, payload: payload)
    }

    /// Ping the gateway.
    public func ping() async throws {
        _ = try await sendAndWait(type: MessageType.ping, payload: EmptyPayload())
    }

    // MARK: - Private: Send

    private func send<T: Codable>(type: String, payload: T) async throws -> String {
        guard let ws = task else {
            throw GatewayError(code: "NOT_CONNECTED", message: "WebSocket not connected", details: nil)
        }

        let messageId = UUID().uuidString
        let message = GatewayMessage(type: type, id: messageId, payload: payload)
        let data = try encoder.encode(message)
        let string = String(data: data, encoding: .utf8)!

        try await ws.send(.string(string))

        return messageId
    }

    private func sendAndWait(
        type: String,
        payload: some Codable,
        timeoutSec: TimeInterval? = nil
    ) async throws -> Data {
        let messageId = UUID().uuidString
        let message = GatewayMessage(type: type, id: messageId, payload: payload)
        let data = try encoder.encode(message)
        guard let encodedMessage = String(data: data, encoding: .utf8) else {
            throw GatewayError(
                code: "ENCODE_ERROR",
                message: "Failed to encode gateway message as UTF-8.",
                details: nil
            )
        }
        let timeoutNanos = requestTimeoutNanoseconds(timeoutSec: timeoutSec)

        return try await withUnsafeThrowingContinuation { continuation in
            pendingRequests[messageId] = PendingRequest(continuation: continuation)

            Task { [weak self] in
                await self?.sendPendingRequest(messageId: messageId, encodedMessage: encodedMessage)
            }

            // Schedule timeout
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: timeoutNanos)
                await self?.timeoutRequest(messageId)
            }
        }
    }

    private func decodeOrchestratorResult<T: Decodable>(
        _ command: OrchestratorCommandResult,
        as type: T.Type
    ) throws -> T {
        guard command.status == "completed" else {
            if let error = command.error {
                throw error
            }
            throw GatewayError(
                code: "FAILED_PRECONDITION",
                message: "Gateway command did not complete successfully.",
                details: nil
            )
        }

        guard let payload = command.result else {
            throw GatewayError(
                code: "FAILED_PRECONDITION",
                message: "Gateway command returned no payload.",
                details: nil
            )
        }

        let jsonObject = payload.mapValues(\.value)
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        return try decoder.decode(type, from: data)
    }

    private func requestTimeoutNanoseconds(timeoutSec: TimeInterval?) -> UInt64 {
        let effectiveTimeout = max(timeoutSec ?? options.requestTimeoutSec, 0.1)
        return UInt64((effectiveTimeout * 1_000_000_000).rounded())
    }

    private func timeoutRequest(_ messageId: String) {
        guard let pending = pendingRequests.removeValue(forKey: messageId) else { return }
        pending.continuation.resume(throwing: GatewayError(
            code: "TIMEOUT",
            message: "Request timed out",
            details: nil
        ))
    }

    private func sendPendingRequest(messageId: String, encodedMessage: String) async {
        guard let ws = task else {
            failPendingRequest(
                messageId,
                error: GatewayError(
                    code: "NOT_CONNECTED",
                    message: "WebSocket not connected",
                    details: nil
                )
            )
            return
        }

        do {
            try await ws.send(.string(encodedMessage))
        } catch {
            failPendingRequest(messageId, error: error)
        }
    }

    private func failPendingRequest(_ messageId: String, error: Error) {
        guard let pending = pendingRequests.removeValue(forKey: messageId) else { return }
        pending.continuation.resume(throwing: error)
    }

    // MARK: - Private: Receive

    private func receiveLoop() async {
        guard let ws = task else { return }

        while !Task.isCancelled {
            do {
                let message = try await ws.receive()

                switch message {
                case .string(let text):
                    guard let data = text.data(using: .utf8) else { continue }
                    await handleMessage(data)
                case .data(let data):
                    await handleMessage(data)
                @unknown default:
                    break
                }
            } catch {
                if !Task.isCancelled {
                    await handleDisconnect()
                }
                return
            }
        }
    }

    private func handleMessage(_ data: Data) async {
        do {
            let envelope = try decoder.decode(MessageEnvelope.self, from: data)

            // Check for reply to pending request
            if let replyTo = envelope.replyTo, let pending = pendingRequests.removeValue(forKey: replyTo) {
                let result: Result<Data, Error>
                if envelope.type == MessageType.error {
                    do {
                        let errorPayload = try decoder.decode(
                            GatewayMessage<GatewayError>.self,
                            from: data
                        )
                        result = .failure(errorPayload.payload)
                    } catch {
                        result = .failure(GatewayError(
                            code: "PARSE_ERROR",
                            message: "Failed to decode gateway error payload: \(error.localizedDescription)",
                            details: nil
                        ))
                    }
                } else {
                    do {
                        // Extract the "payload" value directly from the raw JSON
                        // instead of round-tripping through AnyCodable encode,
                        // which can cause heap corruption with bridged Foundation types.
                        let payloadData = try Self.extractPayloadData(from: data)
                        result = .success(payloadData)
                    } catch {
                        result = .failure(GatewayError(
                            code: "PARSE_ERROR",
                            message: "Failed to decode gateway response payload: \(error.localizedDescription)",
                            details: nil
                        ))
                    }
                }

                switch result {
                case .success(let payloadData):
                    pending.continuation.resume(returning: payloadData)
                case .failure(let error):
                    pending.continuation.resume(throwing: error)
                }
                return
            }

            // Handle unsolicited messages
            switch envelope.type {
            case MessageType.authChallenge:
                let msg = try decoder.decode(GatewayMessage<AuthChallengePayload>.self, from: data)
                await handleAuthChallenge(msg.payload)

            case MessageType.authResult:
                let msg = try decoder.decode(GatewayMessage<AuthResultPayload>.self, from: data)
                if msg.payload.success {
                    // Challenge/response finished successfully.
                    setState(.connected)
                } else {
                    emit(.error(GatewayError(
                        code: "AUTH_FAILED",
                        message: msg.payload.reason ?? "Authentication failed",
                        details: nil
                    )))
                    disconnect()
                }

            case MessageType.turnEvent:
                let msg = try decoder.decode(GatewayMessage<TurnEvent>.self, from: data)
                emit(.turnEvent(msg.payload))

            case MessageType.turnStream:
                let msg = try decoder.decode(GatewayMessage<TurnStream>.self, from: data)
                emit(.turnStream(msg.payload))

            case MessageType.spaceState:
                let msg = try decoder.decode(GatewayMessage<SpaceState>.self, from: data)
                emit(.spaceState(msg.payload))

            case MessageType.spaceAgentUpdated:
                let msg = try decoder.decode(GatewayMessage<SpaceAgentUpdatedEvent>.self, from: data)
                emit(.spaceAgentUpdated(msg.payload))

            case MessageType.notification:
                let msg = try decoder.decode(GatewayMessage<GatewayNotification>.self, from: data)
                emit(.notification(msg.payload))

            case MessageType.appNavigate:
                let msg = try decoder.decode(GatewayMessage<AppNavigateEvent>.self, from: data)
                emit(.appNavigate(msg.payload))

            case MessageType.appConciergeActionRequest:
                let msg = try decoder.decode(GatewayMessage<AppConciergeActionRequestPayload>.self, from: data)
                emit(.conciergeActionRequest(msg.payload))

            case MessageType.capabilityInvokeAdapter:
                let msg = try decoder.decode(GatewayMessage<AdapterCapabilityInvokePayload>.self, from: data)
                emit(.capabilityInvoke(msg.payload))

            case MessageType.agentMessage:
                let msg = try decoder.decode(GatewayMessage<AgentMessage>.self, from: data)
                emit(.agentMessage(msg.payload))

            case MessageType.agentPoke:
                let msg = try decoder.decode(GatewayMessage<AgentPoke>.self, from: data)
                emit(.agentPoke(msg.payload))

            case MessageType.agentIdle:
                let msg = try decoder.decode(GatewayMessage<AgentIdle>.self, from: data)
                emit(.agentIdle(msg.payload))

            case MessageType.taskDependencyResolved:
                let msg = try decoder.decode(GatewayMessage<TaskDependencyResolved>.self, from: data)
                emit(.taskDependencyResolved(msg.payload))

            case MessageType.orchestratorEvent:
                let msg = try decoder.decode(GatewayMessage<OrchestratorEvent>.self, from: data)
                emit(.orchestratorEvent(msg.payload))

            case MessageType.speechEvent:
                let msg = try decoder.decode(GatewayMessage<SpeechSessionEvent>.self, from: data)
                emit(.speechEvent(msg.payload))

            case MessageType.conciergeCallEvent:
                let msg = try decoder.decode(GatewayMessage<ConciergeCallEvent>.self, from: data)
                emit(.conciergeCallEvent(msg.payload))

            case MessageType.error:
                let msg = try decoder.decode(GatewayMessage<GatewayError>.self, from: data)
                handleServerError(msg.payload)

            case MessageType.pong:
                break // Silently handle

            default:
                break
            }
        } catch {
            emit(.error(GatewayError(
                code: "PARSE_ERROR",
                message: "Failed to parse message: \(error.localizedDescription)",
                details: nil
            )))
        }
    }

    // MARK: - Private: Auth

    private func handleAuthChallenge(_ payload: AuthChallengePayload) async {
        guard let challenge = payload.challenge, let keyPair = options.authKeyPair else {
            emit(.error(GatewayError(
                code: "AUTH_NO_KEYPAIR",
                message: "Received auth challenge but no key pair configured",
                details: nil
            )))
            disconnect()
            return
        }

        setState(.authenticating)

        do {
            let signature = try signChallenge(challenge, with: keyPair)
            let effectiveDeviceProofSignature: String?
            if let provided = options.deviceProofSignature, !provided.isEmpty {
                effectiveDeviceProofSignature = provided
            } else if
                let deviceId = options.deviceId,
                !deviceId.isEmpty,
                let devicePublicKey = options.devicePublicKey,
                !devicePublicKey.isEmpty,
                devicePublicKey == keyPair.publicKeyBase64
            {
                effectiveDeviceProofSignature = signature
            } else {
                effectiveDeviceProofSignature = nil
            }
            let authPayload = AuthenticatePayload(
                publicKey: keyPair.publicKeyBase64,
                signature: signature,
                clientType: options.clientType,
                clientVersion: options.clientVersion,
                deviceId: options.deviceId,
                devicePublicKey: options.devicePublicKey,
                deviceProofSignature: effectiveDeviceProofSignature
            )
            _ = try await send(type: MessageType.authenticate, payload: authPayload)
        } catch {
            emit(.error(GatewayError(
                code: "AUTH_SIGN_FAILED",
                message: "Failed to sign challenge: \(error.localizedDescription)",
                details: nil
            )))
            disconnect()
        }
    }

    // MARK: - Private: Reconnect

    private func handleDisconnect() async {
        receiveTask?.cancel()
        receiveTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil

        // Reject all pending requests so continuations don't leak
        for (_, pending) in pendingRequests {
            pending.continuation.resume(throwing: GatewayError(
                code: "DISCONNECTED",
                message: "Connection lost",
                details: nil
            ))
        }
        pendingRequests.removeAll()

        guard options.reconnect, reconnectAllowed, reconnectAttempts < options.maxReconnectAttempts else {
            setState(.disconnected)
            return
        }

        reconnectAttempts += 1
        setState(.reconnecting(attempt: reconnectAttempts))

        let exponential = options.reconnectIntervalSec * pow(2, Double(reconnectAttempts - 1))
        let delay = min(exponential, options.maxReconnectDelaySec)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        do {
            try await connect()
        } catch {
            emit(.error(GatewayError(
                code: "RECONNECT_FAILED",
                message: "Reconnection attempt \(reconnectAttempts) failed: \(error.localizedDescription)",
                details: nil
            )))
            await handleDisconnect() // Retry
        }
    }

    // MARK: - Private: State & Events

    private func setState(_ newState: ConnectionState) {
        state = newState
        emit(.connectionStateChanged(newState))
    }

    func handleServerError(_ error: GatewayError) {
        if Self.errorDisablesReconnect(error.code) {
            reconnectAllowed = false
        }
        emit(.error(error))
    }

    static func errorDisablesReconnect(_ code: String) -> Bool {
        code.uppercased() == "SESSION_SUPERSEDED"
    }

    func factoryResetTimeoutNanosecondsForTesting() -> UInt64 {
        requestTimeoutNanoseconds(timeoutSec: max(options.requestTimeoutSec, 180))
    }

    func spaceResetTimeoutNanosecondsForTesting() -> UInt64 {
        requestTimeoutNanoseconds(timeoutSec: max(options.requestTimeoutSec, 180))
    }

    func awaitPendingRequestForTesting(messageId: String) async throws -> Data {
        try await withUnsafeThrowingContinuation { continuation in
            pendingRequests[messageId] = PendingRequest(continuation: continuation)
        }
    }

    func handleMessageForTesting(_ data: Data) async {
        await handleMessage(data)
    }

    func hasPendingRequestForTesting(_ messageId: String) -> Bool {
        pendingRequests[messageId] != nil
    }

    func pendingRequestCountForTesting() -> Int {
        pendingRequests.count
    }

    var reconnectAllowedForTesting: Bool { reconnectAllowed }

    private func emit(_ event: GatewayEvent) {
        eventContinuations.yield(event)
    }

    /// Extract the raw JSON bytes of the "payload" key from a gateway message,
    /// avoiding the AnyCodable decode→re-encode round-trip that can corrupt
    /// bridged Foundation objects.
    static func extractPayloadData(from data: Data) throws -> Data {
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let payload = obj?["payload"] else {
            return Data("null".utf8)
        }
        if payload is NSNull {
            return Data("null".utf8)
        }

        // JSONSerialization cannot encode top-level scalar values directly.
        // Wrap then slice to preserve scalar payloads like true/"ok"/1.
        let wrapped = try JSONSerialization.data(withJSONObject: ["payload": payload])
        let prefix = Data("{\"payload\":".utf8)
        guard wrapped.starts(with: prefix), wrapped.last == UInt8(ascii: "}") else {
            throw GatewayError(
                code: "PARSE_ERROR",
                message: "Malformed payload envelope",
                details: nil
            )
        }
        return wrapped.subdata(in: prefix.count ..< wrapped.count - 1)
    }
}

// MARK: - Empty Payload

private struct EmptyPayload: Codable {}

private struct ExecuteTurnAckCompat: Codable {
    let turnId: String
    let spaceId: String?
    let spaceUid: String?
    let eventType: String?
    let data: AnyCodable?
}

// MARK: - Event Continuations (Thread-safe)

/// Manages multiple AsyncStream continuations for broadcasting events.
private final class EventContinuations: @unchecked Sendable {
    private var continuations: [UUID: AsyncStream<GatewayEvent>.Continuation] = [:]
    private let lock = NSLock()

    func makeStream() -> AsyncStream<GatewayEvent> {
        let id = UUID()
        return AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            self.withLockVoid {
                self.continuations[id] = continuation
            }

            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.withLockVoid {
                    self.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    func yield(_ event: GatewayEvent) {
        let conts = withLock {
            Array(continuations.values)
        }

        for continuation in conts {
            continuation.yield(event)
        }
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    private func withLockVoid(_ body: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        body()
    }
}
