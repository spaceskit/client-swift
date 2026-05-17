// SpaceLifecycleProtocolPayloads.swift - Space lifecycle and assignment payloads.

import Foundation

public struct SpaceCreatePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String?
    public let workspaceRoot: String?
    public let resourceId: String
    public let spaceType: String?
    public let name: String
    public let goal: String?
    public let conversationTopology: String?
    public let promptPackId: String?
    public let turnModel: String?
    public let templateId: String?
    public let templateRevision: Int?
    public let capabilities: [String]?
    public let capabilityOverrides: [String: String]?
    public let visibility: String?
    public let turnModelConfig: [String: AnyCodable]?
    public let maxTurns: Int?
    public let thinkingCapturePolicy: ThinkingCapturePolicy?
    public let memoryPolicy: SpaceMemoryPolicy?
    public let moderatorProfileId: String?
    public let initialAgents: [SpaceCreateInitialAgentPayload]?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String? = nil,
        workspaceRoot: String? = nil,
        resourceId: String,
        spaceType: String? = nil,
        name: String,
        goal: String? = nil,
        conversationTopology: String? = nil,
        promptPackId: String? = nil,
        turnModel: String? = nil,
        templateId: String? = nil,
        templateRevision: Int? = nil,
        capabilities: [String]? = nil,
        capabilityOverrides: [String: String]? = nil,
        visibility: String? = nil,
        turnModelConfig: [String: Any]? = nil,
        maxTurns: Int? = nil,
        thinkingCapturePolicy: ThinkingCapturePolicy? = nil,
        memoryPolicy: SpaceMemoryPolicy? = nil,
        moderatorProfileId: String? = nil,
        initialAgents: [SpaceCreateInitialAgentPayload]? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.workspaceRoot = workspaceRoot
        self.resourceId = resourceId
        self.spaceType = spaceType
        self.name = name
        self.goal = goal
        self.conversationTopology = conversationTopology
        self.promptPackId = promptPackId
        self.turnModel = turnModel
        self.templateId = templateId
        self.templateRevision = templateRevision
        self.capabilities = capabilities
        self.capabilityOverrides = capabilityOverrides
        self.visibility = visibility
        self.turnModelConfig = turnModelConfig?.mapValues { AnyCodable($0) }
        self.maxTurns = maxTurns
        self.thinkingCapturePolicy = thinkingCapturePolicy
        self.memoryPolicy = memoryPolicy
        self.moderatorProfileId = moderatorProfileId
        self.initialAgents = initialAgents
    }
}

public struct SpaceGetPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceUpdateMetadataPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let name: String?
    public let goal: String?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        name: String? = nil,
        goal: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.name = name
        self.goal = goal
    }
}

public struct SpaceSetThinkingCapturePolicyPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let thinkingCapturePolicy: ThinkingCapturePolicy

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        thinkingCapturePolicy: ThinkingCapturePolicy
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.thinkingCapturePolicy = thinkingCapturePolicy
    }
}

public struct SpaceGetMemoryPolicyPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceSetMemoryPolicyPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let memoryPolicy: SpaceMemoryPolicy

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        memoryPolicy: SpaceMemoryPolicy
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.memoryPolicy = memoryPolicy
    }
}

public struct SpaceEndIncognitoSessionPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceListPayload: Codable, Sendable {
    public let apiVersion: String?
    public let statuses: [String]?
    public let resourceId: String?
    public let limit: Int?

    public init(
        apiVersion: String? = nil,
        statuses: [String]? = nil,
        resourceId: String? = nil,
        limit: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.statuses = statuses
        self.resourceId = resourceId
        self.limit = limit
    }
}

public struct SpaceArchivePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, idempotencyKey: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
    }
}

public struct SpaceDeletePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, idempotencyKey: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
    }
}

