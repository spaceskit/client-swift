// Protocol.swift — handwritten WebSocket transport types for Spaceskit.
// Canonical cross-process contracts live in /proto; this file keeps the
// remaining first-party Swift transport aligned without shim-generated code.

import Foundation

// MARK: - Message Envelope

/// JSON envelope for all gateway protocol messages.
public struct GatewayMessage<T: Codable>: Codable {
    public let type: String
    public let id: String
    public var replyTo: String?
    public let ts: String
    public let payload: T

    public init(type: String, id: String, replyTo: String? = nil, payload: T) {
        self.type = type
        self.id = id
        self.replyTo = replyTo
        self.ts = ISO8601DateFormatter().string(from: Date())
        self.payload = payload
    }
}

// MARK: - Client → Gateway Payloads

public struct AuthenticatePayload: Codable, Sendable {
    public let publicKey: String
    public let signature: String
    public let clientType: String
    public let clientVersion: String
    public let deviceId: String?
    public let devicePublicKey: String?
    public let deviceProofSignature: String?
}

public struct ExecuteTurnPayload: Codable, Sendable {
    public let spaceUid: String
    public let input: String
    public let targetAgentId: String?
    public let targetAgentIds: [String]?
    public let replyToTurnId: String?
    public let conversationTopology: ConversationTopology?
    public let mode: String?
    public let effort: String?
    public let accessMode: String?

    public init(
        spaceUid: String,
        input: String,
        targetAgentId: String? = nil,
        targetAgentIds: [String]? = nil,
        replyToTurnId: String? = nil,
        conversationTopology: ConversationTopology? = nil,
        mode: String? = nil,
        effort: String? = nil,
        accessMode: String? = nil
    ) {
        self.spaceUid = spaceUid
        self.input = input
        self.targetAgentId = targetAgentId
        self.targetAgentIds = targetAgentIds
        self.replyToTurnId = replyToTurnId
        self.conversationTopology = conversationTopology
        self.mode = mode
        self.effort = effort
        self.accessMode = accessMode
    }

    public init(_ options: ExecuteTurnOptions) {
        self.init(
            spaceUid: options.spaceUid,
            input: options.input,
            targetAgentId: options.targetAgentId,
            targetAgentIds: options.targetAgentIds,
            replyToTurnId: options.replyToTurnId,
            conversationTopology: options.conversationTopology,
            mode: options.mode,
            effort: options.effort,
            accessMode: options.accessMode
        )
    }
}

public struct ResumeFeedbackPayload: Codable, Sendable {
    public let spaceUid: String
    public let turnId: String
    public let response: String
    public let revision: String?
    public let approvalGrant: ApprovalGrantPayload?

    public init(
        spaceUid: String,
        turnId: String,
        response: FeedbackResponse,
        revision: String? = nil,
        approvalGrant: ApprovalGrantPayload? = nil
    ) {
        self.spaceUid = spaceUid
        self.turnId = turnId
        self.response = response.rawValue
        self.revision = revision
        self.approvalGrant = approvalGrant
    }
}

public struct ApprovalGrantPayload: Codable, Sendable {
    public let mode: GatewayToolApprovalGrantMode
    public let ttlSeconds: Int?

    public init(
        mode: GatewayToolApprovalGrantMode,
        ttlSeconds: Int? = nil
    ) {
        self.mode = mode
        self.ttlSeconds = ttlSeconds
    }
}

public struct SubscribePayload: Codable, Sendable {
    public let spaceUids: [String]

    public init(spaceUids: [String]) {
        self.spaceUids = spaceUids
    }
}

public struct SubscribeDeniedSpace: Codable, Sendable {
    public let spaceUid: String
    public let reason: String

    public init(spaceUid: String, reason: String) {
        self.spaceUid = spaceUid
        self.reason = reason
    }
}

public struct SubscribeResponsePayload: Codable, Sendable {
    public let subscribedSpaceUids: [String]
    public let denied: [SubscribeDeniedSpace]

    public init(subscribedSpaceUids: [String], denied: [SubscribeDeniedSpace]) {
        self.subscribedSpaceUids = subscribedSpaceUids
        self.denied = denied
    }
}

public struct CapabilityInvokePayload: Codable, Sendable {
    public let capability: String
    public let method: String
    public let params: [String: AnyCodable]
    public let targetProvider: String?

    public init(capability: String, method: String, params: [String: Any], targetProvider: String? = nil) {
        self.capability = capability
        self.method = method
        self.params = params.mapValues { AnyCodable($0) }
        self.targetProvider = targetProvider
    }
}

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
    public let securityScope: [String: AnyCodable]?
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
        case securityScope
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
        securityScope: [String: Any]? = nil,
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
        self.securityScope = securityScope?.mapValues { AnyCodable($0) }
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
        try container.encodeIfPresent(securityScope, forKey: .securityScope)
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
    public let securityScope: [String: AnyCodable]?
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
        case securityScope
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
        securityScope: [String: Any]? = nil,
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
        self.securityScope = securityScope?.mapValues { AnyCodable($0) }
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
        try container.encodeIfPresent(securityScope, forKey: .securityScope)
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

public struct SpaceListAgentAssignmentsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceGetMcpEndpointPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceSetMcpEndpointPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let transport: SpaceMcpTransport
    public let endpoint: String
    public let args: [String]?
    public let secretRef: String?
    public let enabled: Bool?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        transport: SpaceMcpTransport,
        endpoint: String,
        args: [String]? = nil,
        secretRef: String? = nil,
        enabled: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.transport = transport
        self.endpoint = endpoint
        self.args = args
        self.secretRef = secretRef
        self.enabled = enabled
    }
}

public struct SpaceClearMcpEndpointPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceAddSkillPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let skillId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        skillId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.skillId = skillId
    }
}

public struct SpaceRemoveSkillPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let skillId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        skillId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.skillId = skillId
    }
}

public struct SpaceListSkillsPayload: Codable, Sendable {
  public let apiVersion: String?
  public let spaceId: String

  public init(apiVersion: String? = nil, spaceId: String) {
    self.apiVersion = apiVersion
    self.spaceId = spaceId
  }
}

public struct SpaceGetWorkspacePayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceSetWorkspacePayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let workspaceRoot: String?

    public init(apiVersion: String? = nil, spaceId: String, workspaceRoot: String? = nil) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.workspaceRoot = workspaceRoot
    }
}

public struct SpaceOpenWorkspacePayload: Codable, Sendable {
    public let apiVersion: String?
    public let workspaceRoot: String

    public init(apiVersion: String? = nil, workspaceRoot: String) {
        self.apiVersion = apiVersion
        self.workspaceRoot = workspaceRoot
    }
}

public struct SpaceAddResourcePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let resourceId: String?
    public let spaceId: String
    public let uri: String
    public let type: String
    public let label: String?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        resourceId: String? = nil,
        spaceId: String,
        uri: String,
        type: String,
        label: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.resourceId = resourceId
        self.spaceId = spaceId
        self.uri = uri
        self.type = type
        self.label = label
    }
}

public struct SpaceRemoveResourcePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let resourceId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        resourceId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.resourceId = resourceId
    }
}

public struct SpaceListResourcesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceListTurnsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String?
    public let spaceUid: String?
    public let limit: Int
    public let offset: Int
    public let lastSeenTurnId: String?

    public init(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        spaceUid: String? = nil,
        limit: Int,
        offset: Int,
        lastSeenTurnId: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.limit = limit
        self.offset = offset
        self.lastSeenTurnId = lastSeenTurnId
    }
}

public struct SpaceListOrchestrationJournalPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String?
    public let spaceUid: String?
    public let turnId: String?
    public let limit: Int
    public let offset: Int

    public init(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        spaceUid: String? = nil,
        turnId: String? = nil,
        limit: Int,
        offset: Int
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.turnId = turnId
        self.limit = limit
        self.offset = offset
    }
}

public struct IdentityListAgentDefinitionsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let includeArchived: Bool?

    public init(apiVersion: String? = nil, includeArchived: Bool? = nil) {
        self.apiVersion = apiVersion
        self.includeArchived = includeArchived
    }
}

public struct IdentityGetAgentDefinitionPayload: Codable, Sendable {
    public let apiVersion: String?
    public let agentDefinitionId: String

    public init(apiVersion: String? = nil, agentDefinitionId: String) {
        self.apiVersion = apiVersion
        self.agentDefinitionId = agentDefinitionId
    }
}

public struct IdentityCreateAgentDefinitionPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let agentDefinitionId: String?
    public let personaId: String?
    public let name: String
    public let description: String?
    public let instructions: String?
    public let defaultSkillIds: [String]?
    public let providerHint: String?
    public let modelHint: String?
    public let modelConfig: ProfileModelConfig?
    public let isDefault: Bool?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        agentDefinitionId: String? = nil,
        personaId: String? = nil,
        name: String,
        description: String? = nil,
        instructions: String? = nil,
        defaultSkillIds: [String]? = nil,
        providerHint: String? = nil,
        modelHint: String? = nil,
        modelConfig: ProfileModelConfig? = nil,
        isDefault: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.agentDefinitionId = agentDefinitionId
        self.personaId = personaId
        self.name = name
        self.description = description
        self.instructions = instructions
        self.defaultSkillIds = defaultSkillIds
        self.providerHint = providerHint
        self.modelHint = modelHint
        self.modelConfig = modelConfig
        self.isDefault = isDefault
    }
}

public struct IdentityUpdateAgentDefinitionPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let agentDefinitionId: String
    public let personaId: String?
    public let name: String?
    public let description: String?
    public let instructions: String?
    public let defaultSkillIds: [String]?
    public let providerHint: String?
    public let modelHint: String?
    public let modelConfig: ProfileModelConfig?
    public let isDefault: Bool?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        agentDefinitionId: String,
        personaId: String? = nil,
        name: String? = nil,
        description: String? = nil,
        instructions: String? = nil,
        defaultSkillIds: [String]? = nil,
        providerHint: String? = nil,
        modelHint: String? = nil,
        modelConfig: ProfileModelConfig? = nil,
        isDefault: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.agentDefinitionId = agentDefinitionId
        self.personaId = personaId
        self.name = name
        self.description = description
        self.instructions = instructions
        self.defaultSkillIds = defaultSkillIds
        self.providerHint = providerHint
        self.modelHint = modelHint
        self.modelConfig = modelConfig
        self.isDefault = isDefault
    }
}

public struct IdentityArchiveAgentDefinitionPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let agentDefinitionId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        agentDefinitionId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.agentDefinitionId = agentDefinitionId
    }
}

public struct IdentityListPersonasPayload: Codable, Sendable {
    public let apiVersion: String?
    public let includeArchived: Bool?

    public init(apiVersion: String? = nil, includeArchived: Bool? = nil) {
        self.apiVersion = apiVersion
        self.includeArchived = includeArchived
    }
}

public struct IdentityGetPersonaPayload: Codable, Sendable {
    public let apiVersion: String?
    public let personaId: String

    public init(apiVersion: String? = nil, personaId: String) {
        self.apiVersion = apiVersion
        self.personaId = personaId
    }
}

public struct IdentityCreatePersonaPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let personaId: String?
    public let name: String
    public let description: String?
    public let tone: String?
    public let style: String?
    public let emotionalLayer: String?
    public let constraints: [String]?
    public let instructions: String?
    public let isDefault: Bool?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        personaId: String? = nil,
        name: String,
        description: String? = nil,
        tone: String? = nil,
        style: String? = nil,
        emotionalLayer: String? = nil,
        constraints: [String]? = nil,
        instructions: String? = nil,
        isDefault: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.personaId = personaId
        self.name = name
        self.description = description
        self.tone = tone
        self.style = style
        self.emotionalLayer = emotionalLayer
        self.constraints = constraints
        self.instructions = instructions
        self.isDefault = isDefault
    }
}

public struct IdentityUpdatePersonaPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let personaId: String
    public let name: String?
    public let description: String?
    public let tone: String?
    public let style: String?
    public let emotionalLayer: String?
    public let constraints: [String]?
    public let instructions: String?
    public let isDefault: Bool?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        personaId: String,
        name: String? = nil,
        description: String? = nil,
        tone: String? = nil,
        style: String? = nil,
        emotionalLayer: String? = nil,
        constraints: [String]? = nil,
        instructions: String? = nil,
        isDefault: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.personaId = personaId
        self.name = name
        self.description = description
        self.tone = tone
        self.style = style
        self.emotionalLayer = emotionalLayer
        self.constraints = constraints
        self.instructions = instructions
        self.isDefault = isDefault
    }
}

