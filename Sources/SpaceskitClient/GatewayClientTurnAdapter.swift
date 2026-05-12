// Turn, subscription, and adapter GatewayClient APIs.

import Foundation

extension GatewayClient {
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
}
