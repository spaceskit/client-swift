// Orchestrator, bootstrap, inter-agent, and ping GatewayClient APIs.

import Foundation

extension GatewayClient {
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
}