public struct IdentityArchivePersonaPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let personaId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        personaId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.personaId = personaId
    }
}

public struct IdentityPreviewCompiledInstructionsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let agentDefinitionId: String
    public let workspaceContext: String?

    public init(
        apiVersion: String? = nil,
        agentDefinitionId: String,
        workspaceContext: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.agentDefinitionId = agentDefinitionId
        self.workspaceContext = workspaceContext
    }
}

public struct IdentityPreviewRuntimeSystemPromptPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let agentId: String?
    public let profileId: String?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        agentId: String? = nil,
        profileId: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.agentId = agentId
        self.profileId = profileId
    }
}

// MARK: - System Prompt Matrix Preview

public struct IdentityPreviewSystemPromptMatrixPayload: Codable, Sendable {
    public let apiVersion: String?
    public let agentDefinitionId: String
    public let spaceId: String?
    public let agentId: String?

    public init(
        apiVersion: String? = nil,
        agentDefinitionId: String,
        spaceId: String? = nil,
        agentId: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.agentDefinitionId = agentDefinitionId
        self.spaceId = spaceId
        self.agentId = agentId
    }
}

public enum PromptBudgetClass: String, Codable, Sendable, CaseIterable {
    case full
    case compact
    case minimal
    case cli
}

public struct SystemPromptVariant: Codable, Sendable, Identifiable {
    public var id: String { budgetClass.rawValue }
    public let budgetClass: PromptBudgetClass
    public let label: String
    public let tokenEstimate: Int
    public let sections: [CompiledInstructionSection]
    public let compiledText: String
}

public struct SystemPromptMatrix: Codable, Sendable {
    public let agentDefinitionId: String
    public let personaId: String?
    public let generatedAt: String
    public let variants: [SystemPromptVariant]
}

public struct IdentityPreviewSystemPromptMatrixResponsePayload: Codable, Sendable {
    public let matrix: SystemPromptMatrix
}

public struct SpacePreviewTemplatePayload: Codable, Sendable {
    public let apiVersion: String?
    public let templateId: String
    public let resourceId: String?
    public let name: String?
    public let goal: String?

    public init(
        apiVersion: String? = nil,
        templateId: String,
        resourceId: String? = nil,
        name: String? = nil,
        goal: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.templateId = templateId
        self.resourceId = resourceId
        self.name = name
        self.goal = goal
    }
}

public struct SpaceCreateFromTemplatePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let templateId: String
    public let spaceId: String?
    public let resourceId: String
    public let name: String?
    public let goal: String?
    public let workspaceRoot: String?
    public let visibility: String?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        templateId: String,
        spaceId: String? = nil,
        resourceId: String,
        name: String? = nil,
        goal: String? = nil,
        workspaceRoot: String? = nil,
        visibility: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.templateId = templateId
        self.spaceId = spaceId
        self.resourceId = resourceId
        self.name = name
        self.goal = goal
        self.workspaceRoot = workspaceRoot
        self.visibility = visibility
    }
}

public struct SpaceSaveTemplatePayload: Codable, Sendable {
    public let apiVersion: String?
    public let templateId: String?
    public let title: String
    public let description: String?
    public let communicationMode: String?
    public let conversationTopology: String?
    public let promptPackId: String?
    public let baseAgents: [TemplateAgentDefinition]?
    public let agentPresetIds: [String]?
    public let sourceSpaceId: String?
    public let tags: [String]?

    public init(
        apiVersion: String? = nil,
        templateId: String? = nil,
        title: String,
        description: String? = nil,
        communicationMode: String? = nil,
        conversationTopology: String? = nil,
        promptPackId: String? = nil,
        baseAgents: [TemplateAgentDefinition]? = nil,
        agentPresetIds: [String]? = nil,
        sourceSpaceId: String? = nil,
        tags: [String]? = nil
    ) {
        self.apiVersion = apiVersion
        self.templateId = templateId
        self.title = title
        self.description = description
        self.communicationMode = communicationMode
        self.conversationTopology = conversationTopology
        self.promptPackId = promptPackId
        self.baseAgents = baseAgents
        self.agentPresetIds = agentPresetIds
        self.sourceSpaceId = sourceSpaceId
        self.tags = tags
    }
}

public struct SpaceTemplateListPayload: Codable, Sendable {
    public let apiVersion: String?
    public let includeArchived: Bool?
    public let includeSystem: Bool?

    public init(apiVersion: String? = nil, includeArchived: Bool? = nil, includeSystem: Bool? = nil) {
        self.apiVersion = apiVersion
        self.includeArchived = includeArchived
        self.includeSystem = includeSystem
    }
}

public struct SpaceTemplateGetPayload: Codable, Sendable {
    public let apiVersion: String?
    public let templateId: String

    public init(apiVersion: String? = nil, templateId: String) {
        self.apiVersion = apiVersion
        self.templateId = templateId
    }
}

public struct SpaceTemplatePreviewPayload: Codable, Sendable {
    public let apiVersion: String?
    public let templateId: String
    public let resourceId: String?
    public let name: String?
    public let goal: String?

    public init(
        apiVersion: String? = nil,
        templateId: String,
        resourceId: String? = nil,
        name: String? = nil,
        goal: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.templateId = templateId
        self.resourceId = resourceId
        self.name = name
        self.goal = goal
    }
}

public struct SpaceTemplateCreateSpacePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let templateId: String
    public let spaceId: String?
    public let resourceId: String
    public let name: String?
    public let goal: String?
    public let visibility: String?
    public let workspaceRoot: String?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        templateId: String,
        spaceId: String? = nil,
        resourceId: String,
        name: String? = nil,
        goal: String? = nil,
        visibility: String? = nil,
        workspaceRoot: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.templateId = templateId
        self.spaceId = spaceId
        self.resourceId = resourceId
        self.name = name
        self.goal = goal
        self.visibility = visibility
        self.workspaceRoot = workspaceRoot
    }
}

public struct SpaceTemplateSavePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let templateId: String?
    public let name: String
    public let description: String?
    public let communicationMode: String?
    public let conversationTopology: String?
    public let promptPackId: String?
    public let baseAgents: [TemplateAgentDefinition]?
    public let sourceSpaceId: String?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        templateId: String? = nil,
        name: String,
        description: String? = nil,
        communicationMode: String? = nil,
        conversationTopology: String? = nil,
        promptPackId: String? = nil,
        baseAgents: [TemplateAgentDefinition]? = nil,
        sourceSpaceId: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.templateId = templateId
        self.name = name
        self.description = description
        self.communicationMode = communicationMode
        self.conversationTopology = conversationTopology
        self.promptPackId = promptPackId
        self.baseAgents = baseAgents
        self.sourceSpaceId = sourceSpaceId
    }
}

public struct SpaceTemplateArchivePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let templateId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        templateId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.templateId = templateId
    }
}

// MARK: - Gateway Skill Catalog

public struct GatewaySkillListPayload: Codable, Sendable {
    public let apiVersion: String?
    public let query: String?
    public let tags: [String]?
    public let status: String?
    public let limit: Int?

    public init(
        apiVersion: String? = nil,
        query: String? = nil,
        tags: [String]? = nil,
        status: String? = nil,
        limit: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.query = query
        self.tags = tags
        self.status = status
        self.limit = limit
    }
}

public struct GatewaySkillEntry: Codable, Sendable, Identifiable {
    public let skillId: String
    public let name: String
    public let description: String?
    public let contentMarkdown: String?
    public let sourceRef: String?
    public let tags: [String]
    public let status: String
    public let createdAt: String
    public let updatedAt: String

    public var id: String { skillId }
}

public struct GatewaySkillListResponsePayload: Codable, Sendable {
    public let skills: [GatewaySkillEntry]
}

// MARK: - Library (Legacy)

public struct LibraryListEntriesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let query: String?
    public let tags: [String]?
    public let status: LibraryEntryStatus?
    public let sourceKinds: [LibrarySourceKind]?
    public let includeArchived: Bool?
    public let includeContent: Bool?
    public let limit: Int?

    public init(
        apiVersion: String? = nil,
        query: String? = nil,
        tags: [String]? = nil,
        status: LibraryEntryStatus? = nil,
        sourceKinds: [LibrarySourceKind]? = nil,
        includeArchived: Bool? = nil,
        includeContent: Bool? = nil,
        limit: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.query = query
        self.tags = tags
        self.status = status
        self.sourceKinds = sourceKinds
        self.includeArchived = includeArchived
        self.includeContent = includeContent
        self.limit = limit
    }
}

public struct LibraryGetEntryPayload: Codable, Sendable {
    public let apiVersion: String?
    public let entryId: String
    public let includeContent: Bool?

    public init(apiVersion: String? = nil, entryId: String, includeContent: Bool? = nil) {
        self.apiVersion = apiVersion
        self.entryId = entryId
        self.includeContent = includeContent
    }
}

public struct LibrarySaveSkillPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let entryId: String?
    public let skillId: String?
    public let name: String
    public let description: String?
    public let contentMarkdown: String
    public let tags: [String]?
    public let sourceKind: LibrarySourceKind?
    public let sourceRef: String?
    public let status: LibraryEntryStatus?
    public let enabled: Bool?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        entryId: String? = nil,
        skillId: String? = nil,
        name: String,
        description: String? = nil,
        contentMarkdown: String,
        tags: [String]? = nil,
        sourceKind: LibrarySourceKind? = nil,
        sourceRef: String? = nil,
        status: LibraryEntryStatus? = nil,
        enabled: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.entryId = entryId
        self.skillId = skillId
        self.name = name
        self.description = description
        self.contentMarkdown = contentMarkdown
        self.tags = tags
        self.sourceKind = sourceKind
        self.sourceRef = sourceRef
        self.status = status
        self.enabled = enabled
    }
}

public struct LibraryImportEntryPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let entryId: String
    public let skillId: String?
    public let name: String?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        entryId: String,
        skillId: String? = nil,
        name: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.entryId = entryId
        self.skillId = skillId
        self.name = name
    }
}

public struct LibraryArchiveEntryPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let entryId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        entryId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.entryId = entryId
    }
}

public struct LibrarySetEntryEnabledPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let entryId: String
    public let enabled: Bool

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        entryId: String,
        enabled: Bool
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.entryId = entryId
        self.enabled = enabled
    }
}

public struct LibraryDeleteEntryPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let entryId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        entryId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.entryId = entryId
    }
}

public struct LibraryScanEntriesPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct LibraryListSkillDraftsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct LibraryGetSkillDraftPayload: Codable, Sendable {
    public let apiVersion: String?
    public let draftId: String

    public init(apiVersion: String? = nil, draftId: String) {
        self.apiVersion = apiVersion
        self.draftId = draftId
    }
}

public struct LibraryCreateSkillDraftPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let draftId: String?
    public let name: String?
    public let description: String?
    public let requestPrompt: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        draftId: String? = nil,
        name: String? = nil,
        description: String? = nil,
        requestPrompt: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.draftId = draftId
        self.name = name
        self.description = description
        self.requestPrompt = requestPrompt
    }
}

public struct LibraryDeleteSkillDraftPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let draftId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        draftId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.draftId = draftId
    }
}

public struct AuthRegisterDevicePayload: Codable, Sendable {
    public let apiVersion: String?
    public let deviceId: String
    public let publicKey: String
    public let platform: String?

    public init(
        apiVersion: String? = nil,
        deviceId: String,
        publicKey: String,
        platform: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.deviceId = deviceId
        self.publicKey = publicKey
        self.platform = platform
    }
}

public struct AuthRotateDeviceKeyPayload: Codable, Sendable {
    public let apiVersion: String?
    public let deviceId: String
    public let nextPublicKey: String
    public let platform: String?

    public init(
        apiVersion: String? = nil,
        deviceId: String,
        nextPublicKey: String,
        platform: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.deviceId = deviceId
        self.nextPublicKey = nextPublicKey
        self.platform = platform
    }
}

public struct AuthRevokeDevicePayload: Codable, Sendable {
    public let apiVersion: String?
    public let deviceId: String

    public init(apiVersion: String? = nil, deviceId: String) {
        self.apiVersion = apiVersion
        self.deviceId = deviceId
    }
}

public struct AuthListDevicesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let includeRevoked: Bool?

    public init(apiVersion: String? = nil, includeRevoked: Bool? = nil) {
        self.apiVersion = apiVersion
        self.includeRevoked = includeRevoked
    }
}

public struct AuthIssueHttpPrincipalTokenPayload: Codable, Sendable {
    public let apiVersion: String?
    public let ttlSeconds: Int?

