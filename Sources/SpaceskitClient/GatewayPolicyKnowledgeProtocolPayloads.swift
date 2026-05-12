// Protocol payload types for Spaceskit Client SDK.

import Foundation

// MARK: - Gateway Policy, Knowledge, and Usage Payloads

public struct UsageGetSnapshotPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct UsageGetSnapshotResponsePayload: Codable, Sendable {
    public let snapshot: UsageSnapshot
}

public struct GatewayGetPolicyPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewayGetPolicyResponsePayload: Codable, Sendable {
    public let policy: GatewayPolicy
}

public struct GatewayUpdatePolicyPayload: Codable, Sendable {
    public let apiVersion: String?
    public let allowedCapabilityTypes: [String]?
    public let deniedCapabilityTypes: [String]?
    public let allowedSkillIds: [String]?
    public let deniedSkillIds: [String]?
    public let globalFlags: [String: AnyCodable]?

    public init(
        apiVersion: String? = nil,
        allowedCapabilityTypes: [String]? = nil,
        deniedCapabilityTypes: [String]? = nil,
        allowedSkillIds: [String]? = nil,
        deniedSkillIds: [String]? = nil,
        globalFlags: [String: AnyCodable]? = nil
    ) {
        self.apiVersion = apiVersion
        self.allowedCapabilityTypes = allowedCapabilityTypes
        self.deniedCapabilityTypes = deniedCapabilityTypes
        self.allowedSkillIds = allowedSkillIds
        self.deniedSkillIds = deniedSkillIds
        self.globalFlags = globalFlags
    }
}

public struct GatewayUpdatePolicyResponsePayload: Codable, Sendable {
    public let policy: GatewayPolicy
}

public struct GatewayListKnowledgeBaseEntriesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String?
    public let query: String?
    public let tags: [String]?
    public let kinds: [GatewayKnowledgeBaseEntryKind]?
    public let limit: Int?

    public init(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        query: String? = nil,
        tags: [String]? = nil,
        kinds: [GatewayKnowledgeBaseEntryKind]? = nil,
        limit: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.query = query
        self.tags = tags
        self.kinds = kinds
        self.limit = limit
    }
}

public struct GatewayListKnowledgeBaseEntriesResponsePayload: Codable, Sendable {
    public let entries: [GatewayKnowledgeBaseEntry]
}

public struct GatewayUpsertKnowledgeBaseEntryPayload: Codable, Sendable {
    public let apiVersion: String?
    public let entryId: String?
    public let name: String
    public let kind: GatewayKnowledgeBaseEntryKind
    public let uri: String
    public let description: String?
    public let tags: [String]?
    public let scopeType: GatewayKnowledgeBaseScopeType
    public let spaceId: String?

    public init(
        apiVersion: String? = nil,
        entryId: String? = nil,
        name: String,
        kind: GatewayKnowledgeBaseEntryKind,
        uri: String,
        description: String? = nil,
        tags: [String]? = nil,
        scopeType: GatewayKnowledgeBaseScopeType,
        spaceId: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.entryId = entryId
        self.name = name
        self.kind = kind
        self.uri = uri
        self.description = description
        self.tags = tags
        self.scopeType = scopeType
        self.spaceId = spaceId
    }
}

public struct GatewayUpsertKnowledgeBaseEntryResponsePayload: Codable, Sendable {
    public let entry: GatewayKnowledgeBaseEntry
}

public struct GatewayDeleteKnowledgeBaseEntryPayload: Codable, Sendable {
    public let apiVersion: String?
    public let entryId: String

    public init(apiVersion: String? = nil, entryId: String) {
        self.apiVersion = apiVersion
        self.entryId = entryId
    }
}

public struct GatewayDeleteKnowledgeBaseEntryResponsePayload: Codable, Sendable {
    public let entryId: String
    public let deleted: Bool
}
