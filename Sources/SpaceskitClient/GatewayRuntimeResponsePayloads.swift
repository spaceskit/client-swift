// Protocol payload types for Spaceskit Client SDK.

import Foundation

// MARK: - Gateway Runtime Response Payloads

public struct AuthRegisterDeviceResponsePayload: Codable, Sendable {
    public let device: DeviceIdentity
    public let created: Bool
}

public struct AuthRotateDeviceKeyResponsePayload: Codable, Sendable {
    public let device: DeviceIdentity
}

public typealias AuthRevokeDeviceResponsePayload = AuthRevokeDeviceResult

public struct AuthListDevicesResponsePayload: Codable, Sendable {
    public let devices: [DeviceIdentity]
}

public struct AuthIssueHttpPrincipalTokenResponsePayload: Codable, Sendable {
    public let token: String
    public let tokenType: String
    public let principalId: String
    public let deviceId: String?
    public let issuedAt: String
    public let expiresAt: String
    public let ttlSeconds: Int
}

public struct GatewayDiscoverLocalAgentsResponsePayload: Codable, Sendable {
    public let agents: [DiscoveredLocalAgent]
}

public struct GatewayListProviderConfigsResponsePayload: Codable, Sendable {
    public let configs: [GatewayProviderRuntimeConfig]
}

public struct GatewayGetRuntimeDefaultsResponsePayload: Codable, Sendable {
    public let defaults: GatewayRuntimeDefaults
}

public struct GatewaySetRuntimeDefaultsResponsePayload: Codable, Sendable {
    public let defaults: GatewayRuntimeDefaults
    public let mainAgentState: GatewayMainAgentState
    public let conciergeAgentState: GatewayConciergeAgentState
}

public struct GatewayGetMainAgentResponsePayload: Codable, Sendable {
    public let state: GatewayMainAgentState
}

public struct GatewaySetMainAgentResponsePayload: Codable, Sendable {
    public let state: GatewayMainAgentState
}

public struct GatewayGetConciergeAgentResponsePayload: Codable, Sendable {
    public let state: GatewayConciergeAgentState
}

public struct GatewaySetConciergeAgentResponsePayload: Codable, Sendable {
    public let state: GatewayConciergeAgentState
}

public struct GatewayGetWorkspaceDefaultsResponsePayload: Codable, Sendable {
    public let defaults: GatewayWorkspaceDefaults
}

public struct GatewaySetWorkspaceDefaultsResponsePayload: Codable, Sendable {
    public let defaults: GatewayWorkspaceDefaults
}

public struct GatewayGetMemoryDefaultsResponsePayload: Codable, Sendable {
    public let defaults: GatewayMemoryDefaults
}

public struct GatewaySetMemoryDefaultsResponsePayload: Codable, Sendable {
    public let defaults: GatewayMemoryDefaults
}

public struct GatewayGetExternalConnectivityResponsePayload: Codable, Sendable {
    public let settings: GatewayExternalConnectivitySettings
    public let status: GatewayExternalConnectivityStatus
}

public struct GatewaySetExternalConnectivityResponsePayload: Codable, Sendable {
    public let settings: GatewayExternalConnectivitySettings
    public let status: GatewayExternalConnectivityStatus
}

public struct GatewayListAvailableModelsResponsePayload: Codable, Sendable {
    public let providers: [GatewayModelProviderCatalog]
    public let generatedAt: String
}

public struct GatewayListProviderCatalogsResponsePayload: Codable, Sendable {
    public let providers: [GatewayModelProviderCatalog]
    public let generatedAt: String
}

public struct GatewayListToolsResponsePayload: Codable, Sendable {
    public let tools: [GatewayTool]
}

public struct GatewayGetToolResponsePayload: Codable, Sendable {
    public let tool: GatewayTool?
}

public struct GatewayScaffoldToolResponsePayload: Codable, Sendable {
    public let manifest: GatewayRegisterToolPayload
    public let readme: String
}

public struct GatewayRegisterToolResponsePayload: Codable, Sendable {
    public let tool: GatewayTool
}

public struct GatewayRemoveToolResponsePayload: Codable, Sendable {
    public let toolId: String
    public let removed: Bool
}

public struct GatewaySetToolEnabledResponsePayload: Codable, Sendable {
    public let tools: [GatewayTool]
}