    public init(apiVersion: String? = nil, ttlSeconds: Int? = nil) {
        self.apiVersion = apiVersion
        self.ttlSeconds = ttlSeconds
    }
}

public struct GatewayDiscoverLocalAgentsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewayListProviderConfigsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewayGetRuntimeDefaultsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewaySetRuntimeDefaultsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let main: GatewayRuntimeDefaultSelection?
    public let concierge: GatewayRuntimeDefaultSelection?

    public init(
        apiVersion: String? = nil,
        main: GatewayRuntimeDefaultSelection? = nil,
        concierge: GatewayRuntimeDefaultSelection? = nil
    ) {
        self.apiVersion = apiVersion
        self.main = main
        self.concierge = concierge
    }
}

public struct GatewayGetMainAgentPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String?
    public let repairIfMissing: Bool?

    public init(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        repairIfMissing: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.repairIfMissing = repairIfMissing
    }
}

public struct GatewaySetMainAgentPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String?
    public let selectionMode: MainAgentSelectionMode
    public let providerId: String?
    public let modelId: String?
    public let sourceAgentDefinitionId: String?
    public let applyPersonaInstructions: Bool?

    public init(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        selectionMode: MainAgentSelectionMode,
        providerId: String? = nil,
        modelId: String? = nil,
        sourceAgentDefinitionId: String? = nil,
        applyPersonaInstructions: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.selectionMode = selectionMode
        self.providerId = providerId
        self.modelId = modelId
        self.sourceAgentDefinitionId = sourceAgentDefinitionId
        self.applyPersonaInstructions = applyPersonaInstructions
    }
}

public struct GatewayGetConciergeAgentPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String?
    public let repairIfMissing: Bool?

    public init(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        repairIfMissing: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.repairIfMissing = repairIfMissing
    }
}

public struct GatewaySetConciergeAgentPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String?
    public let selectionMode: ConciergeAgentSelectionMode
    public let providerId: String?
    public let modelId: String?
    public let sourceAgentDefinitionId: String?
    public let applyPersonaInstructions: Bool?

    public init(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        selectionMode: ConciergeAgentSelectionMode,
        providerId: String? = nil,
        modelId: String? = nil,
        sourceAgentDefinitionId: String? = nil,
        applyPersonaInstructions: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.selectionMode = selectionMode
        self.providerId = providerId
        self.modelId = modelId
        self.sourceAgentDefinitionId = sourceAgentDefinitionId
        self.applyPersonaInstructions = applyPersonaInstructions
    }
}

public struct GatewayListAvailableModelsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String?
    public let refresh: Bool?

    public init(apiVersion: String? = nil, providerId: String? = nil, refresh: Bool? = nil) {
        self.apiVersion = apiVersion
        self.providerId = providerId
        self.refresh = refresh
    }
}

public struct GatewayListProviderCatalogsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String?
    public let refresh: Bool?

    public init(apiVersion: String? = nil, providerId: String? = nil, refresh: Bool? = nil) {
        self.apiVersion = apiVersion
        self.providerId = providerId
        self.refresh = refresh
    }
}

public struct GatewayListToolsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewayGetToolPayload: Codable, Sendable {
    public let apiVersion: String?
    public let toolId: String

    public init(apiVersion: String? = nil, toolId: String) {
        self.apiVersion = apiVersion
        self.toolId = toolId
    }
}

public struct GatewayScaffoldToolPayload: Codable, Sendable {
    public let apiVersion: String?
    public let id: String
    public let displayName: String
    public let description: String
    public let outputMode: String

    public init(
        apiVersion: String? = nil,
        id: String,
        displayName: String,
        description: String,
        outputMode: String
    ) {
        self.apiVersion = apiVersion
        self.id = id
        self.displayName = displayName
        self.description = description
        self.outputMode = outputMode
    }
}

public struct GatewayRegisterToolPayload: Codable, Sendable {
    public let apiVersion: String?
    public let schemaVersion: Int?
    public let id: String
    public let displayName: String
    public let description: String
    public let bundleId: String?
    public let bundleDisplayName: String?
    public let bundleDescription: String?
    public let toolGroupId: String?
    public let toolGroupDisplayName: String?
    public let executable: String
    public let argsTemplate: [String]
    public let inputSchema: [String: AnyCodable]
    public let instructions: String?
    public let examples: [GatewayToolExample]?
    public let timeoutMs: Int?
    public let maxOutputBytes: Int?
    public let cwdMode: String
    public let fixedCwd: String?
    public let outputMode: String
    public let dangerLevel: GatewayToolDangerLevel?
    public let readme: String?
    public let enabled: Bool?

    public init(
        apiVersion: String? = nil,
        schemaVersion: Int? = nil,
        id: String,
        displayName: String,
        description: String,
        bundleId: String? = nil,
        bundleDisplayName: String? = nil,
        bundleDescription: String? = nil,
        toolGroupId: String? = nil,
        toolGroupDisplayName: String? = nil,
        executable: String,
        argsTemplate: [String],
        inputSchema: [String: Any] = [:],
        instructions: String? = nil,
        examples: [GatewayToolExample]? = nil,
        timeoutMs: Int? = nil,
        maxOutputBytes: Int? = nil,
        cwdMode: String,
        fixedCwd: String? = nil,
        outputMode: String,
        dangerLevel: GatewayToolDangerLevel? = nil,
        readme: String? = nil,
        enabled: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.schemaVersion = schemaVersion
        self.id = id
        self.displayName = displayName
        self.description = description
        self.bundleId = bundleId
        self.bundleDisplayName = bundleDisplayName
        self.bundleDescription = bundleDescription
        self.toolGroupId = toolGroupId
        self.toolGroupDisplayName = toolGroupDisplayName
        self.executable = executable
        self.argsTemplate = argsTemplate
        self.inputSchema = inputSchema.mapValues { AnyCodable($0) }
        self.instructions = instructions
        self.examples = examples
        self.timeoutMs = timeoutMs
        self.maxOutputBytes = maxOutputBytes
        self.cwdMode = cwdMode
        self.fixedCwd = fixedCwd
        self.outputMode = outputMode
        self.dangerLevel = dangerLevel
        self.readme = readme
        self.enabled = enabled
    }
}

public struct GatewayRemoveToolPayload: Codable, Sendable {
    public let apiVersion: String?
    public let toolId: String

    public init(apiVersion: String? = nil, toolId: String) {
        self.apiVersion = apiVersion
        self.toolId = toolId
    }
}

public struct GatewaySetToolEnabledPayload: Codable, Sendable {
    public let apiVersion: String?
    public let toolId: String
    public let enabled: Bool

    public init(
        apiVersion: String? = nil,
        toolId: String,
        enabled: Bool
    ) {
        self.apiVersion = apiVersion
        self.toolId = toolId
        self.enabled = enabled
    }
}

public struct GatewayRescanJiraCliToolsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewayListToolApprovalGrantsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let principalId: String?
    public let deviceId: String?
    public let spaceId: String?
    public let toolId: String?
    public let includeRevoked: Bool?
    public let includeExpired: Bool?

    public init(
        apiVersion: String? = nil,
        principalId: String? = nil,
        deviceId: String? = nil,
        spaceId: String? = nil,
        toolId: String? = nil,
        includeRevoked: Bool? = nil,
        includeExpired: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.principalId = principalId
        self.deviceId = deviceId
        self.spaceId = spaceId
        self.toolId = toolId
        self.includeRevoked = includeRevoked
        self.includeExpired = includeExpired
    }
}

public struct GatewayRevokeToolApprovalGrantPayload: Codable, Sendable {
    public let apiVersion: String?
    public let principalId: String?
    public let deviceId: String?
    public let spaceId: String
    public let toolId: String
    public let reason: String?

    public init(
        apiVersion: String? = nil,
        principalId: String? = nil,
        deviceId: String? = nil,
        spaceId: String,
        toolId: String,
        reason: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.principalId = principalId
        self.deviceId = deviceId
        self.spaceId = spaceId
        self.toolId = toolId
        self.reason = reason
    }
}

public struct GatewayGetProviderTelemetryPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String?

    public init(apiVersion: String? = nil, providerId: String? = nil) {
        self.apiVersion = apiVersion
        self.providerId = providerId
    }
}

public struct GatewayGetLocalUsageTelemetryPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String?
    public let providerIds: [String]?

    public init(apiVersion: String? = nil, providerId: String? = nil, providerIds: [String]? = nil) {
        self.apiVersion = apiVersion
        self.providerId = providerId
        self.providerIds = providerIds
    }
}

public struct GatewayGetWorkspaceDefaultsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewaySetWorkspaceDefaultsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceHomeRoot: String?

    public init(apiVersion: String? = nil, spaceHomeRoot: String? = nil) {
        self.apiVersion = apiVersion
        self.spaceHomeRoot = spaceHomeRoot
    }
}

public struct GatewayGetMemoryDefaultsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewaySetMemoryDefaultsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let defaultExperienceCapture: SpaceExperienceCaptureMode
    public let defaultSpacePrivacyMode: SpacePrivacyMode?

    public init(
        apiVersion: String? = nil,
        defaultExperienceCapture: SpaceExperienceCaptureMode,
        defaultSpacePrivacyMode: SpacePrivacyMode? = .standard
    ) {
        self.apiVersion = apiVersion
        self.defaultExperienceCapture = defaultExperienceCapture
        self.defaultSpacePrivacyMode = defaultSpacePrivacyMode
    }
}

public struct GatewayGetExternalConnectivityPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewaySetExternalConnectivityPayload: Codable, Sendable {
    public let apiVersion: String?
    public let mode: String

    public init(apiVersion: String? = nil, mode: String) {
        self.apiVersion = apiVersion
        self.mode = mode
    }
}

public struct GatewayGetProviderSettingsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String

    public init(apiVersion: String? = nil, providerId: String) {
        self.apiVersion = apiVersion
        self.providerId = providerId
    }
}

public struct GatewaySetProviderConfigPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String
    public let model: String?
    public let apiKey: String?
    public let apiKeySecretRef: String?
    public let authMode: GatewayProviderAuthMode?
    public let baseURL: String?
    public let executablePath: String?
    public let allowedModels: [String]?
    public let allowCustomModel: Bool?

    public init(
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
    ) {
        self.apiVersion = apiVersion
        self.providerId = providerId
        self.model = model
        self.apiKey = apiKey
        self.apiKeySecretRef = apiKeySecretRef
        self.authMode = authMode
        self.baseURL = baseURL
        self.executablePath = executablePath
        self.allowedModels = allowedModels
        self.allowCustomModel = allowCustomModel
    }
}

public struct GatewayUpdateProviderSettingsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String
    public let model: String?
    public let apiKey: String?
    public let apiKeySecretRef: String?
    public let authMode: GatewayProviderAuthMode?
    public let baseURL: String?
    public let executablePath: String?
    public let allowedModels: [String]?
    public let allowCustomModel: Bool?

    public init(
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
    ) {
        self.apiVersion = apiVersion
        self.providerId = providerId
        self.model = model
        self.apiKey = apiKey
        self.apiKeySecretRef = apiKeySecretRef
        self.authMode = authMode
        self.baseURL = baseURL
        self.executablePath = executablePath
        self.allowedModels = allowedModels
        self.allowCustomModel = allowCustomModel
    }
}

public struct GatewayRemoveProviderConfigPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String

    public init(apiVersion: String? = nil, providerId: String) {
        self.apiVersion = apiVersion
        self.providerId = providerId
    }
}

public struct GatewayFactoryResetPayload: Codable, Sendable {
    public let apiVersion: String?
    public let confirmation: String

    public init(apiVersion: String? = nil, confirmation: String) {
        self.apiVersion = apiVersion
        self.confirmation = confirmation
    }
}

public struct GatewayProvisionLocalProfilePayload: Codable, Sendable {
    public let apiVersion: String?
    public let localClientId: String
    public let profileId: String?
    public let profileName: String?
    public let agentId: String?
    public let spaceId: String?

    public init(
        apiVersion: String? = nil,
        localClientId: String,
        profileId: String? = nil,
        profileName: String? = nil,
        agentId: String? = nil,
        spaceId: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.localClientId = localClientId
        self.profileId = profileId
        self.profileName = profileName
        self.agentId = agentId
        self.spaceId = spaceId
    }
}

public struct GatewayPutSecretRefPayload: Codable, Sendable {
    public let apiVersion: String?
    public let secretRef: String?
    public let providerId: String
    public let label: String?
    public let secret: String
    public let backend: String?

