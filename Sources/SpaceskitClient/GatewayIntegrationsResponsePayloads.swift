// Protocol payload types for Spaceskit Client SDK.

import Foundation

// MARK: - Gateway Integrations Response Payloads

public enum GatewayBuiltinMcpAdminAuthMode: String, Codable, Sendable, Equatable {
    case strict
    case principalToken = "principal_token"
    case unavailable
}

public enum GatewayInterconnectorAvailabilityStatus: String, Codable, Sendable {
    case active
    case degraded
    case inactive
}

public enum GatewayIntegrationGroupId: String, Codable, Sendable {
    case builtInIntegrations = "built_in_integrations"
    case builtInMcpAdmin = "built_in_mcp_admin"
    case mcpServers = "mcp_servers"
    case cliTools = "cli_tools"
    case externalConnectors = "external_connectors"
}

public enum GatewayIntegrationEntryKind: String, Codable, Sendable {
    case builtInIntegration = "built_in_integration"
    case builtInMcpAdmin = "built_in_mcp_admin"
    case mcpServer = "mcp_server"
    case cliTool = "cli_tool"
    case connectorFamily = "connector_family"
    case connector = "connector"
}

public enum GatewayIntegrationBadgeTone: String, Codable, Sendable {
    case green
    case blue
    case orange
    case red
    case gray
}

public struct GatewayIntegrationBadge: Codable, Sendable {
    public let text: String
    public let tone: GatewayIntegrationBadgeTone?

    public init(
        text: String,
        tone: GatewayIntegrationBadgeTone? = nil
    ) {
        self.text = text
        self.tone = tone
    }
}

public struct GatewayBuiltinIntegrationEntry: Codable, Sendable {
    public let integrationId: String
    public let displayName: String
    public let description: String?
    public let enabled: Bool
    public let capabilityTypes: [String]
    public let managementSummary: String?
    public let runtimeAvailable: Bool?
    public let runtimeStatus: String?
    public let runtimeStatusMessage: String?
    public let providerIds: [String]?
}

public struct GatewayBuiltinMcpAdminRuntimeState: Codable, Sendable, Equatable {
    public let endpointPath: String
    public let effectiveEnabled: Bool
    public let bootstrapDefaultEnabled: Bool
    public let authMode: GatewayBuiltinMcpAdminAuthMode
    public let tokenIssuerAvailable: Bool
    public let defaultTargetSpaceId: String

    public init(
        endpointPath: String,
        effectiveEnabled: Bool,
        bootstrapDefaultEnabled: Bool,
        authMode: GatewayBuiltinMcpAdminAuthMode,
        tokenIssuerAvailable: Bool,
        defaultTargetSpaceId: String
    ) {
        self.endpointPath = endpointPath
        self.effectiveEnabled = effectiveEnabled
        self.bootstrapDefaultEnabled = bootstrapDefaultEnabled
        self.authMode = authMode
        self.tokenIssuerAvailable = tokenIssuerAvailable
        self.defaultTargetSpaceId = defaultTargetSpaceId
    }
}

public struct GatewayBuiltinMcpAdminEntry: Codable, Sendable {
    public let enabled: Bool
    public let allowTargetSpaceOverride: Bool
    public let allowedTools: [String]
    public let runtimeState: GatewayBuiltinMcpAdminRuntimeState?
}

public struct GatewayIntegrationCliToolEntry: Codable, Sendable {
    public let tool: GatewayTool
    public let activeApprovalGrantCount: Int
}

public struct GatewayIntegrationMcpServerEntry: Codable, Sendable {
    public let spaceId: String
    public let spaceName: String
    public let endpoint: SpaceMcpEndpoint
}

public struct GatewayIntegrationConnectorFamilyEntry: Codable, Sendable {
    public let family: GatewayConnectorFamily
    public let configuredConnectorCount: Int
    public let policy: GatewayConnectorPolicy?
}

public struct GatewayIntegrationConnectorEntry: Codable, Sendable {
    public let connector: GatewayConnector
    public let family: GatewayConnectorFamily
    public let bindings: [GatewayConnectorBinding]
    public let policy: GatewayConnectorPolicy?
}

