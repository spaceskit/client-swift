// Gateway connector, policy, usage, and skill GatewayClient APIs.

import Foundation

extension GatewayClient {
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
}