    public init(
        apiVersion: String? = nil,
        secretRef: String? = nil,
        providerId: String,
        label: String? = nil,
        secret: String,
        backend: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.secretRef = secretRef
        self.providerId = providerId
        self.label = label
        self.secret = secret
        self.backend = backend
    }
}

public struct GatewayListSecretRefsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String?

    public init(apiVersion: String? = nil, providerId: String? = nil) {
        self.apiVersion = apiVersion
        self.providerId = providerId
    }
}

public struct GatewayDeleteSecretRefPayload: Codable, Sendable {
    public let apiVersion: String?
    public let secretRef: String

    public init(apiVersion: String? = nil, secretRef: String) {
        self.apiVersion = apiVersion
        self.secretRef = secretRef
    }
}

public struct GatewayListInterconnectorsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewayRescanInterconnectorsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewayGetIntegrationsSnapshotPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

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

public struct SpaceCreateInitialAgentPayload: Codable, Sendable {
    public let agentId: String
    public let profileId: String
    public let securityScope: [String: AnyCodable]?
    public let role: String?
    public let turnOrder: Int?
    public let isPrimary: Bool?

    public init(
        agentId: String,
        profileId: String,
        securityScope: [String: Any]? = nil,
        role: String? = nil,
        turnOrder: Int? = nil,
        isPrimary: Bool? = nil
    ) {
        self.agentId = agentId
        self.profileId = profileId
        self.securityScope = securityScope?.mapValues { AnyCodable($0) }
        self.role = role
        self.turnOrder = turnOrder
        self.isPrimary = isPrimary
    }
}

public struct SpaceCreateResponsePayload: Codable, Sendable {
    public let space: SpaceConfig

    private enum CodingKeys: String, CodingKey {
        case space
    }

    public init(space: SpaceConfig) {
        self.space = space
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let wrapped = try container.decodeIfPresent(SpaceConfig.self, forKey: .space) {
            self.space = wrapped
            return
        }
        self.space = try SpaceConfig(from: decoder)
    }
}

public struct SpaceGetResponsePayload: Codable, Sendable {
    public let space: SpaceConfig

    private enum CodingKeys: String, CodingKey {
        case space
    }

    public init(space: SpaceConfig) {
        self.space = space
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let wrapped = try container.decodeIfPresent(SpaceConfig.self, forKey: .space) {
            self.space = wrapped
            return
        }
        self.space = try SpaceConfig(from: decoder)
    }
}

public struct SpaceGetMemoryPolicyResponsePayload: Codable, Sendable {
    public let spaceId: String
    public let memoryPolicy: SpaceMemoryPolicy
}

public struct SpaceListResponsePayload: Codable, Sendable {
    public let spaces: [SpaceConfig]

    private enum CodingKeys: String, CodingKey {
        case spaces
    }

    public init(spaces: [SpaceConfig]) {
        self.spaces = spaces
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let wrapped = try container.decodeIfPresent([SpaceConfig].self, forKey: .spaces) {
            self.spaces = wrapped
            return
        }
        self.spaces = try [SpaceConfig](from: decoder)
    }
}

public struct SpaceArchiveResponsePayload: Codable, Sendable {
    public let space: SpaceConfig
    public let archived: Bool
}

public struct SpaceDeleteResponsePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let deleted: Bool
    public let space: SpaceConfig?
}

public struct SpaceAddAgentResponsePayload: Codable, Sendable {
    public let assignment: SpaceAgentAssignment
    public let space: SpaceConfig?
}

public struct SpaceRemoveAgentResponsePayload: Codable, Sendable {
    public let removed: Bool
    public let spaceId: String
    public let spaceUid: String
    public let agentId: String
    public let space: SpaceConfig?
}

public struct SpaceUpdateAgentAssignmentResponsePayload: Codable, Sendable {
    public let assignment: SpaceAgentAssignment
    public let space: SpaceConfig?
}

public struct SpaceUpdateMetadataResponsePayload: Codable, Sendable {
    public let space: SpaceConfig
}

public struct SpaceSetThinkingCapturePolicyResponsePayload: Codable, Sendable {
    public let space: SpaceConfig
}

public struct SpaceSetMemoryPolicyResponsePayload: Codable, Sendable {
    public let space: SpaceConfig
}

public struct SpaceEndIncognitoSessionResponsePayload: Codable, Sendable {
    public let space: SpaceConfig
    public let ended: Bool
    public let reason: String
    public let purgedAt: String?
    public let sessionId: String?
}

public struct SpaceListAgentAssignmentsResponsePayload: Codable, Sendable {
    public let assignments: [SpaceAgentAssignment]
}

public struct SpaceGetMcpEndpointResponsePayload: Codable, Sendable {
    public let spaceId: String
    public let endpoint: SpaceMcpEndpoint?
    public let fallbackEnabled: Bool
}

public struct SpaceSetMcpEndpointResponsePayload: Codable, Sendable {
    public let endpoint: SpaceMcpEndpoint
}

public struct SpaceClearMcpEndpointResponsePayload: Codable, Sendable {
    public let spaceId: String
    public let cleared: Bool
}

public struct SpaceAddSkillResponsePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let skillId: String
    public let skills: [String]
    public let space: SpaceConfig?
}

public struct SpaceRemoveSkillResponsePayload: Codable, Sendable {
    public let removed: Bool
    public let spaceId: String
    public let spaceUid: String
    public let skillId: String
    public let skills: [String]
    public let space: SpaceConfig?
}

public struct SpaceListSkillsResponsePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let skills: [String]
}

public struct SpaceGetWorkspaceResponsePayload: Codable, Sendable {
    public let workspace: SpaceWorkspace
}

public struct SpaceSetWorkspaceResponsePayload: Codable, Sendable {
    public let workspace: SpaceWorkspace
}

public struct SpaceOpenWorkspaceResponsePayload: Codable, Sendable {
    public let result: SpaceOpenWorkspaceResult
}

public struct SpaceAddResourceResponsePayload: Codable, Sendable {
    public let resource: SpaceResource
}

public struct SpaceRemoveResourceResponsePayload: Codable, Sendable {
    public let removed: Bool
    public let spaceId: String
    public let spaceUid: String
    public let resourceId: String
}

public struct SpaceListResourcesResponsePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let resources: [SpaceResource]
}

public struct SpaceListTurnsResponsePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let turns: [SpaceTurn]
    public let total: Int
    public let nextOffset: Int?
}

public struct SpaceListOrchestrationJournalResponsePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let entries: [OrchestrationJournalEntry]
    public let total: Int
    public let nextOffset: Int?
}

public struct IdentityListAgentDefinitionsResponsePayload: Codable, Sendable {
    public let agentDefinitions: [AgentDefinitionSummary]
}

public struct IdentityGetAgentDefinitionResponsePayload: Codable, Sendable {
    public let agentDefinition: AgentDefinitionSummary
}

public struct IdentityCreateAgentDefinitionResponsePayload: Codable, Sendable {
    public let agentDefinition: AgentDefinitionSummary
    public let created: Bool
}

public struct IdentityUpdateAgentDefinitionResponsePayload: Codable, Sendable {
    public let agentDefinition: AgentDefinitionSummary
    public let newRevision: Int
}

public struct IdentityArchiveAgentDefinitionResponsePayload: Codable, Sendable {
    public let agentDefinition: AgentDefinitionSummary
    public let archived: Bool
}

public struct IdentityListPersonasResponsePayload: Codable, Sendable {
    public let personas: [PersonaSummary]
}

public struct IdentityGetPersonaResponsePayload: Codable, Sendable {
    public let persona: PersonaSummary
}

public struct IdentityCreatePersonaResponsePayload: Codable, Sendable {
    public let persona: PersonaSummary
    public let created: Bool
}

public struct IdentityUpdatePersonaResponsePayload: Codable, Sendable {
    public let persona: PersonaSummary
    public let newRevision: Int
}

public struct IdentityArchivePersonaResponsePayload: Codable, Sendable {
    public let persona: PersonaSummary
    public let archived: Bool
}

public struct IdentityPreviewCompiledInstructionsResponsePayload: Codable, Sendable {
    public let preview: CompiledInstructionsPreview
}

public struct IdentityPreviewRuntimeSystemPromptResponsePayload: Codable, Sendable {
    public let preview: RuntimeSystemPromptPreview
}

public struct SpacePreviewTemplateResponsePayload: Codable, Sendable {
    public let template: SpaceTemplateSummary
    public let resolved: SpaceTemplatePreviewResolved
    public let warnings: [String]
}

public typealias SpaceCreateFromTemplateResultPayload = SpaceCreateFromTemplateResult
public typealias SpaceSaveTemplateResultPayload = SpaceSaveTemplateResult

public struct SpaceTemplateListResponsePayload: Codable, Sendable {
    public let templates: [SpaceTemplateRecord]
}

public struct SpaceTemplateGetResponsePayload: Codable, Sendable {
    public let template: SpaceTemplateRecord
}

public struct SpaceTemplatePreviewResponsePayload: Codable, Sendable {
    public let template: SpaceTemplateRecord
    public let resolved: SpaceTemplatePreviewResolved
    public let warnings: [String]
}

public struct SpaceTemplateCreateSpaceResponsePayload: Codable, Sendable {
    public let template: SpaceTemplateRecord
    public let space: SpaceConfig
}

public struct SpaceTemplateSaveResponsePayload: Codable, Sendable {
    public let template: SpaceTemplateRecord
    public let created: Bool
}

public struct SpaceTemplateArchiveResponsePayload: Codable, Sendable {
    public let template: SpaceTemplateRecord
    public let archived: Bool
}

public struct LibraryListEntriesResponsePayload: Codable, Sendable {
    public let entries: [LibraryEntry]
}

public struct LibraryGetEntryResponsePayload: Codable, Sendable {
    public let entry: LibraryEntry
}

public struct LibrarySaveSkillResponsePayload: Codable, Sendable {
    public let entry: LibraryEntry
    public let created: Bool
}

public struct LibraryImportEntryResponsePayload: Codable, Sendable {
    public let entry: LibraryEntry
    public let created: Bool
}

public struct LibraryArchiveEntryResponsePayload: Codable, Sendable {
    public let entry: LibraryEntry
    public let archived: Bool
}

public struct LibrarySetEntryEnabledResponsePayload: Codable, Sendable {
    public let entry: LibraryEntry
}

public struct LibraryDeleteEntryResponsePayload: Codable, Sendable {
    public let entryId: String
    public let deleted: Bool
}

public struct LibraryScanEntriesResponsePayload: Codable, Sendable {
    public let entries: [LibraryEntry]
    public let scannedAt: String
}

public struct LibraryListSkillDraftsResponsePayload: Codable, Sendable {
    public let drafts: [SkillDraft]
}

public struct LibraryGetSkillDraftResponsePayload: Codable, Sendable {
    public let draft: SkillDraft
}

public struct LibraryCreateSkillDraftResponsePayload: Codable, Sendable {
    public let draft: SkillDraft
    public let created: Bool
}

public struct LibraryDeleteSkillDraftResponsePayload: Codable, Sendable {
    public let draftId: String
    public let deleted: Bool
}

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

public enum GatewayBuiltinMcpAdminAuthMode: String, Codable, Sendable, Equatable {
    case strict
    case compat
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

public struct SchedulerCreateJobPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let name: String
    public let timezone: String
    public let schedulePreset: SchedulerSchedulePreset
    public let action: SchedulerAction
    public let primarySpaceId: String
    public let relatedSpaceIds: [String]?
    public let executionTarget: SchedulerExecutionTarget?
    public let calendarBinding: SchedulerCalendarBinding?
    public let evalConfig: SchedulerEvalConfig??

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        name: String,
        timezone: String,
        schedulePreset: SchedulerSchedulePreset,
        action: SchedulerAction,
        primarySpaceId: String,
        relatedSpaceIds: [String]? = nil,
        executionTarget: SchedulerExecutionTarget? = nil,
        calendarBinding: SchedulerCalendarBinding? = nil,
        evalConfig: SchedulerEvalConfig?? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.name = name
        self.timezone = timezone
        self.schedulePreset = schedulePreset
        self.action = action
        self.primarySpaceId = primarySpaceId
        self.relatedSpaceIds = relatedSpaceIds
        self.executionTarget = executionTarget
        self.calendarBinding = calendarBinding
        self.evalConfig = evalConfig
    }
}

public struct SchedulerCreateJobResponsePayload: Codable, Sendable {
    public let job: SchedulerJob
}

public struct SchedulerGetJobPayload: Codable, Sendable {
    public let apiVersion: String?
    public let jobId: String