public struct GatewayIntegrationEntry: Codable, Sendable {
    public let entryId: String
    public let kind: GatewayIntegrationEntryKind
    public let title: String
    public let subtitle: String?
    public let badges: [GatewayIntegrationBadge]
    public let builtinIntegration: GatewayBuiltinIntegrationEntry?
    public let builtinMcpAdmin: GatewayBuiltinMcpAdminEntry?
    public let mcpServer: GatewayIntegrationMcpServerEntry?
    public let cliTool: GatewayIntegrationCliToolEntry?
    public let connectorFamily: GatewayIntegrationConnectorFamilyEntry?
    public let connector: GatewayIntegrationConnectorEntry?
}

public struct GatewayIntegrationGroup: Codable, Sendable {
    public let groupId: GatewayIntegrationGroupId
    public let title: String
    public let summary: String?
    public let entries: [GatewayIntegrationEntry]
}

public struct GatewayIntegrationsSnapshot: Codable, Sendable {
    public let groups: [GatewayIntegrationGroup]
    public let supportedInterconnectors: [GatewayInterconnectorBundle]?
    public let connectorFamilyPolicies: [String: GatewayConnectorPolicy]?
    public let connectorPolicies: [String: GatewayConnectorPolicy]?
    public let generatedAt: String

    public init(
        groups: [GatewayIntegrationGroup],
        supportedInterconnectors: [GatewayInterconnectorBundle]? = nil,
        connectorFamilyPolicies: [String: GatewayConnectorPolicy]? = nil,
        connectorPolicies: [String: GatewayConnectorPolicy]? = nil,
        generatedAt: String
    ) {
        self.groups = groups
        self.supportedInterconnectors = supportedInterconnectors
        self.connectorFamilyPolicies = connectorFamilyPolicies
        self.connectorPolicies = connectorPolicies
        self.generatedAt = generatedAt
    }
}

public struct GatewayGetIntegrationsSnapshotResponsePayload: Codable, Sendable {
    public let snapshot: GatewayIntegrationsSnapshot
}

public struct GatewayListConnectorFamiliesResponsePayload: Codable, Sendable {
    public let families: [GatewayConnectorFamily]
}

public struct GatewayListConnectorsResponsePayload: Codable, Sendable {
    public let connectors: [GatewayConnector]
}

public struct GatewayUpsertConnectorResponsePayload: Codable, Sendable {
    public let connector: GatewayConnector
}

public struct GatewayRemoveConnectorResponsePayload: Codable, Sendable {
    public let connectorId: String
    public let removed: Bool
}

public struct ConnectorInboundRouteResult: Codable, Sendable {
    public let route: String
    public let targetType: String
    public let targetSpaceId: String?
    public let bindingId: String?
    public let matchedScore: Int?
}

public struct ConnectorInboundEventResultPayload: Codable, Sendable {
    public let ok: Bool
    public let route: ConnectorInboundRouteResult?
    public let turnId: String?
    public let directives: [String: AnyCodable]
}

public struct GatewayListConnectorBindingsResponsePayload: Codable, Sendable {
    public let bindings: [GatewayConnectorBinding]
}

public struct GatewayUpsertConnectorBindingResponsePayload: Codable, Sendable {
    public let binding: GatewayConnectorBinding
}

public struct GatewayRemoveConnectorBindingResponsePayload: Codable, Sendable {
    public let bindingId: String
    public let removed: Bool
}

public struct GatewayGetConnectorPolicyResponsePayload: Codable, Sendable {
    public let policy: GatewayConnectorPolicy
}

public struct GatewayUpdateConnectorPolicyResponsePayload: Codable, Sendable {
    public let policy: GatewayConnectorPolicy
}

public struct GatewayTestConnectorResponsePayload: Codable, Sendable {
    public let ok: Bool
    public let reason: String?
    public let connector: GatewayConnector?
    public let inboundRoute: GatewayConnectorInboundRoute?
    public let policy: GatewayConnectorPolicy?
}

public struct GatewayListCapabilityGrantsResponsePayload: Codable, Sendable {
    public let grants: [GatewayCapabilityGrant]
}

public struct GatewayGrantCapabilityResponsePayload: Codable, Sendable {
    public let grant: GatewayCapabilityGrant
}

public struct GatewayRevokeCapabilityResponsePayload: Codable, Sendable {
    public let revoked: Bool
    public let capabilityId: String
    public let principalId: String
    public let deviceId: String
    public let grant: GatewayCapabilityGrant?
}