public struct GatewayInterconnectorBundle: Codable, Sendable {
    public let bundleId: String
    public let bundleDisplayName: String
    public let bundleDescription: String?
    public let availabilityStatus: GatewayInterconnectorAvailabilityStatus
    public let detected: Bool
    public let executablePath: String?
    public let installHint: String?
    public let toolIds: [String]
    public let toolCount: Int
    public let managedEnabled: Bool
    public let healthStatus: GatewayToolHealthStatus
    public let healthMessage: String?
    public let updatedAt: String
}

public struct GatewayListInterconnectorsResponsePayload: Codable, Sendable {
    public let interconnectors: [GatewayInterconnectorBundle]
    public let generatedAt: String
}

public struct GatewayRescanInterconnectorsResponsePayload: Codable, Sendable {
    public let interconnectors: [GatewayInterconnectorBundle]
    public let generatedAt: String
}

public typealias GatewayRescanJiraCliToolsResponsePayload = GatewayJiraCliRescanResult

public struct GatewayListToolApprovalGrantsResponsePayload: Codable, Sendable {
    public let grants: [GatewayToolApprovalGrant]
}

public typealias GatewayRevokeToolApprovalGrantResponsePayload = GatewayRevokeToolApprovalGrantResult

public struct GatewayGetProviderTelemetryResponsePayload: Codable, Sendable {
    public let telemetry: [ProviderTelemetry]
    public let generatedAt: String
}

public struct GatewayGetLocalUsageTelemetryResponsePayload: Codable, Sendable {
    public let telemetry: [LocalProviderUsageTelemetry]
    public let generatedAt: String
}

public struct GatewayGetProviderSettingsResponsePayload: Codable, Sendable {
    public let settings: GatewayProviderRuntimeConfig
}

public struct GatewaySetProviderConfigResponsePayload: Codable, Sendable {
    public let config: GatewayProviderRuntimeConfig
}

public struct GatewayUpdateProviderSettingsResponsePayload: Codable, Sendable {
    public let settings: GatewayProviderRuntimeConfig
}

public struct GatewayRemoveProviderConfigResponsePayload: Codable, Sendable {
    public let providerId: String
}

public struct GatewayFactoryResetResponsePayload: Codable, Sendable {
    public let gatewayId: String
    public let gatewayUuid: String?
    public let resetAt: String
    public let tablesCleared: Int
    public let rowsDeleted: UInt64
}

public typealias SpaceResetResponsePayload = SpaceResetResult

public struct SpaceGetEffectiveToolsResponsePayload: Codable, Sendable {
    public let matrix: EffectiveToolMatrix
}

public struct SpaceGetEffectiveToolAccessResponsePayload: Codable, Sendable {
    public let access: EffectiveToolAccess
}

public struct SpaceGetToolPolicyResponsePayload: Codable, Sendable {
    public let policy: ToolAccessPolicy
}

public struct SpaceUpdateToolPolicyResponsePayload: Codable, Sendable {
    public let policy: ToolAccessPolicy
}

public struct SpaceGetConnectorPolicyResponsePayload: Codable, Sendable {
    public let policy: SpaceConnectorPolicy
}

public struct SpaceUpdateConnectorPolicyResponsePayload: Codable, Sendable {
    public let policy: SpaceConnectorPolicy
}

public struct GatewayGetToolPolicyResponsePayload: Codable, Sendable {
    public let policy: ToolAccessPolicy
}

public struct GatewayUpdateToolPolicyResponsePayload: Codable, Sendable {
    public let policy: ToolAccessPolicy
}

public struct GatewayListSafetyProfilesResponsePayload: Codable, Sendable {
    public let profiles: [SafetyProfileDefinition]
}

public struct GatewayProvisionLocalProfileResponsePayload: Codable, Sendable {
    public let profileId: String
    public let profileName: String
    public let created: Bool
    public let providerId: String
    public let model: String
    public let agentId: String?
    public let assignmentCreated: Bool?
}

public typealias GatewayPutSecretRefResponsePayload = GatewayPutSecretRefResult

public struct GatewayListSecretRefsResponsePayload: Codable, Sendable {
    public let secretRefs: [GatewaySecretRef]
}

public typealias GatewayDeleteSecretRefResponsePayload = GatewayDeleteSecretRefResult
