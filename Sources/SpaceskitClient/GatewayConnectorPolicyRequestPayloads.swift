// Protocol payload types for Spaceskit Client SDK.

import Foundation

// MARK: - Connector, Tool Policy, and Capability Requests

public struct GatewayListConnectorFamiliesPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewayListConnectorsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let familyId: String?

    public init(apiVersion: String? = nil, familyId: String? = nil) {
        self.apiVersion = apiVersion
        self.familyId = familyId
    }
}

public struct GatewayConnectorSecretRefPayload: Codable, Sendable {
    public let key: String
    public let ref: String
    public let backend: String?

    public init(key: String, ref: String, backend: String? = nil) {
        self.key = key
        self.ref = ref
        self.backend = backend
    }
}

public struct GatewayUpsertConnectorPayload: Codable, Sendable {
    public let apiVersion: String?
    public let connectorId: String?
    public let familyId: String
    public let displayName: String
    public let accountFingerprint: String
    public let label: String
    public let status: GatewayConnectorInstanceStatus?
    public let metadata: [String: AnyCodable]?
    public let secretRefs: [GatewayConnectorSecretRefPayload]?

    public init(
        apiVersion: String? = nil,
        connectorId: String? = nil,
        familyId: String,
        displayName: String,
        accountFingerprint: String,
        label: String,
        status: GatewayConnectorInstanceStatus? = nil,
        metadata: [String: Any]? = nil,
        secretRefs: [GatewayConnectorSecretRefPayload]? = nil
    ) {
        self.apiVersion = apiVersion
        self.connectorId = connectorId
        self.familyId = familyId
        self.displayName = displayName
        self.accountFingerprint = accountFingerprint
        self.label = label
        self.status = status
        self.metadata = metadata?.mapValues { AnyCodable($0) }
        self.secretRefs = secretRefs
    }
}

public struct GatewayRemoveConnectorPayload: Codable, Sendable {
    public let apiVersion: String?
    public let connectorId: String

    public init(apiVersion: String? = nil, connectorId: String) {
        self.apiVersion = apiVersion
        self.connectorId = connectorId
    }
}

public struct ConnectorSubmitInboundEventPayload: Codable, Sendable {
    public let apiVersion: String?
    public let connectorId: String
    public let eventType: String
    public let selector: [String: AnyCodable]?
    public let snapshot: [String: AnyCodable]?
    public let input: String?

    public init(
        apiVersion: String? = nil,
        connectorId: String,
        eventType: String,
        selector: [String: Any]? = nil,
        snapshot: [String: Any]? = nil,
        input: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.connectorId = connectorId
        self.eventType = eventType
        self.selector = selector?.mapValues { AnyCodable($0) }
        self.snapshot = snapshot?.mapValues { AnyCodable($0) }
        self.input = input
    }
}

public struct GatewayListConnectorBindingsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let connectorId: String?

    public init(apiVersion: String? = nil, connectorId: String? = nil) {
        self.apiVersion = apiVersion
        self.connectorId = connectorId
    }
}

public struct GatewayUpsertConnectorBindingPayload: Codable, Sendable {
    public let apiVersion: String?
    public let bindingId: String?
    public let connectorId: String
    public let bindingType: GatewayConnectorBindingType
    public let selector: [String: AnyCodable]?
    public let targetType: GatewayConnectorBindingTarget
    public let targetSpaceId: String?
    public let allowedActions: [GatewayConnectorAction]?
    public let capabilityTypes: [String]?
    public let priority: Int?
    public let enabled: Bool?

    public init(
        apiVersion: String? = nil,
        bindingId: String? = nil,
        connectorId: String,
        bindingType: GatewayConnectorBindingType,
        selector: [String: Any]? = nil,
        targetType: GatewayConnectorBindingTarget,
        targetSpaceId: String? = nil,
        allowedActions: [GatewayConnectorAction]? = nil,
        capabilityTypes: [String]? = nil,
        priority: Int? = nil,
        enabled: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.bindingId = bindingId
        self.connectorId = connectorId
        self.bindingType = bindingType
        self.selector = selector?.mapValues { AnyCodable($0) }
        self.targetType = targetType
        self.targetSpaceId = targetSpaceId
        self.allowedActions = allowedActions
        self.capabilityTypes = capabilityTypes
        self.priority = priority
        self.enabled = enabled
    }
}

public struct GatewayRemoveConnectorBindingPayload: Codable, Sendable {
    public let apiVersion: String?
    public let bindingId: String

    public init(apiVersion: String? = nil, bindingId: String) {
        self.apiVersion = apiVersion
        self.bindingId = bindingId
    }
}

public struct GatewayGetConnectorPolicyPayload: Codable, Sendable {
    public let apiVersion: String?
    public let scopeType: GatewayConnectorPolicyScopeType
    public let scopeId: String

    public init(
        apiVersion: String? = nil,
        scopeType: GatewayConnectorPolicyScopeType,
        scopeId: String
    ) {
        self.apiVersion = apiVersion
        self.scopeType = scopeType
        self.scopeId = scopeId
    }
}