public struct SpaceAddAgentPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let agentId: String
    public let agentDefinitionId: String?
    public let profileId: String?
    public let safetyProfileId: String?
    public let toolPolicyOverride: ToolAccessPolicy?
    public let spawnContext: String?
    public let contextOverrides: [String: AnyCodable]?
    public let role: String?
    public let turnOrder: Int?
    public let isPrimary: Bool?

    private enum CodingKeys: String, CodingKey {
        case apiVersion
        case idempotencyKey
        case spaceId
        case agentId
        case agentDefinitionId
        case profileId
        case safetyProfileId
        case toolPolicyOverride
        case spawnContext
        case contextOverrides
        case role
        case turnOrder
        case isPrimary
    }

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        agentId: String,
        agentDefinitionId: String? = nil,
        profileId: String? = nil,
        safetyProfileId: String? = nil,
        toolPolicyOverride: ToolAccessPolicy? = nil,
        spawnContext: String? = nil,
        contextOverrides: [String: Any]? = nil,
        role: String? = nil,
        turnOrder: Int? = nil,
        isPrimary: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.agentId = agentId
        self.agentDefinitionId = agentDefinitionId ?? profileId
        self.profileId = profileId ?? agentDefinitionId
        self.safetyProfileId = safetyProfileId
        self.toolPolicyOverride = toolPolicyOverride
        self.spawnContext = spawnContext
        self.contextOverrides = contextOverrides?.mapValues { AnyCodable($0) }
        self.role = role
        self.turnOrder = turnOrder
        self.isPrimary = isPrimary
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(apiVersion, forKey: .apiVersion)
        try container.encodeIfPresent(idempotencyKey, forKey: .idempotencyKey)
        try container.encode(spaceId, forKey: .spaceId)
        try container.encode(agentId, forKey: .agentId)
        try container.encodeIfPresent(agentDefinitionId ?? profileId, forKey: .agentDefinitionId)
        try container.encodeIfPresent(profileId ?? agentDefinitionId, forKey: .profileId)
        try container.encodeIfPresent(safetyProfileId, forKey: .safetyProfileId)
        try container.encodeIfPresent(toolPolicyOverride, forKey: .toolPolicyOverride)
        try container.encodeIfPresent(spawnContext, forKey: .spawnContext)
        try container.encodeIfPresent(contextOverrides, forKey: .contextOverrides)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(turnOrder, forKey: .turnOrder)
        try container.encodeIfPresent(isPrimary, forKey: .isPrimary)
    }
}

public struct SpaceRemoveAgentPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let agentId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        agentId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.agentId = agentId
    }
}

public struct SpaceUpdateAgentAssignmentPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let agentId: String
    public let agentDefinitionId: String?
    public let profileId: String?
    public let safetyProfileId: String?
    public let toolPolicyOverride: ToolAccessPolicy?
    public let spawnContext: String?
    public let contextOverrides: [String: AnyCodable]?
    public let role: String?
    public let turnOrder: Int?
    public let isPrimary: Bool?
    public let resetSession: Bool?

    private enum CodingKeys: String, CodingKey {
        case apiVersion
        case idempotencyKey
        case spaceId
        case agentId
        case agentDefinitionId
        case profileId
        case safetyProfileId
        case toolPolicyOverride
        case spawnContext
        case contextOverrides
        case role
        case turnOrder
        case isPrimary
        case resetSession
    }

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        agentId: String,
        agentDefinitionId: String? = nil,
        profileId: String? = nil,
        safetyProfileId: String? = nil,
        toolPolicyOverride: ToolAccessPolicy? = nil,
        spawnContext: String? = nil,
        contextOverrides: [String: Any]? = nil,
        role: String? = nil,
        turnOrder: Int? = nil,
        isPrimary: Bool? = nil,
        resetSession: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.agentId = agentId
        self.agentDefinitionId = agentDefinitionId ?? profileId
        self.profileId = profileId ?? agentDefinitionId
        self.safetyProfileId = safetyProfileId
        self.toolPolicyOverride = toolPolicyOverride
        self.spawnContext = spawnContext
        self.contextOverrides = contextOverrides?.mapValues { AnyCodable($0) }
        self.role = role
        self.turnOrder = turnOrder
        self.isPrimary = isPrimary
        self.resetSession = resetSession
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(apiVersion, forKey: .apiVersion)
        try container.encodeIfPresent(idempotencyKey, forKey: .idempotencyKey)
        try container.encode(spaceId, forKey: .spaceId)
        try container.encode(agentId, forKey: .agentId)
        try container.encodeIfPresent(agentDefinitionId ?? profileId, forKey: .agentDefinitionId)
        try container.encodeIfPresent(profileId ?? agentDefinitionId, forKey: .profileId)
        try container.encodeIfPresent(safetyProfileId, forKey: .safetyProfileId)
        try container.encodeIfPresent(toolPolicyOverride, forKey: .toolPolicyOverride)
        try container.encodeIfPresent(spawnContext, forKey: .spawnContext)
        try container.encodeIfPresent(contextOverrides, forKey: .contextOverrides)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(turnOrder, forKey: .turnOrder)
        try container.encodeIfPresent(isPrimary, forKey: .isPrimary)
        try container.encodeIfPresent(resetSession, forKey: .resetSession)
    }
}

public struct SpaceSetOrchestratorPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let agentDefinitionId: String?
    public let spaceId: String
    public let profileId: String?

    private enum CodingKeys: String, CodingKey {
        case apiVersion
        case idempotencyKey
        case agentDefinitionId
        case spaceId
        case profileId
    }

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        agentDefinitionId: String? = nil,
        profileId: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.agentDefinitionId = agentDefinitionId ?? profileId
        self.spaceId = spaceId
        self.profileId = profileId ?? agentDefinitionId
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(apiVersion, forKey: .apiVersion)
        try container.encodeIfPresent(idempotencyKey, forKey: .idempotencyKey)
        try container.encodeIfPresent(agentDefinitionId ?? profileId, forKey: .agentDefinitionId)
        try container.encode(spaceId, forKey: .spaceId)
        try container.encodeIfPresent(profileId ?? agentDefinitionId, forKey: .profileId)
    }
}
