// Gateway runtime, model, tool, provider, and integration GatewayClient APIs.

import Foundation

extension GatewayClient {
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

    public func getRuntimeDefaults(apiVersion: String? = nil) async throws -> GatewayRuntimeDefaults {
        let payload = GatewayGetRuntimeDefaultsPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.gatewayGetRuntimeDefaults, payload: payload)
        let response = try decoder.decode(GatewayGetRuntimeDefaultsResponsePayload.self, from: data)
        return response.defaults
    }

    public func setRuntimeDefaults(
        apiVersion: String? = nil,
        main: GatewayRuntimeDefaultSelection? = nil,
        concierge: GatewayRuntimeDefaultSelection? = nil
    ) async throws -> GatewaySetRuntimeDefaultsResult {
        let payload = GatewaySetRuntimeDefaultsPayload(
            apiVersion: apiVersion,
            main: main,
            concierge: concierge
        )
        return try await setRuntimeDefaults(payload)
    }

    public func setRuntimeDefaults(
        _ payload: GatewaySetRuntimeDefaultsPayload
    ) async throws -> GatewaySetRuntimeDefaultsResult {
        let data = try await sendAndWait(type: MessageType.gatewaySetRuntimeDefaults, payload: payload)
        let response = try decoder.decode(GatewaySetRuntimeDefaultsResponsePayload.self, from: data)
        return GatewaySetRuntimeDefaultsResult(
            defaults: response.defaults,
            mainAgentState: response.mainAgentState,
            conciergeAgentState: response.conciergeAgentState
        )
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
}