    public init(apiVersion: String? = nil, jobId: String) {
        self.apiVersion = apiVersion
        self.jobId = jobId
    }
}

public struct SchedulerGetJobResponsePayload: Codable, Sendable {
    public let job: SchedulerJob
}

public struct SchedulerListJobsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let statuses: [SchedulerJobStatus]?
    public let gatewayId: String?
    public let limit: Int?

    public init(
        apiVersion: String? = nil,
        statuses: [SchedulerJobStatus]? = nil,
        gatewayId: String? = nil,
        limit: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.statuses = statuses
        self.gatewayId = gatewayId
        self.limit = limit
    }
}

public struct SchedulerListJobsResponsePayload: Codable, Sendable {
    public let jobs: [SchedulerJob]
}

public struct SchedulerListEvalDefinitionsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct SchedulerListEvalDefinitionsResponsePayload: Codable, Sendable {
    public let definitions: [SchedulerEvalDefinition]
}

public struct SchedulerUpdateJobPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let jobId: String
    public let name: String?
    public let status: SchedulerJobStatus?
    public let timezone: String?
    public let schedulePreset: SchedulerSchedulePreset?
    public let action: SchedulerAction?
    public let primarySpaceId: String?
    public let relatedSpaceIds: [String]?
    public let executionTarget: SchedulerExecutionTarget?
    public let calendarBinding: SchedulerCalendarBinding?
    public let evalConfig: SchedulerEvalConfig??

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        jobId: String,
        name: String? = nil,
        status: SchedulerJobStatus? = nil,
        timezone: String? = nil,
        schedulePreset: SchedulerSchedulePreset? = nil,
        action: SchedulerAction? = nil,
        primarySpaceId: String? = nil,
        relatedSpaceIds: [String]? = nil,
        executionTarget: SchedulerExecutionTarget? = nil,
        calendarBinding: SchedulerCalendarBinding? = nil,
        evalConfig: SchedulerEvalConfig?? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.jobId = jobId
        self.name = name
        self.status = status
        self.timezone = timezone
        self.schedulePreset = schedulePreset
        self.action = action
        self.primarySpaceId = primarySpaceId
        self.relatedSpaceIds = relatedSpaceIds
        self.executionTarget = executionTarget
        self.calendarBinding = calendarBinding
        self.evalConfig = evalConfig
    }
}

public struct SchedulerUpdateJobResponsePayload: Codable, Sendable {
    public let job: SchedulerJob
}

public struct SchedulerDeleteJobPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let jobId: String

    public init(apiVersion: String? = nil, idempotencyKey: String? = nil, jobId: String) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.jobId = jobId
    }
}

public struct SchedulerDeleteJobResponsePayload: Codable, Sendable {
    public let jobId: String
    public let deleted: Bool
}

public struct SchedulerLinkSpacePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let jobId: String
    public let spaceId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        jobId: String,
        spaceId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.jobId = jobId
        self.spaceId = spaceId
    }
}

public struct SchedulerLinkSpaceResponsePayload: Codable, Sendable {
    public let job: SchedulerJob
}

public struct SchedulerUnlinkSpacePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let jobId: String
    public let spaceId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        jobId: String,
        spaceId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.jobId = jobId
        self.spaceId = spaceId
    }
}

public struct SchedulerUnlinkSpaceResponsePayload: Codable, Sendable {
    public let job: SchedulerJob
}

public struct SchedulerListRunsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let jobId: String
    public let limit: Int?
    public let offset: Int?

    public init(
        apiVersion: String? = nil,
        jobId: String,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.jobId = jobId
        self.limit = limit
        self.offset = offset
    }
}

public struct SchedulerListRunsResponsePayload: Codable, Sendable {
    public let runs: [SchedulerJobRun]
    public let total: Int
    public let nextOffset: Int?
}

public struct SchedulerRunNowPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let jobId: String

    public init(apiVersion: String? = nil, idempotencyKey: String? = nil, jobId: String) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.jobId = jobId
    }
}

public struct SchedulerRunNowResponsePayload: Codable, Sendable {
    public let run: SchedulerJobRun
    public let job: SchedulerJob
}

public struct WorkbenchListQueuePayload: Codable, Sendable {
    public let apiVersion: String?
    public let limit: Int?

    public init(apiVersion: String? = nil, limit: Int? = nil) {
        self.apiVersion = apiVersion
        self.limit = limit
    }
}

public struct WorkbenchListQueueResponsePayload: Codable, Sendable {
    public let items: [WorkbenchQueueItem]
}

public struct WorkbenchGetQueueItemPayload: Codable, Sendable {
    public let apiVersion: String?
    public let queueItemId: String

    public init(apiVersion: String? = nil, queueItemId: String) {
        self.apiVersion = apiVersion
        self.queueItemId = queueItemId
    }
}

public struct WorkbenchGetQueueItemResponsePayload: Codable, Sendable {
    public let item: WorkbenchQueueItem
}

public struct WorkbenchCreateBatchPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let name: String
    public let queueItemIds: [String]
    public let executionMode: WorkbenchExecutionMode?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        name: String,
        queueItemIds: [String],
        executionMode: WorkbenchExecutionMode? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.name = name
        self.queueItemIds = queueItemIds
        self.executionMode = executionMode
    }
}

public struct WorkbenchCreateBatchResponsePayload: Codable, Sendable {
    public let batch: WorkbenchBatch
}

public struct WorkbenchListBatchesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let limit: Int?

    public init(apiVersion: String? = nil, limit: Int? = nil) {
        self.apiVersion = apiVersion
        self.limit = limit
    }
}

public struct WorkbenchListBatchesResponsePayload: Codable, Sendable {
    public let batches: [WorkbenchBatch]
}

public struct WorkbenchUpdateBatchPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let batchId: String
    public let name: String?
    public let queueItemIds: [String]?
    public let executionMode: WorkbenchExecutionMode?
    public let status: WorkbenchBatchStatus?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        batchId: String,
        name: String? = nil,
        queueItemIds: [String]? = nil,
        executionMode: WorkbenchExecutionMode? = nil,
        status: WorkbenchBatchStatus? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.batchId = batchId
        self.name = name
        self.queueItemIds = queueItemIds
        self.executionMode = executionMode
        self.status = status
    }
}

public struct WorkbenchUpdateBatchResponsePayload: Codable, Sendable {
    public let batch: WorkbenchBatch
}

public struct WorkbenchStartRunPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let queueItemId: String
    public let batchId: String?
    public let executionMode: WorkbenchExecutionMode?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        queueItemId: String,
        batchId: String? = nil,
        executionMode: WorkbenchExecutionMode? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.queueItemId = queueItemId
        self.batchId = batchId
        self.executionMode = executionMode
    }
}

public struct WorkbenchStartRunResponsePayload: Codable, Sendable {
    public let run: WorkbenchRun
}

public struct WorkbenchRetryRunPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let runId: String

    public init(apiVersion: String? = nil, idempotencyKey: String? = nil, runId: String) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.runId = runId
    }
}

public struct WorkbenchRetryRunResponsePayload: Codable, Sendable {
    public let run: WorkbenchRun
}

public struct WorkbenchCancelRunPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let runId: String

    public init(apiVersion: String? = nil, idempotencyKey: String? = nil, runId: String) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.runId = runId
    }
}

public struct WorkbenchCancelRunResponsePayload: Codable, Sendable {
    public let run: WorkbenchRun
}

public struct WorkbenchListRunsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let batchId: String?
    public let queueItemId: String?
    public let limit: Int?

    public init(
        apiVersion: String? = nil,
        batchId: String? = nil,
        queueItemId: String? = nil,
        limit: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.batchId = batchId
        self.queueItemId = queueItemId
        self.limit = limit
    }
}

public struct WorkbenchListRunsResponsePayload: Codable, Sendable {
    public let runs: [WorkbenchRun]
}

public struct WorkbenchGetRunPayload: Codable, Sendable {
    public let apiVersion: String?
    public let runId: String

    public init(apiVersion: String? = nil, runId: String) {
        self.apiVersion = apiVersion
        self.runId = runId
    }
}

public struct WorkbenchGetRunResponsePayload: Codable, Sendable {
    public let run: WorkbenchRun
}

public struct WorkbenchApproveStagePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let runId: String
    public let stage: WorkbenchRunStage?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        runId: String,
        stage: WorkbenchRunStage? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.runId = runId
        self.stage = stage
    }
}

public struct WorkbenchApproveStageResponsePayload: Codable, Sendable {
    public let run: WorkbenchRun
}

public struct WorkbenchRejectStagePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let runId: String
    public let stage: WorkbenchRunStage?
    public let reason: String?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        runId: String,
        stage: WorkbenchRunStage? = nil,
        reason: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.runId = runId
        self.stage = stage
        self.reason = reason
    }
}

public struct WorkbenchRejectStageResponsePayload: Codable, Sendable {
    public let run: WorkbenchRun
}

public struct WorkbenchSetModePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let runId: String?
    public let batchId: String?
    public let executionMode: WorkbenchExecutionMode

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        runId: String? = nil,
        batchId: String? = nil,
        executionMode: WorkbenchExecutionMode
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.runId = runId
        self.batchId = batchId
        self.executionMode = executionMode
    }
}

public struct WorkbenchSetModeResponsePayload: Codable, Sendable {
    public let run: WorkbenchRun?
    public let batch: WorkbenchBatch?
}

public struct WorkbenchListArtifactsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let runId: String

    public init(apiVersion: String? = nil, runId: String) {
        self.apiVersion = apiVersion
        self.runId = runId
    }
}

public struct WorkbenchListArtifactsResponsePayload: Codable, Sendable {
    public let artifacts: [WorkbenchArtifact]
}

public struct WorkbenchGetPolicyPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct WorkbenchGetPolicyResponsePayload: Codable, Sendable {
    public let policy: WorkbenchPolicy
}

public struct WorkbenchUpdatePolicyPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let defaultExecutionMode: WorkbenchExecutionMode?
    public let autonomousEnabled: Bool?
    public let maxParallelRuns: Int?
    public let requireExplicitAutonomousOptIn: Bool?
    public let requireAiShippableForAutonomous: Bool?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        defaultExecutionMode: WorkbenchExecutionMode? = nil,
        autonomousEnabled: Bool? = nil,
        maxParallelRuns: Int? = nil,
        requireExplicitAutonomousOptIn: Bool? = nil,
        requireAiShippableForAutonomous: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.defaultExecutionMode = defaultExecutionMode
        self.autonomousEnabled = autonomousEnabled
        self.maxParallelRuns = maxParallelRuns
        self.requireExplicitAutonomousOptIn = requireExplicitAutonomousOptIn
        self.requireAiShippableForAutonomous = requireAiShippableForAutonomous
    }
}

public struct WorkbenchUpdatePolicyResponsePayload: Codable, Sendable {
    public let policy: WorkbenchPolicy
}

public struct OrchestratorCommandPayload: Codable, Sendable {
    public let apiVersion: String?
    public let correlationId: String?
    public let idempotencyKey: String?
    public let commandType: String
    public let targetSpaceId: String?
    public let targetAgentId: String?
    public let payload: [String: AnyCodable]?

    public init(
        apiVersion: String? = nil,
        correlationId: String? = nil,
        idempotencyKey: String? = nil,
        commandType: String,
        targetSpaceId: String? = nil,
        targetAgentId: String? = nil,
        payload: [String: Any]? = nil
    ) {
        self.apiVersion = apiVersion
        self.correlationId = correlationId
        self.idempotencyKey = idempotencyKey
        self.commandType = commandType
        self.targetSpaceId = targetSpaceId
        self.targetAgentId = targetAgentId
        self.payload = payload?.mapValues { AnyCodable($0) }
    }
}

public struct OrchestratorGetCommandPayload: Codable, Sendable {
    public let apiVersion: String?
    public let commandId: String

    public init(apiVersion: String? = nil, commandId: String) {
        self.apiVersion = apiVersion
        self.commandId = commandId
    }
}

public struct OrchestratorCommandResponsePayload: Codable, Sendable {
    public let command: OrchestratorCommandResult
}

public struct SpaceLinkPayload: Codable, Sendable {
    public let apiVersion: String?
    public let sourceSpaceId: String
    public let targetSpaceId: String
    public let mode: String?

    public init(apiVersion: String? = nil, sourceSpaceId: String, targetSpaceId: String, mode: String? = nil) {
        self.apiVersion = apiVersion
        self.sourceSpaceId = sourceSpaceId
        self.targetSpaceId = targetSpaceId
        self.mode = mode
    }
}

