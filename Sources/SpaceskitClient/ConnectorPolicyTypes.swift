// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Connector Policies

public enum SpaceConnectorPolicySourceKind: String, Codable, Sendable {
    case builtinIntegration = "builtin_integration"
    case cliBundle = "cli_bundle"
    case connectorFamily = "connector_family"
    case connectorInstance = "connector_instance"
    case mcpServer = "mcp_server"
}

public enum SpaceConnectorPolicyEntryState: String, Codable, Sendable {
    case enabled
    case disabled
}

public enum SpaceConnectorPolicyMode: String, Codable, Sendable {
    case allEnabled = "all_enabled"
    case custom
}

public struct SpaceConnectorPolicyEntry: Codable, Sendable {
    public let sourceKind: SpaceConnectorPolicySourceKind
    public let sourceId: String
    public let state: SpaceConnectorPolicyEntryState

    public init(
        sourceKind: SpaceConnectorPolicySourceKind,
        sourceId: String,
        state: SpaceConnectorPolicyEntryState
    ) {
        self.sourceKind = sourceKind
        self.sourceId = sourceId
        self.state = state
    }
}

public struct SpaceConnectorPolicy: Codable, Sendable {
    public let spaceId: String
    public let mode: SpaceConnectorPolicyMode
    public let entries: [SpaceConnectorPolicyEntry]
    public let policyVersion: String
    public let updatedBy: String?
    public let updatedAt: String?
}

public enum GatewayConnectorKind: String, Codable, Sendable {
    case channel
    case capability
    case hybrid
}

public enum GatewayConnectorRuntime: String, Codable, Sendable {
    case adapter
    case connector
    case builtin
}

public enum GatewayConnectorTrustClass: String, Codable, Sendable {
    case embeddedSafe = "embedded_safe"
    case externalOnly = "external_only"
}

public enum GatewayConnectorInstanceStatus: String, Codable, Sendable {
    case active
    case paused
    case error
}

public enum GatewayConnectorBindingType: String, Codable, Sendable {
    case inboundRoute = "inbound_route"
    case outboundAction = "outbound_action"
    case capabilityExport = "capability_export"
}

public enum GatewayConnectorBindingTarget: String, Codable, Sendable {
    case mainOrchestrator = "main_orchestrator"
    case spaceOrchestrator = "space_orchestrator"
}

public enum GatewayConnectorAction: String, Codable, Sendable {
    case notify
    case sendMessage = "send_message"
    case sendMedia = "send_media"
    case sendReaction = "send_reaction"
}

public enum GatewayConnectorPolicyScopeType: String, Codable, Sendable {
    case global
    case family
    case instance
}

public enum GatewayConnectorInboundRouteKind: String, Codable, Sendable {
    case binding
    case mainFallback = "main_fallback"
}

public struct GatewayConnectorFamily: Codable, Sendable {
    public let familyId: String
    public let displayName: String
    public let kind: GatewayConnectorKind
    public let runtime: GatewayConnectorRuntime
    public let trustClass: GatewayConnectorTrustClass
    public let embeddedEnabled: Bool
    public let capabilityTypes: [String]
    public let features: [String: AnyCodable]
    public let createdAt: String
    public let updatedAt: String
}

public struct GatewayConnector: Codable, Sendable {
    public let connectorId: String
    public let familyId: String
    public let displayName: String
    public let accountFingerprintHash: String
    public let labelSlug: String
    public let status: GatewayConnectorInstanceStatus
    public let metadata: [String: AnyCodable]
    public let createdAt: String
    public let updatedAt: String
}

public struct GatewayConnectorBinding: Codable, Sendable {
    public let bindingId: String
    public let connectorId: String
    public let bindingType: GatewayConnectorBindingType
    public let selector: [String: AnyCodable]
    public let targetType: GatewayConnectorBindingTarget
    public let targetSpaceId: String?
    public let allowedActions: [GatewayConnectorAction]
    public let capabilityTypes: [String]
    public let priority: Int
    public let enabled: Bool
    public let createdAt: String
    public let updatedAt: String
}

public struct GatewayConnectorPolicy: Codable, Sendable {
    public let scopeType: GatewayConnectorPolicyScopeType
    public let scopeId: String
    public let requestsPerMinute: Int
    public let burst: Int
    public let disabled: Bool
    public let disableReason: String?
    public let disabledUntil: String?
    public let updatedBy: String
    public let updatedAt: String
}

public struct GatewayConnectorInboundRoute: Codable, Sendable {
    public let route: GatewayConnectorInboundRouteKind
    public let targetType: GatewayConnectorBindingTarget
    public let targetSpaceId: String?
    public let bindingId: String?
    public let matchedScore: Double?
}

public struct GatewayTestConnectorResult: Codable, Sendable {
    public let ok: Bool
    public let reason: String?
    public let connector: GatewayConnector?
    public let inboundRoute: GatewayConnectorInboundRoute?
    public let policy: GatewayConnectorPolicy?
}

public enum GatewayCapabilityGrantLevel: String, Codable, Sendable {
    case read
    case write
    case execute
}

public struct GatewayCapabilityGrant: Codable, Sendable {
    public let principalId: String
    public let deviceId: String
    public let capabilityId: String
    public let level: GatewayCapabilityGrantLevel
    public let source: String
    public let reason: String
    public let grantedBy: String
    public let grantedAt: String
    public let expiresAt: String?
    public let revokedAt: String?
    public let updatedAt: String
}

public struct GatewayRevokeCapabilityResult: Codable, Sendable {
    public let revoked: Bool
    public let capabilityId: String
    public let principalId: String
    public let deviceId: String
    public let grant: GatewayCapabilityGrant?
}
