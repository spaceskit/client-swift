// Gateway tool, provider-settings, telemetry, and integration GatewayClient APIs.

import Foundation

extension GatewayClient {
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
        return try decoder.decode(GatewayRevokeToolApprovalGrantResult.self, from: data)
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
        providerId: String? = nil,
        providerIds: [String]? = nil
    ) async throws -> [LocalProviderUsageTelemetry] {
        let payload = GatewayGetLocalUsageTelemetryPayload(
            apiVersion: apiVersion,
            providerId: providerId,
            providerIds: providerIds
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
}