public struct SpaceLinkResponsePayload: Codable, Sendable {
    public let link: SpaceLinkResult
}

public struct SpaceUnlinkPayload: Codable, Sendable {
    public let apiVersion: String?
    public let sourceSpaceId: String
    public let targetSpaceId: String

    public init(apiVersion: String? = nil, sourceSpaceId: String, targetSpaceId: String) {
        self.apiVersion = apiVersion
        self.sourceSpaceId = sourceSpaceId
        self.targetSpaceId = targetSpaceId
    }
}

public struct SpaceUnlinkResponsePayload: Codable, Sendable {
    public let removed: Bool
    public let sourceSpaceId: String
    public let targetSpaceId: String
}

public struct SpaceShareContextPayload: Codable, Sendable {
    public let apiVersion: String?
    public let sourceSpaceId: String
    public let targetSpaceId: String
    public let artifactId: String

    public init(apiVersion: String? = nil, sourceSpaceId: String, targetSpaceId: String, artifactId: String) {
        self.apiVersion = apiVersion
        self.sourceSpaceId = sourceSpaceId
        self.targetSpaceId = targetSpaceId
        self.artifactId = artifactId
    }
}

public struct SpaceShareContextResponsePayload: Codable, Sendable {
    public let transfer: SharedContextRef
}

public struct SpaceShareCreateInvitePayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let mode: SpaceShareAccessMode
    public let expiresInSeconds: Int?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        mode: SpaceShareAccessMode,
        expiresInSeconds: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.mode = mode
        self.expiresInSeconds = expiresInSeconds
    }
}

public struct SpaceShareCreateInviteResponsePayload: Codable, Sendable {
    public let invite: SpaceShareInvite
}

public enum SpaceShareJoinRoute: String, Codable, Sendable {
    case direct
    case relayProxy = "relay_proxy"
}

public enum SpaceShareIdentityModeHint: String, Codable, Sendable {
    case deviceKey = "device_key"
    case strictAppleId = "strict_apple_id"
}

public struct SpaceShareJoinPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let inviteToken: String
    public let deviceId: String?
    public let devicePublicKey: String?
    public let identityModeHint: SpaceShareIdentityModeHint?
    public let appleIdAssertion: String?
    public let joinRoute: SpaceShareJoinRoute?
    public let relaySessionToken: String?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        inviteToken: String,
        deviceId: String? = nil,
        devicePublicKey: String? = nil,
        identityModeHint: SpaceShareIdentityModeHint? = nil,
        appleIdAssertion: String? = nil,
        joinRoute: SpaceShareJoinRoute? = nil,
        relaySessionToken: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.inviteToken = inviteToken
        self.deviceId = deviceId
        self.devicePublicKey = devicePublicKey
        self.identityModeHint = identityModeHint
        self.appleIdAssertion = appleIdAssertion
        self.joinRoute = joinRoute
        self.relaySessionToken = relaySessionToken
    }
}

public struct SpaceShareJoinResponsePayload: Codable, Sendable {
    public let participant: SpaceParticipant
}

public struct SpaceShareRevokePayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let inviteId: String?
    public let participantId: String?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        inviteId: String? = nil,
        participantId: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.inviteId = inviteId
        self.participantId = participantId
    }
}

public struct SpaceShareRevokeResponsePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let inviteId: String?
    public let participantId: String?
    public let revokedInvite: Bool
    public let revokedParticipant: Bool
}

public struct SpaceShareListParticipantsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceShareListParticipantsResponsePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let participants: [SpaceParticipant]
}

public struct SpacePullSharedContextPayload: Codable, Sendable {
    public let apiVersion: String?
    public let sourceSpaceId: String
    public let targetSpaceId: String
    public let limit: Int?

    public init(apiVersion: String? = nil, sourceSpaceId: String, targetSpaceId: String, limit: Int? = nil) {
        self.apiVersion = apiVersion
        self.sourceSpaceId = sourceSpaceId
        self.targetSpaceId = targetSpaceId
        self.limit = limit
    }
}

public struct SyncAnnouncePayload: Codable, Sendable {
    public let apiVersion: String?
    public let peerId: String
    public let resourceId: String
    public let gatewayVersion: String
    public let endpointUrl: String?
    public let authSecretHash: String?
    public let skillCount: Int?
    public let actionCount: Int?
    public let experienceCount: Int?
    public let profileCount: Int?
}

public struct SyncQueryResourcesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let peerId: String
    public let resourceId: String?
    public let types: [String]?
    public let tags: [String]?
    public let updatedAfter: String?
    public let cursor: String?
    public let limit: Int?
}

public struct SyncQueryResourcesResponsePayload: Codable, Sendable {
    public let resources: [SyncResourceRef]
    public let nextCursor: String?
}

public struct SyncPullResourcesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let peerId: String
    public let idempotencyKey: String
    public let refs: [SyncResourceRef]
}

public struct SyncPullResourcesResponsePayload: Codable, Sendable {
    public let resources: [SyncResource]
    public let denied: [SyncResourceDenied]
    public let appliedCount: Int
    public let skippedCount: Int
}

public struct SubscribeNotificationsPayload: Codable, Sendable {
    public let categories: [String]

    public init(categories: [String]) {
        self.categories = categories
    }
}

public struct UnsubscribeNotificationsPayload: Codable, Sendable {
    public let categories: [String]

    public init(categories: [String]) {
        self.categories = categories
    }
}

public struct NotificationSubscriptionResponsePayload: Codable, Sendable {
    public let categories: [String]
}

public enum ConciergeActionRequestType: String, Codable, Sendable {
    case createSpace = "create_space"
    case openWorkspace = "open_workspace"
    case updateSpace = "update_space"
    case addAgent = "add_agent"
    case removeAgent = "remove_agent"
    case runSpacePrompt = "run_space_prompt"
    case draftSchedulerJob = "draft_scheduler_job"
}

public struct AppConciergeActionRequestPayload: Codable, Sendable {
    public let requestId: String
    public let action: ConciergeActionRequestType
    public let gatewayId: String?
    public let params: [String: AnyCodable]?

    public init(
        requestId: String,
        action: ConciergeActionRequestType,
        gatewayId: String? = nil,
        params: [String: AnyCodable]? = nil
    ) {
        self.requestId = requestId
        self.action = action
        self.gatewayId = gatewayId
        self.params = params
    }
}

public enum ConciergeActionResultStatus: String, Codable, Sendable {
    case ok
    case error
}

public struct ConciergeActionResultPayload: Codable, Sendable {
    public let requestId: String
    public let status: ConciergeActionResultStatus
    public let payload: [String: AnyCodable]?
    public let error: String?

    public init(
        requestId: String,
        status: ConciergeActionResultStatus,
        payload: [String: Any]? = nil,
        error: String? = nil
    ) {
        self.requestId = requestId
        self.status = status
        self.payload = payload?.mapValues { AnyCodable($0) }
        self.error = error
    }
}

public struct ConciergeActionResultAckPayload: Codable, Sendable {
    public let acknowledged: Bool
    public let requestId: String
}

public struct SpeechStartPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let spaceUid: String?
    public let sessionId: String?
    public let locale: String?
    public let sourceDevice: String?
    public let enableTranscription: Bool?
    public let enablePlayback: Bool?
    public let agentId: String?
    public let autoSubmitTurns: Bool?
    public let preferredSource: String?
    public let preferredProviderId: String?
    public let byokProviderId: String?
    public let localModelProviderId: String?
    public let appleSpeechProviderId: String?
    public let allowByokFallback: Bool?
    public let allowLocalFallback: Bool?
    public let allowAppleSpeechFallback: Bool?
    public let sttPreferences: SpeechRoutePreferences?
    public let ttsPreferences: SpeechRoutePreferences?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        spaceUid: String? = nil,
        sessionId: String? = nil,
        locale: String? = nil,
        sourceDevice: String? = nil,
        enableTranscription: Bool? = nil,
        enablePlayback: Bool? = nil,
        agentId: String? = nil,
        autoSubmitTurns: Bool? = nil,
        preferredSource: String? = nil,
        preferredProviderId: String? = nil,
        byokProviderId: String? = nil,
        localModelProviderId: String? = nil,
        appleSpeechProviderId: String? = nil,
        allowByokFallback: Bool? = nil,
        allowLocalFallback: Bool? = nil,
        allowAppleSpeechFallback: Bool? = nil,
        sttPreferences: SpeechRoutePreferences? = nil,
        ttsPreferences: SpeechRoutePreferences? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.sessionId = sessionId
        self.locale = locale
        self.sourceDevice = sourceDevice
        self.enableTranscription = enableTranscription
        self.enablePlayback = enablePlayback
        self.agentId = agentId
        self.autoSubmitTurns = autoSubmitTurns
        self.preferredSource = preferredSource
        self.preferredProviderId = preferredProviderId
        self.byokProviderId = byokProviderId
        self.localModelProviderId = localModelProviderId
        self.appleSpeechProviderId = appleSpeechProviderId
        self.allowByokFallback = allowByokFallback
        self.allowLocalFallback = allowLocalFallback
        self.allowAppleSpeechFallback = allowAppleSpeechFallback
        self.sttPreferences = sttPreferences
        self.ttsPreferences = ttsPreferences
    }
}

public struct SpeechAudioChunkPayload: Codable, Sendable {
    public let apiVersion: String?
    public let sessionId: String
    public let sequence: Int
    public let sequenceNo: Int?
    public let audioBase64: String
    public let sampleRateHz: Int?
    public let channels: Int?
    public let codec: String?
    public let audioDurationSeconds: Double?
    public let ttsChars: Int?
    public let ttsSeconds: Double?
    public let transcriptText: String?
    public let isFinal: Bool?
    public let engineMetrics: SpeechEngineMetrics?

    public init(
        apiVersion: String? = nil,
        sessionId: String,
        sequence: Int,
        sequenceNo: Int? = nil,
        audioBase64: String,
        sampleRateHz: Int? = nil,
        channels: Int? = nil,
        codec: String? = nil,
        audioDurationSeconds: Double? = nil,
        ttsChars: Int? = nil,
        ttsSeconds: Double? = nil,
        transcriptText: String? = nil,
        isFinal: Bool? = nil,
        engineMetrics: SpeechEngineMetrics? = nil
    ) {
        self.apiVersion = apiVersion
        self.sessionId = sessionId
        self.sequence = sequence
        self.sequenceNo = sequenceNo
        self.audioBase64 = audioBase64
        self.sampleRateHz = sampleRateHz
        self.channels = channels
        self.codec = codec
        self.audioDurationSeconds = audioDurationSeconds
        self.ttsChars = ttsChars
        self.ttsSeconds = ttsSeconds
        self.transcriptText = transcriptText
        self.isFinal = isFinal
        self.engineMetrics = engineMetrics
    }
}

public struct SpeechControlPayload: Codable, Sendable {
    public let apiVersion: String?
    public let sessionId: String
    public let command: String
    public let reason: String?
}

public struct SpeechEventResponsePayload: Codable, Sendable {
    public let event: SpeechSessionEvent
}

public struct SpeechEventsResponsePayload: Codable, Sendable {
    public let events: [SpeechSessionEvent]
}

public struct ConciergeCallStartPayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let deviceId: String?
    public let platform: String
    public let ttsMode: String?
    public let targetGatewayId: String?
    public let displayName: String?
    public let handoffContext: ConciergeCallHandoffContext?
    public let spaceId: String?
    public let spaceUid: String?
    public let targetAgentId: String?

    public init(
        apiVersion: String? = nil,
        callId: String,
        deviceId: String? = nil,
        platform: String,
        ttsMode: String? = nil,
        targetGatewayId: String? = nil,
        displayName: String? = nil,
        handoffContext: ConciergeCallHandoffContext? = nil,
        spaceId: String? = nil,
        spaceUid: String? = nil,
        targetAgentId: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.callId = callId
        self.deviceId = deviceId
        self.platform = platform
        self.ttsMode = ttsMode
        self.targetGatewayId = targetGatewayId
        self.displayName = displayName
        self.handoffContext = handoffContext
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.targetAgentId = targetAgentId
    }
}

public struct ConciergeCallAnswerPayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let deviceId: String?
    public let platform: String?

    public init(
        apiVersion: String? = nil,
        callId: String,
        deviceId: String? = nil,
        platform: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.callId = callId
        self.deviceId = deviceId
        self.platform = platform
    }
}

public struct ConciergeCallEndPayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let reason: String?

    public init(
        apiVersion: String? = nil,
        callId: String,
        reason: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.callId = callId
        self.reason = reason
    }
}

public struct ConciergeCallSetMutedPayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let muted: Bool

    public init(
        apiVersion: String? = nil,
        callId: String,
        muted: Bool
    ) {
        self.apiVersion = apiVersion
        self.callId = callId
        self.muted = muted
    }
}

public struct ConciergeCallAudioChunkPayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let sequence: Int
    public let audioBase64: String
    public let audioDurationSeconds: Double?
    public let sampleRateHz: Int?
    public let channels: Int?
    public let codec: String?
    public let transcriptText: String?
    public let isFinal: Bool?

    public init(
        apiVersion: String? = nil,
        callId: String,
        sequence: Int,
        audioBase64: String,
        audioDurationSeconds: Double? = nil,
        sampleRateHz: Int? = nil,
        channels: Int? = nil,
        codec: String? = nil,
        transcriptText: String? = nil,
        isFinal: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.callId = callId
        self.sequence = sequence
        self.audioBase64 = audioBase64
        self.audioDurationSeconds = audioDurationSeconds
        self.sampleRateHz = sampleRateHz
        self.channels = channels
        self.codec = codec
        self.transcriptText = transcriptText
        self.isFinal = isFinal
    }
}

public struct ConciergeCallControlPayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let command: String
    public let reason: String?

    public init(
        apiVersion: String? = nil,
        callId: String,
        command: String,
        reason: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.callId = callId
        self.command = command
        self.reason = reason
    }
}

public struct ConciergeCallHandoffPreparePayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let sourceDeviceId: String?
    public let destinationPlatform: String
    public let destinationDeviceId: String?
    public let destinationClientId: String?
    public let resumeUrl: String?
}

public struct ConciergeCallHandoffAcceptPayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let handoffToken: String
    public let deviceId: String?
    public let platform: String?
}

public struct ConciergeCallRegisterPushPayload: Codable, Sendable {
    public let apiVersion: String?
    public let deviceId: String?
    public let platform: String
    public let pushToken: String
    public let voipTopic: String?
    public let proactiveOptIn: Bool?
}

public struct ConciergeCallEventResponsePayload: Codable, Sendable {
    public let event: ConciergeCallEvent
}

public struct ConciergeCallEventsResponsePayload: Codable, Sendable {
    public let events: [ConciergeCallEvent]
}

public struct ConciergeCallHandoffPrepareResponsePayload: Codable, Sendable {
    public let event: ConciergeCallEvent
    public let handoffToken: ConciergeCallHandoffToken
}

public struct ConciergeCallRegisterPushResponsePayload: Codable, Sendable {
    public let registration: ConciergeVoipPushRegistration
}

// MARK: - Adapter Payloads

public enum AdapterCapabilityProviderSource: String, Codable, Sendable {
    case adapter
}

public struct AdapterCapabilityProvider: Codable, Sendable {
    public let id: String
    public let name: String
    public let source: AdapterCapabilityProviderSource
    public let capabilityType: String
    public let operations: [String]

    public init(
        id: String,
        name: String,
        source: AdapterCapabilityProviderSource = .adapter,
        capabilityType: String,
        operations: [String]
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.capabilityType = capabilityType
        self.operations = operations
    }
}

public struct CapabilitiesRegisterPayload: Codable, Sendable {
    public let providers: [AdapterCapabilityProvider]

    public init(providers: [AdapterCapabilityProvider]) {
        self.providers = providers
    }
}

public struct CapabilitiesDeregisterPayload: Codable, Sendable {
    public let providerIds: [String]

    public init(providerIds: [String]) {
        self.providerIds = providerIds
    }
}

public struct AdapterCapabilityInvokePayload: Codable, Sendable {
    public let invocationId: String
    public let capability: String
    public let operation: String
    public let args: [String: AnyCodable]
    public let targetProvider: String?

    public init(
        invocationId: String,
        capability: String,
        operation: String,
        args: [String: AnyCodable],
        targetProvider: String? = nil
    ) {
        self.invocationId = invocationId
        self.capability = capability
        self.operation = operation
        self.args = args
        self.targetProvider = targetProvider
    }
}

public struct CapabilityResultPayload: Codable, Sendable {
    public let invocationId: String
    public let providerId: String
    public let data: AnyCodable?
    public let durationMs: Double?

    public init(
        invocationId: String,
        providerId: String,
        data: Any? = nil,
        durationMs: Double? = nil
    ) {
        self.invocationId = invocationId
        self.providerId = providerId
        self.data = data.map(AnyCodable.init)
        self.durationMs = durationMs
    }

    public init(
        invocationId: String,
        providerId: String,
        dataCodable: AnyCodable?,
        durationMs: Double? = nil
    ) {
        self.invocationId = invocationId
        self.providerId = providerId
        self.data = dataCodable
        self.durationMs = durationMs
    }
}

public struct CapabilityErrorPayload: Codable, Sendable {
    public let invocationId: String
    public let providerId: String?
    public let code: String?
    public let message: String
    public let details: AnyCodable?

    public init(
        invocationId: String,
        providerId: String? = nil,
        code: String? = nil,
        message: String,
        details: Any? = nil
    ) {
        self.invocationId = invocationId
        self.providerId = providerId
        self.code = code
        self.message = message
        self.details = details.map(AnyCodable.init)
    }
}

// MARK: - Gateway → Client Payloads

public struct AuthChallengePayload: Codable, Sendable {
    public let challenge: String?
    public let success: Bool?
    public let reason: String?
}

public struct AuthResultPayload: Codable, Sendable {
    public let success: Bool
    public let reason: String?
}

public struct AppNavigatePayload: Codable, Sendable {
    public let destination: String
    public let gatewayId: String?
    public let spaceId: String?
    public let jobId: String?
    public let promptText: String?

    public init(
        destination: String,
        gatewayId: String? = nil,
        spaceId: String? = nil,
        jobId: String? = nil,
        promptText: String? = nil
    ) {
        self.destination = destination
        self.gatewayId = gatewayId
        self.spaceId = spaceId
        self.jobId = jobId
        self.promptText = promptText
    }
}

// MARK: - Inter-Agent Messaging Payloads

/// Send a message directly to a specific agent within a space.
public struct AgentMessagePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let fromAgentId: String
    /// Target agent ID. Use "*" for broadcast to all agents in the space.
    public let toAgentId: String
    public let content: String
    public let metadata: [String: AnyCodable]?

    public init(
        spaceId: String,
        spaceUid: String,
        fromAgentId: String,
        toAgentId: String,
        content: String,
        metadata: [String: Any]? = nil
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.fromAgentId = fromAgentId
        self.toAgentId = toAgentId
        self.content = content
        self.metadata = metadata?.mapValues { AnyCodable($0) }
    }
}

/// Notify an idle agent to resume work.
public struct AgentPokePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let targetAgentId: String
    public let reason: String
    public let unblockedByTurnId: String?

    public init(
        spaceId: String,
        spaceUid: String,
        targetAgentId: String,
        reason: String,
        unblockedByTurnId: String? = nil
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.targetAgentId = targetAgentId
        self.reason = reason
        self.unblockedByTurnId = unblockedByTurnId
    }
}

/// Agent idle notification from the gateway.
public struct AgentIdlePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let agentId: String
    public let idleDurationMs: Double
    public let lastTurnId: String?
}

/// Declare a dependency between tasks/turns within a space.
public struct TaskDependencyPayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let blockedTurnId: String
    public let dependsOnTurnId: String

    public init(
        spaceId: String,
        spaceUid: String,
        blockedTurnId: String,
        dependsOnTurnId: String
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.blockedTurnId = blockedTurnId
        self.dependsOnTurnId = dependsOnTurnId
    }
}

/// Gateway notification that a task dependency has been resolved.
public struct TaskDependencyResolvedPayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let unblockedTurnId: String
    public let resolvedByTurnId: String
}

// MARK: - Known Message Types

