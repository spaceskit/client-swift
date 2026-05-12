// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Tool Policies

public struct ToolDenyReason: Codable, Sendable {
    public let code: String
    public let message: String
}

public struct ToolAccessRule: Codable, Sendable {
    public let selectorKind: String
    public let selectorId: String
    public let state: String

    public init(selectorKind: String, selectorId: String, state: String) {
        self.selectorKind = selectorKind
        self.selectorId = selectorId
        self.state = state
    }
}

public struct DangerousCapabilityRule: Codable, Sendable {
    public let capabilityId: String
    public let state: String

    public init(capabilityId: String, state: String) {
        self.capabilityId = capabilityId
        self.state = state
    }
}

public struct ToolAccessPolicy: Codable, Sendable {
    public let scopeType: String
    public let scopeId: String
    public let rules: [ToolAccessRule]
    public let dangerousCapabilities: [DangerousCapabilityRule]
    public let guestAccessPreset: String?
    public let policyVersion: String
    public let updatedBy: String?
    public let updatedAt: String?

    public init(
        scopeType: String,
        scopeId: String,
        rules: [ToolAccessRule],
        dangerousCapabilities: [DangerousCapabilityRule],
        guestAccessPreset: String? = nil,
        policyVersion: String,
        updatedBy: String? = nil,
        updatedAt: String? = nil
    ) {
        self.scopeType = scopeType
        self.scopeId = scopeId
        self.rules = rules
        self.dangerousCapabilities = dangerousCapabilities
        self.guestAccessPreset = guestAccessPreset
        self.policyVersion = policyVersion
        self.updatedBy = updatedBy
        self.updatedAt = updatedAt
    }
}

public struct SafetyProfileDefinition: Codable, Sendable {
    public let profileId: String
    public let displayName: String
    public let description: String
    public let rules: [ToolAccessRule]
    public let dangerousCapabilities: [DangerousCapabilityRule]
    public let updatedAt: String

    public init(
        profileId: String,
        displayName: String,
        description: String,
        rules: [ToolAccessRule],
        dangerousCapabilities: [DangerousCapabilityRule],
        updatedAt: String
    ) {
        self.profileId = profileId
        self.displayName = displayName
        self.description = description
        self.rules = rules
        self.dangerousCapabilities = dangerousCapabilities
        self.updatedAt = updatedAt
    }
}

public struct EffectiveToolOperation: Codable, Sendable {
    public let operationId: String
    public let capability: String
    public let operation: String
    public let providerIds: [String]
    public let allowed: Bool
    public let denyReasons: [ToolDenyReason]
}

public struct EffectiveToolMatrix: Codable, Sendable {
    public let spaceId: String
    public let principalId: String?
    public let deviceId: String?
    public let agentId: String?
    public let policyVersion: String
    public let operations: [EffectiveToolOperation]
    public let generatedAt: String
}

public struct EffectiveToolAccessOperation: Codable, Sendable {
    public let operationId: String
    public let capability: String
    public let operation: String
    public let providerIds: [String]
    public let selectors: [String]
    public let allowed: Bool
    public let denialReasonCode: String?
    public let denialReason: String?
    public let requiredDangerousCapability: String?
    public let escalationAllowed: Bool?
}

public struct EffectiveDangerousCapability: Codable, Sendable {
    public let capabilityId: String
    public let enabled: Bool
    public let source: String
}

public struct EffectiveToolAccess: Codable, Sendable {
    public let spaceId: String
    public let agentId: String?
    public let policyVersion: String
    public let safetyProfileId: String?
    public let operations: [EffectiveToolAccessOperation]
    public let dangerousCapabilities: [EffectiveDangerousCapability]
    public let generatedAt: String
}