public struct GatewayUpdateConnectorPolicyPayload: Codable, Sendable {
    public let apiVersion: String?
    public let scopeType: GatewayConnectorPolicyScopeType
    public let scopeId: String
    public let requestsPerMinute: Int?
    public let burst: Int?
    public let disabled: Bool?
    public let disableReason: String?
    public let disabledUntil: String?
    public let updatedBy: String

    public init(
        apiVersion: String? = nil,
        scopeType: GatewayConnectorPolicyScopeType,
        scopeId: String,
        requestsPerMinute: Int? = nil,
        burst: Int? = nil,
        disabled: Bool? = nil,
        disableReason: String? = nil,
        disabledUntil: String? = nil,
        updatedBy: String
    ) {
        self.apiVersion = apiVersion
        self.scopeType = scopeType
        self.scopeId = scopeId
        self.requestsPerMinute = requestsPerMinute
        self.burst = burst
        self.disabled = disabled
        self.disableReason = disableReason
        self.disabledUntil = disabledUntil
        self.updatedBy = updatedBy
    }
}

public struct GatewayGetToolPolicyPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewayUpdateToolPolicyPayload: Codable, Sendable {
    public let apiVersion: String?
    public let rules: [ToolAccessRule]?
    public let dangerousCapabilities: [DangerousCapabilityRule]?
    public let updatedBy: String?

    public init(
        apiVersion: String? = nil,
        rules: [ToolAccessRule]? = nil,
        dangerousCapabilities: [DangerousCapabilityRule]? = nil,
        updatedBy: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.rules = rules
        self.dangerousCapabilities = dangerousCapabilities
        self.updatedBy = updatedBy
    }
}

public struct GatewayListSafetyProfilesPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct SpaceGetEffectiveToolsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let agentId: String?
    public let accessMode: String?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        agentId: String? = nil,
        accessMode: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.agentId = agentId
        self.accessMode = accessMode
    }
}

public struct SpaceGetEffectiveToolAccessPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let agentId: String?
    public let accessMode: String?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        agentId: String? = nil,
        accessMode: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.agentId = agentId
        self.accessMode = accessMode
    }
}

public struct SpaceGetToolPolicyPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(
        apiVersion: String? = nil,
        spaceId: String
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceUpdateToolPolicyPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let rules: [ToolAccessRule]?
    public let dangerousCapabilities: [DangerousCapabilityRule]?
    public let guestAccessPreset: String?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        rules: [ToolAccessRule]? = nil,
        dangerousCapabilities: [DangerousCapabilityRule]? = nil,
        guestAccessPreset: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.rules = rules
        self.dangerousCapabilities = dangerousCapabilities
        self.guestAccessPreset = guestAccessPreset
    }
}

public struct SpaceGetConnectorPolicyPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(
        apiVersion: String? = nil,
        spaceId: String
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceUpdateConnectorPolicyPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let mode: SpaceConnectorPolicyMode
    public let entries: [SpaceConnectorPolicyEntry]?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        mode: SpaceConnectorPolicyMode,
        entries: [SpaceConnectorPolicyEntry]? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.mode = mode
        self.entries = entries
    }
}

public struct GatewayTestConnectorPayload: Codable, Sendable {
    public let apiVersion: String?
    public let connectorId: String

    public init(apiVersion: String? = nil, connectorId: String) {
        self.apiVersion = apiVersion
        self.connectorId = connectorId
    }
}

public struct GatewayListCapabilityGrantsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let principalId: String?
    public let deviceId: String?
    public let includeRevoked: Bool?
    public let includeExpired: Bool?

    public init(
        apiVersion: String? = nil,
        principalId: String? = nil,
        deviceId: String? = nil,
        includeRevoked: Bool? = nil,
        includeExpired: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.principalId = principalId
        self.deviceId = deviceId
        self.includeRevoked = includeRevoked
        self.includeExpired = includeExpired
    }
}

public struct GatewayGrantCapabilityPayload: Codable, Sendable {
    public let apiVersion: String?
    public let principalId: String?
    public let deviceId: String?
    public let capabilityId: String
    public let reason: String?
    public let expiresAt: String?

    public init(
        apiVersion: String? = nil,
        principalId: String? = nil,
        deviceId: String? = nil,
        capabilityId: String,
        reason: String? = nil,
        expiresAt: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.principalId = principalId
        self.deviceId = deviceId
        self.capabilityId = capabilityId
        self.reason = reason
        self.expiresAt = expiresAt
    }
}

public struct GatewayRevokeCapabilityPayload: Codable, Sendable {
    public let apiVersion: String?
    public let principalId: String?
    public let deviceId: String?
    public let capabilityId: String
    public let reason: String?

    public init(
        apiVersion: String? = nil,
        principalId: String? = nil,
        deviceId: String? = nil,
        capabilityId: String,
        reason: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.principalId = principalId
        self.deviceId = deviceId
        self.capabilityId = capabilityId
        self.reason = reason
    }
}