public enum MessageType {
    // Client → Gateway
    public static let authenticate = "authenticate"
    public static let executeTurn = "execute_turn"
    public static let cancelTurn = "cancel_turn"
    public static let resumeFeedback = "resume_feedback"
    public static let subscribe = "subscribe"
    public static let capabilityInvoke = "capability_invoke"
    public static let spaceCreate = "space.create"
    public static let spaceGet = "space.get"
    public static let spaceList = "space.list"
    public static let spaceArchive = "space.archive"
    public static let spaceDelete = "space.delete"
    public static let spaceUpdateMetadata = "space.update_metadata"
    public static let spaceAddAgent = "space.add_agent"
    public static let spaceRemoveAgent = "space.remove_agent"
    public static let spaceUpdateAgentAssignment = "space.update_agent_assignment"
    public static let spaceSetOrchestrator = "space.set_orchestrator"
    public static let spaceSetThinkingCapturePolicy = "space.set_thinking_capture_policy"
    public static let spaceGetMemoryPolicy = "space.get_memory_policy"
    public static let spaceSetMemoryPolicy = "space.set_memory_policy"
    public static let spaceEndIncognitoSession = "space.end_incognito_session"
    public static let spaceListAgentAssignments = "space.list_agent_assignments"
    public static let spaceGetMcpEndpoint = "space.get_mcp_endpoint"
    public static let spaceSetMcpEndpoint = "space.set_mcp_endpoint"
    public static let spaceClearMcpEndpoint = "space.clear_mcp_endpoint"
    public static let spaceDiscoverMcpAgents = "space.discover_mcp_agents"
    public static let spaceApproveMcpAgent = "space.approve_mcp_agent"
    public static let spaceAddSkill = "space.add_skill"
    public static let spaceRemoveSkill = "space.remove_skill"
    public static let spaceListSkills = "space.list_skills"
    public static let spaceGetWorkspace = "space.get_workspace"
    public static let spaceSetWorkspace = "space.set_workspace"
    public static let spaceOpenWorkspace = "space.open_workspace"
    public static let spaceAddResource = "space.add_resource"
    public static let spaceRemoveResource = "space.remove_resource"
    public static let spaceListResources = "space.list_resources"
    public static let spaceListTurns = "space.list_turns"
    public static let spaceListOrchestrationJournal = "space.list_orchestration_journal"
    public static let identityListAgentDefinitions = "identity.list_agent_definitions"
    public static let identityGetAgentDefinition = "identity.get_agent_definition"
    public static let identityCreateAgentDefinition = "identity.create_agent_definition"
    public static let identityUpdateAgentDefinition = "identity.update_agent_definition"
    public static let identityArchiveAgentDefinition = "identity.archive_agent_definition"
    public static let identityListPersonas = "identity.list_personas"
    public static let identityGetPersona = "identity.get_persona"
    public static let identityCreatePersona = "identity.create_persona"
    public static let identityUpdatePersona = "identity.update_persona"
    public static let identityArchivePersona = "identity.archive_persona"
    public static let identityPreviewCompiledInstructions = "identity.preview_compiled_instructions"
    public static let identityPreviewRuntimeSystemPrompt = "identity.preview_runtime_system_prompt"
    public static let identityPreviewSystemPromptMatrix = "identity.preview_system_prompt_matrix"
    public static let spaceListTemplates = "space.list_templates"
    public static let spaceGetTemplate = "space.get_template"
    public static let spacePreviewTemplate = "space.preview_template"
    public static let spaceCreateFromTemplate = "space.create_from_template"
    public static let spaceSaveTemplate = "space.save_template"
    public static let spaceArchiveTemplate = "space.archive_template"
    public static let spaceTemplateList = "space_template.list"
    public static let spaceTemplateGet = "space_template.get"
    public static let spaceTemplatePreview = "space_template.preview"
    public static let spaceTemplateCreateSpace = "space_template.create_space"
    public static let spaceTemplateSave = "space_template.save"
    public static let spaceTemplateArchive = "space_template.archive"
    public static let libraryListEntries = "library.list_entries"
    public static let libraryGetEntry = "library.get_entry"
    public static let librarySaveSkill = "library.save_skill"
    public static let libraryImportEntry = "library.import_entry"
    public static let libraryArchiveEntry = "library.archive_entry"
    public static let librarySetEntryEnabled = "library.set_entry_enabled"
    public static let libraryDeleteEntry = "library.delete_entry"
    public static let libraryScanEntries = "library.scan_entries"
    public static let libraryListSkillDrafts = "library.list_skill_drafts"
    public static let libraryGetSkillDraft = "library.get_skill_draft"
    public static let libraryCreateSkillDraft = "library.create_skill_draft"
    public static let libraryDeleteSkillDraft = "library.delete_skill_draft"
    public static let gatewayDiscoverLocalAgents = "gateway.discover_local_agents"
    public static let gatewayListProviderConfigs = "gateway.list_provider_configs"
    public static let gatewayGetRuntimeDefaults = "gateway.get_runtime_defaults"
    public static let gatewaySetRuntimeDefaults = "gateway.set_runtime_defaults"
    public static let gatewayGetMainAgent = "gateway.get_main_agent"
    public static let gatewaySetMainAgent = "gateway.set_main_agent"
    public static let gatewayGetConciergeAgent = "gateway.get_concierge_agent"
    public static let gatewaySetConciergeAgent = "gateway.set_concierge_agent"
    public static let gatewayListAvailableModels = "gateway.list_available_models"
    public static let gatewayListProviderCatalogs = "gateway.list_provider_catalogs"
    public static let gatewayListInterconnectors = "gateway.list_interconnectors"
    public static let gatewayRescanInterconnectors = "gateway.rescan_interconnectors"
    public static let toolList = "tool.list"
    public static let toolGet = "tool.get"
    public static let toolScaffold = "tool.scaffold"
    public static let toolRegister = "tool.register"
    public static let toolRemove = "tool.remove"
    public static let toolSetEnabled = "tool.set_enabled"
    public static let toolRescanJira = "tool.rescan_jira"
    public static let toolListGrants = "tool.list_grants"
    public static let toolRevokeGrant = "tool.revoke_grant"
    public static let gatewayGetProviderTelemetry = "gateway.get_provider_telemetry"
    public static let gatewayGetLocalUsageTelemetry = "gateway.get_local_usage_telemetry"
    public static let gatewayGetWorkspaceDefaults = "gateway.get_workspace_defaults"
    public static let gatewaySetWorkspaceDefaults = "gateway.set_workspace_defaults"
    public static let gatewayGetMemoryDefaults = "gateway.get_memory_defaults"
    public static let gatewaySetMemoryDefaults = "gateway.set_memory_defaults"
    public static let gatewayGetExternalConnectivity = "gateway.get_external_connectivity"
    public static let gatewaySetExternalConnectivity = "gateway.set_external_connectivity"
    public static let gatewayGetProviderSettings = "gateway.get_provider_settings"
    public static let gatewayUpdateProviderSettings = "gateway.update_provider_settings"
    public static let gatewaySetProviderConfig = "gateway.set_provider_config"
    public static let gatewayRemoveProviderConfig = "gateway.remove_provider_config"
    public static let gatewayFactoryReset = "gateway.factory_reset"
    public static let gatewayProvisionLocalProfile = "gateway.provision_local_profile"
    public static let gatewayPutSecretRef = "gateway.put_secret_ref"
    public static let gatewayListSecretRefs = "gateway.list_secret_refs"
    public static let gatewayDeleteSecretRef = "gateway.delete_secret_ref"
    public static let gatewayGetIntegrationsSnapshot = "gateway.get_integrations_snapshot"
    public static let gatewayListConnectorFamilies = "gateway.list_connector_families"
    public static let gatewayListConnectors = "gateway.list_connectors"
    public static let gatewayUpsertConnector = "gateway.upsert_connector"
    public static let gatewayRemoveConnector = "gateway.remove_connector"
    public static let connectorSubmitInboundEvent = "connector.submit_inbound_event"
    public static let connectorInboundEventResult = "connector.inbound_event_result"
    public static let gatewayListConnectorBindings = "gateway.list_connector_bindings"
    public static let gatewayUpsertConnectorBinding = "gateway.upsert_connector_binding"
    public static let gatewayRemoveConnectorBinding = "gateway.remove_connector_binding"
    public static let gatewayGetConnectorPolicy = "gateway.get_connector_policy"
    public static let gatewayUpdateConnectorPolicy = "gateway.update_connector_policy"
    public static let gatewayGetToolPolicy = "gateway.get_tool_policy"
    public static let gatewayUpdateToolPolicy = "gateway.update_tool_policy"
    public static let gatewayListSafetyProfiles = "gateway.list_safety_profiles"
    public static let gatewayTestConnector = "gateway.test_connector"
    public static let gatewayGetPolicy = "gateway.get_policy"
    public static let gatewayUpdatePolicy = "gateway.update_policy"
    public static let gatewayKbListEntries = "gateway.kb_list_entries"
    public static let gatewayKbUpsertEntry = "gateway.kb_upsert_entry"
    public static let gatewayKbDeleteEntry = "gateway.kb_delete_entry"
    public static let gatewaySkillList = "gateway.skill_list"
    public static let gatewayListCapabilityGrants = "gateway.list_capability_grants"
    public static let gatewayGrantCapability = "gateway.grant_capability"
    public static let gatewayRevokeCapability = "gateway.revoke_capability"
    public static let usageGetSnapshot = "usage.get_snapshot"
    public static let schedulerCreateJob = "scheduler.create_job"
    public static let schedulerGetJob = "scheduler.get_job"
    public static let schedulerListJobs = "scheduler.list_jobs"
    public static let schedulerListEvalDefinitions = "scheduler.list_eval_definitions"
    public static let schedulerUpdateJob = "scheduler.update_job"
    public static let schedulerDeleteJob = "scheduler.delete_job"
    public static let schedulerLinkSpace = "scheduler.link_space"
    public static let schedulerUnlinkSpace = "scheduler.unlink_space"
    public static let schedulerListRuns = "scheduler.list_runs"
    public static let schedulerRunNow = "scheduler.run_now"
    public static let workbenchListQueue = "workbench.list_queue"
    public static let workbenchGetQueueItem = "workbench.get_queue_item"
    public static let workbenchCreateBatch = "workbench.create_batch"
    public static let workbenchListBatches = "workbench.list_batches"
    public static let workbenchUpdateBatch = "workbench.update_batch"
    public static let workbenchStartRun = "workbench.start_run"
    public static let workbenchRetryRun = "workbench.retry_run"
    public static let workbenchCancelRun = "workbench.cancel_run"
    public static let workbenchListRuns = "workbench.list_runs"
    public static let workbenchGetRun = "workbench.get_run"
    public static let workbenchApproveStage = "workbench.approve_stage"
    public static let workbenchRejectStage = "workbench.reject_stage"
    public static let workbenchSetMode = "workbench.set_mode"
    public static let workbenchListArtifacts = "workbench.list_artifacts"
    public static let workbenchGetPolicy = "workbench.get_policy"
    public static let workbenchUpdatePolicy = "workbench.update_policy"
    public static let orchestratorCommand = "orchestrator.command"
    public static let orchestratorGetCommand = "orchestrator.get_command"
    public static let spaceLink = "space.link"
    public static let spaceUnlink = "space.unlink"
    public static let spaceShareContext = "space.share_context"
    public static let spaceShareCreateInvite = "space.share_create_invite"
    public static let spaceShareJoin = "space.share_join"
    public static let spaceShareRevoke = "space.share_revoke"
    public static let spaceShareListParticipants = "space.share_list_participants"
    public static let spaceCreateChangeset = "space.create_changeset"
    public static let spaceListChangesets = "space.list_changesets"
    public static let spaceUploadChangesetFileInit = "space.upload_changeset_file_init"
    public static let spaceUploadChangesetFileComplete = "space.upload_changeset_file_complete"
    public static let spaceSubmitChangeset = "space.submit_changeset"
    public static let spaceReviewChangeset = "space.review_changeset"
    public static let spaceApplyChangeset = "space.apply_changeset"
    public static let spaceGetChangesetDiff = "space.get_changeset_diff"
    public static let spaceGetQuota = "space.get_quota"
    public static let spaceUpdateQuotaPolicy = "space.update_quota_policy"
    public static let spaceGetUsage = "space.get_usage"
    public static let spaceListActivityLog = "space.list_activity_log"
    public static let spaceGetTurnTrace = "space.get_turn_trace"
    public static let spaceListArtifacts = "space.list_artifacts"
    public static let spaceGetArtifact = "space.get_artifact"
    public static let spaceGetDebugArtifact = "space.get_debug_artifact"
    public static let spaceListExperiences = "space.list_experiences"
    public static let spaceGetExperience = "space.get_experience"
    public static let spaceListInsights = "space.list_insights"
    public static let spaceGetInsight = "space.get_insight"
    public static let spaceAcceptInsight = "space.accept_insight"
    public static let spaceRejectInsight = "space.reject_insight"
    public static let spaceDismissInsight = "space.dismiss_insight"
    public static let spaceGetSpaceAgentNotes = "space.get_space_agent_notes"
    public static let spaceUpdateSpaceAgentNotes = "space.update_space_agent_notes"
    public static let spaceGetUserProfile = "space.get_user_profile"
    public static let spaceUpdateUserProfile = "space.update_user_profile"
    public static let spaceListMemories = "space.list_memories"
    public static let spaceDeleteMemory = "space.delete_memory"
    public static let spaceUpdateMemoryImportance = "space.update_memory_importance"
    public static let spaceReset = "space.reset"
    public static let spaceResetAgentUsageSession = "space.reset_agent_usage_session"
    public static let spaceGetEffectiveTools = "space.get_effective_tools"
    public static let spaceGetEffectiveToolAccess = "space.get_effective_tool_access"
    public static let spaceGetToolPolicy = "space.get_tool_policy"
    public static let spaceUpdateToolPolicy = "space.update_tool_policy"
    public static let spaceGetConnectorPolicy = "space.get_connector_policy"
    public static let spaceUpdateConnectorPolicy = "space.update_connector_policy"
    public static let authRegisterDevice = "auth.register_device"
    public static let authRotateDeviceKey = "auth.rotate_device_key"
    public static let authRevokeDevice = "auth.revoke_device"
    public static let authListDevices = "auth.list_devices"
    public static let authIssueHttpPrincipalToken = "auth.issue_http_principal_token"
    public static let spacePullSharedContext = "space.pull_shared_context"
    public static let syncAnnounce = "sync.announce"
    public static let syncQueryResources = "sync.query_resources"
    public static let syncPullResources = "sync.pull_resources"
    public static let speechStart = "speech.start"
    public static let speechAudioChunk = "speech.audio_chunk"
    public static let speechControl = "speech.control"
    public static let conciergeCallStart = "concierge.call.start"
    public static let conciergeCallAnswer = "concierge.call.answer"
    public static let conciergeCallEnd = "concierge.call.end"
    public static let conciergeCallSetMuted = "concierge.call.set_muted"
    public static let conciergeCallAudioChunk = "concierge.call.audio_chunk"
    public static let conciergeCallControl = "concierge.call.control"
    public static let conciergeCallHandoffPrepare = "concierge.call.handoff.prepare"
    public static let conciergeCallHandoffAccept = "concierge.call.handoff.accept"
    public static let conciergeCallRegisterPush = "concierge.call.register_push"
    public static let ping = "ping"

    // Adapter ↔ Gateway
    public static let capabilitiesRegister = "capabilities.register"
    public static let capabilitiesDeregister = "capabilities.deregister"
    public static let capabilityInvokeAdapter = "capability.invoke"
    public static let capabilityResult = "capability.result"
    public static let capabilityError = "capability.error"

    // Gateway → Client
    public static let authChallenge = "auth_challenge"
    public static let authResult = "auth_result"
    public static let turnEvent = "turn_event"
    public static let turnStream = "turn_stream"
    public static let spaceState = "space_state"
    public static let spaceAgentUpdated = "space.agent_updated"
    public static let notification = "notification"
    public static let appNavigate = "app.navigate"
    public static let appConciergeActionRequest = "app.concierge_action_request"
    public static let orchestratorEvent = "orchestrator.event"
    public static let speechEvent = "speech.event"
    public static let conciergeCallEvent = "concierge.call.event"
    public static let error = "error"
    public static let pong = "pong"

    // Notifications
    public static let subscribeNotifications = "subscribe_notifications"
    public static let unsubscribeNotifications = "unsubscribe_notifications"
    public static let conciergeActionResult = "concierge.action_result"

    // Inter-Agent Messaging
    public static let agentMessage = "agent_message"
    public static let agentPoke = "agent_poke"
    public static let agentIdle = "agent_idle"

    // Task Dependencies
    public static let taskDependency = "task_dependency"
    public static let taskDependencyResolved = "task_dependency_resolved"
}

// MARK: - Raw Message (for initial parsing)

/// Partially-decoded message for type discrimination.
struct RawGatewayMessage: Codable {
    let type: String
    let id: String
    let replyTo: String?
    let ts: String
    let payload: AnyCodable?
}

/// Lightweight message envelope for routing — skips payload decode.
struct MessageEnvelope: Codable {
    let type: String
    let id: String
    let replyTo: String?
}
