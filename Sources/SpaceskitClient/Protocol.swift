// Protocol.swift — WebSocket compatibility types mirroring server/protocol.ts.
// Canonical cross-process contracts now live in /proto and this file remains
// the legacy JSON transport surface until generated Swift contracts replace it.

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

    public init(spaceUid: String, input: String, targetAgentId: String? = nil) {
        self.spaceUid = spaceUid
        self.input = input
        self.targetAgentId = targetAgentId
    }
}

public struct ResumeFeedbackPayload: Codable, Sendable {
    public let spaceUid: String
    public let turnId: String
    public let response: String
    public let revision: String?

    public init(spaceUid: String, turnId: String, response: FeedbackResponse, revision: String? = nil) {
        self.spaceUid = spaceUid
        self.turnId = turnId
        self.response = response.rawValue
        self.revision = revision
    }
}

public struct SubscribePayload: Codable, Sendable {
    public let spaceUids: [String]
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
    public let turnModel: String?
    public let templateId: String?
    public let templateRevision: Int?
    public let capabilities: [String]?
    public let capabilityOverrides: [String: String]?
    public let visibility: String?
    public let turnModelConfig: [String: AnyCodable]?
    public let maxTurns: Int?
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
        turnModel: String? = nil,
        templateId: String? = nil,
        templateRevision: Int? = nil,
        capabilities: [String]? = nil,
        capabilityOverrides: [String: String]? = nil,
        visibility: String? = nil,
        turnModelConfig: [String: Any]? = nil,
        maxTurns: Int? = nil,
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
        self.turnModel = turnModel
        self.templateId = templateId
        self.templateRevision = templateRevision
        self.capabilities = capabilities
        self.capabilityOverrides = capabilityOverrides
        self.visibility = visibility
        self.turnModelConfig = turnModelConfig?.mapValues { AnyCodable($0) }
        self.maxTurns = maxTurns
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

public struct SpaceAddAgentPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let agentId: String
    public let profileId: String
    public let securityScope: [String: AnyCodable]?
    public let spawnContext: String?
    public let contextOverrides: [String: AnyCodable]?
    public let role: String?
    public let turnOrder: Int?
    public let isPrimary: Bool?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        agentId: String,
        profileId: String,
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
        self.profileId = profileId
        self.securityScope = securityScope?.mapValues { AnyCodable($0) }
        self.spawnContext = spawnContext
        self.contextOverrides = contextOverrides?.mapValues { AnyCodable($0) }
        self.role = role
        self.turnOrder = turnOrder
        self.isPrimary = isPrimary
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
    public let profileId: String?
    public let securityScope: [String: AnyCodable]?
    public let spawnContext: String?
    public let contextOverrides: [String: AnyCodable]?
    public let role: String?
    public let turnOrder: Int?
    public let isPrimary: Bool?
    public let resetSession: Bool?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        agentId: String,
        profileId: String? = nil,
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
        self.profileId = profileId
        self.securityScope = securityScope?.mapValues { AnyCodable($0) }
        self.spawnContext = spawnContext
        self.contextOverrides = contextOverrides?.mapValues { AnyCodable($0) }
        self.role = role
        self.turnOrder = turnOrder
        self.isPrimary = isPrimary
        self.resetSession = resetSession
    }
}

public struct SpaceSetOrchestratorPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let profileId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        profileId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.profileId = profileId
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

public struct ProfileCreatePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let profileId: String?
    public let name: String
    public let description: String?
    public let personalityPrompt: String?
    public let defaultSkillIds: [String]?
    public let providerHint: String?
    public let modelHint: String?
    public let modelConfig: ProfileModelConfig?
    public let canModerate: Bool?
    public let isDefault: Bool?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        profileId: String? = nil,
        name: String,
        description: String? = nil,
        personalityPrompt: String? = nil,
        defaultSkillIds: [String]? = nil,
        providerHint: String? = nil,
        modelHint: String? = nil,
        modelConfig: ProfileModelConfig? = nil,
        canModerate: Bool? = nil,
        isDefault: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.profileId = profileId
        self.name = name
        self.description = description
        self.personalityPrompt = personalityPrompt
        self.defaultSkillIds = defaultSkillIds
        self.providerHint = providerHint
        self.modelHint = modelHint
        self.modelConfig = modelConfig
        self.canModerate = canModerate
        self.isDefault = isDefault
    }
}

public struct ProfileGetPayload: Codable, Sendable {
    public let apiVersion: String?
    public let profileId: String

    public init(apiVersion: String? = nil, profileId: String) {
        self.apiVersion = apiVersion
        self.profileId = profileId
    }
}

public struct ProfileListPayload: Codable, Sendable {
    public let apiVersion: String?
    public let includeArchived: Bool?

    public init(apiVersion: String? = nil, includeArchived: Bool? = nil) {
        self.apiVersion = apiVersion
        self.includeArchived = includeArchived
    }
}

public struct ProfileUpdatePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let profileId: String
    public let name: String?
    public let description: String?
    public let personalityPrompt: String?
    public let defaultSkillIds: [String]?
    public let providerHint: String?
    public let modelHint: String?
    public let modelConfig: ProfileModelConfig?
    public let canModerate: Bool?
    public let isDefault: Bool?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        profileId: String,
        name: String? = nil,
        description: String? = nil,
        personalityPrompt: String? = nil,
        defaultSkillIds: [String]? = nil,
        providerHint: String? = nil,
        modelHint: String? = nil,
        modelConfig: ProfileModelConfig? = nil,
        canModerate: Bool? = nil,
        isDefault: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.profileId = profileId
        self.name = name
        self.description = description
        self.personalityPrompt = personalityPrompt
        self.defaultSkillIds = defaultSkillIds
        self.providerHint = providerHint
        self.modelHint = modelHint
        self.modelConfig = modelConfig
        self.canModerate = canModerate
        self.isDefault = isDefault
    }
}

public struct ProfileArchivePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let profileId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        profileId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.profileId = profileId
    }
}

public struct PresetListPayload: Codable, Sendable {
    public let apiVersion: String?
    public let kind: String?
    public let source: String?
    public let tags: [String]?

    public init(
        apiVersion: String? = nil,
        kind: String? = nil,
        source: String? = nil,
        tags: [String]? = nil
    ) {
        self.apiVersion = apiVersion
        self.kind = kind
        self.source = source
        self.tags = tags
    }
}

public struct PresetGetPayload: Codable, Sendable {
    public let apiVersion: String?
    public let presetId: String

    public init(apiVersion: String? = nil, presetId: String) {
        self.apiVersion = apiVersion
        self.presetId = presetId
    }
}

public struct PresetApplyToSpacePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let presetId: String
    public let targetSpaceId: String?
    public let spaceId: String?
    public let resourceId: String?
    public let name: String?
    public let goal: String?
    public let workspaceRoot: String?
    public let visibility: String?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        presetId: String,
        targetSpaceId: String? = nil,
        spaceId: String? = nil,
        resourceId: String? = nil,
        name: String? = nil,
        goal: String? = nil,
        workspaceRoot: String? = nil,
        visibility: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.presetId = presetId
        self.targetSpaceId = targetSpaceId
        self.spaceId = spaceId
        self.resourceId = resourceId
        self.name = name
        self.goal = goal
        self.workspaceRoot = workspaceRoot
        self.visibility = visibility
    }
}

public struct PresetSaveAgentPayload: Codable, Sendable {
    public let apiVersion: String?
    public let presetId: String?
    public let title: String
    public let description: String?
    public let defaultAgents: [TemplateAgentDefinition]?
    public let tags: [String]?

    public init(
        apiVersion: String? = nil,
        presetId: String? = nil,
        title: String,
        description: String? = nil,
        defaultAgents: [TemplateAgentDefinition]? = nil,
        tags: [String]? = nil
    ) {
        self.apiVersion = apiVersion
        self.presetId = presetId
        self.title = title
        self.description = description
        self.defaultAgents = defaultAgents
        self.tags = tags
    }
}

public struct PresetArchiveAgentPayload: Codable, Sendable {
    public let apiVersion: String?
    public let presetId: String

    public init(apiVersion: String? = nil, presetId: String) {
        self.apiVersion = apiVersion
        self.presetId = presetId
    }
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
        self.baseAgents = baseAgents
        self.agentPresetIds = agentPresetIds
        self.sourceSpaceId = sourceSpaceId
        self.tags = tags
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
    public let sourceProfileId: String?
    public let copyPersonality: Bool?

    public init(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        selectionMode: MainAgentSelectionMode,
        providerId: String? = nil,
        modelId: String? = nil,
        sourceProfileId: String? = nil,
        copyPersonality: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.selectionMode = selectionMode
        self.providerId = providerId
        self.modelId = modelId
        self.sourceProfileId = sourceProfileId
        self.copyPersonality = copyPersonality
    }
}

public struct GatewayListAvailableModelsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String?

    public init(apiVersion: String? = nil, providerId: String? = nil) {
        self.apiVersion = apiVersion
        self.providerId = providerId
    }
}

public struct GatewayListProviderCatalogsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String?

    public init(apiVersion: String? = nil, providerId: String? = nil) {
        self.apiVersion = apiVersion
        self.providerId = providerId
    }
}

public struct GatewayCreateIntegrationRequestPayload: Codable, Sendable {
    public let apiVersion: String?
    public let integrationClass: GatewayIntegrationClass
    public let requestedName: String
    public let useCase: String?
    public let sourceURL: String?
    public let notes: String?

    public init(
        apiVersion: String? = nil,
        integrationClass: GatewayIntegrationClass,
        requestedName: String,
        useCase: String? = nil,
        sourceURL: String? = nil,
        notes: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.integrationClass = integrationClass
        self.requestedName = requestedName
        self.useCase = useCase
        self.sourceURL = sourceURL
        self.notes = notes
    }
}

public struct GatewayListIntegrationRequestsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let integrationClass: GatewayIntegrationClass?
    public let limit: Int?

    public init(
        apiVersion: String? = nil,
        integrationClass: GatewayIntegrationClass? = nil,
        limit: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.integrationClass = integrationClass
        self.limit = limit
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

    public init(apiVersion: String? = nil, providerId: String? = nil) {
        self.apiVersion = apiVersion
        self.providerId = providerId
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
    public let baseURL: String?
    public let allowedModels: [String]?
    public let allowCustomModel: Bool?
    public let nativeCliToolsEnabled: Bool?

    public init(
        apiVersion: String? = nil,
        providerId: String,
        model: String? = nil,
        apiKey: String? = nil,
        apiKeySecretRef: String? = nil,
        baseURL: String? = nil,
        allowedModels: [String]? = nil,
        allowCustomModel: Bool? = nil,
        nativeCliToolsEnabled: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.providerId = providerId
        self.model = model
        self.apiKey = apiKey
        self.apiKeySecretRef = apiKeySecretRef
        self.baseURL = baseURL
        self.allowedModels = allowedModels
        self.allowCustomModel = allowCustomModel
        self.nativeCliToolsEnabled = nativeCliToolsEnabled
    }
}

public struct GatewayUpdateProviderSettingsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String
    public let model: String?
    public let apiKey: String?
    public let apiKeySecretRef: String?
    public let baseURL: String?
    public let allowedModels: [String]?
    public let allowCustomModel: Bool?
    public let nativeCliToolsEnabled: Bool?

    public init(
        apiVersion: String? = nil,
        providerId: String,
        model: String? = nil,
        apiKey: String? = nil,
        apiKeySecretRef: String? = nil,
        baseURL: String? = nil,
        allowedModels: [String]? = nil,
        allowCustomModel: Bool? = nil,
        nativeCliToolsEnabled: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.providerId = providerId
        self.model = model
        self.apiKey = apiKey
        self.apiKeySecretRef = apiKeySecretRef
        self.baseURL = baseURL
        self.allowedModels = allowedModels
        self.allowCustomModel = allowCustomModel
        self.nativeCliToolsEnabled = nativeCliToolsEnabled
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
}

public struct SpaceGetResponsePayload: Codable, Sendable {
    public let space: SpaceConfig
}

public struct SpaceListResponsePayload: Codable, Sendable {
    public let spaces: [SpaceConfig]
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

public struct SpaceListAgentAssignmentsResponsePayload: Codable, Sendable {
    public let assignments: [SpaceAgentAssignment]
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

public struct ProfileCreateResponsePayload: Codable, Sendable {
    public let profile: ProfileSummary
    public let created: Bool
}

public struct ProfileGetResponsePayload: Codable, Sendable {
    public let profile: ProfileSummary
}

public struct ProfileListResponsePayload: Codable, Sendable {
    public let profiles: [ProfileSummary]
}

public struct ProfileUpdateResponsePayload: Codable, Sendable {
    public let profile: ProfileSummary
    public let newRevision: Int
}

public struct ProfileArchiveResponsePayload: Codable, Sendable {
    public let profile: ProfileSummary
    public let archived: Bool
}

public struct PresetListResponsePayload: Codable, Sendable {
    public let presets: [PresetSummary]
}

public struct PresetGetResponsePayload: Codable, Sendable {
    public let preset: PresetDetail
}

public typealias PresetApplyToSpaceResultPayload = PresetApplyToSpaceResult
public typealias PresetSaveAgentResponsePayload = PresetSaveAgentResult
public typealias PresetArchiveAgentResponsePayload = PresetArchiveAgentResult

public struct SpacePreviewTemplateResponsePayload: Codable, Sendable {
    public let template: SpaceTemplateSummary
    public let resolved: SpaceTemplatePreviewResolved
    public let warnings: [String]
}

public typealias SpaceCreateFromTemplateResultPayload = SpaceCreateFromTemplateResult
public typealias SpaceSaveTemplateResultPayload = SpaceSaveTemplateResult

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

public struct GatewayGetMainAgentResponsePayload: Codable, Sendable {
    public let state: GatewayMainAgentState
}

public struct GatewaySetMainAgentResponsePayload: Codable, Sendable {
    public let state: GatewayMainAgentState
}

public struct GatewayListAvailableModelsResponsePayload: Codable, Sendable {
    public let providers: [GatewayModelProviderCatalog]
    public let generatedAt: String
}

public struct GatewayListProviderCatalogsResponsePayload: Codable, Sendable {
    public let providers: [GatewayModelProviderCatalog]
    public let generatedAt: String
}

public struct GatewayCreateIntegrationRequestResponsePayload: Codable, Sendable {
    public let request: GatewayIntegrationRequest
}

public struct GatewayListIntegrationRequestsResponsePayload: Codable, Sendable {
    public let requests: [GatewayIntegrationRequest]
}

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

public struct GatewaySkillListResponsePayload: Codable, Sendable {
    public let skills: [GatewaySkillEntry]
}

public struct GatewaySkillGetPayload: Codable, Sendable {
    public let apiVersion: String?
    public let skillId: String

    public init(apiVersion: String? = nil, skillId: String) {
        self.apiVersion = apiVersion
        self.skillId = skillId
    }
}

public struct GatewaySkillGetResponsePayload: Codable, Sendable {
    public let skill: GatewaySkillEntry
}

public struct GatewaySkillUpsertPayload: Codable, Sendable {
    public let apiVersion: String?
    public let skillId: String?
    public let name: String
    public let description: String?
    public let contentMarkdown: String
    public let sourceRef: String?
    public let tags: [String]?
    public let status: GatewaySkillStatus?

    public init(
        apiVersion: String? = nil,
        skillId: String? = nil,
        name: String,
        description: String? = nil,
        contentMarkdown: String,
        sourceRef: String? = nil,
        tags: [String]? = nil,
        status: GatewaySkillStatus? = nil
    ) {
        self.apiVersion = apiVersion
        self.skillId = skillId
        self.name = name
        self.description = description
        self.contentMarkdown = contentMarkdown
        self.sourceRef = sourceRef
        self.tags = tags
        self.status = status
    }
}

public typealias GatewaySkillUpsertResponsePayload = GatewaySkillUpsertResult

public struct GatewaySkillDeletePayload: Codable, Sendable {
    public let apiVersion: String?
    public let skillId: String

    public init(apiVersion: String? = nil, skillId: String) {
        self.apiVersion = apiVersion
        self.skillId = skillId
    }
}

public typealias GatewaySkillDeleteResponsePayload = GatewaySkillDeleteResult

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

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        name: String,
        timezone: String,
        schedulePreset: SchedulerSchedulePreset,
        action: SchedulerAction,
        primarySpaceId: String,
        relatedSpaceIds: [String]? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.name = name
        self.timezone = timezone
        self.schedulePreset = schedulePreset
        self.action = action
        self.primarySpaceId = primarySpaceId
        self.relatedSpaceIds = relatedSpaceIds
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
        relatedSpaceIds: [String]? = nil
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

public struct SpeechStartPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let spaceUid: String
    public let sessionId: String?
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
}

public struct SpeechAudioChunkPayload: Codable, Sendable {
    public let apiVersion: String?
    public let sessionId: String
    public let sequence: Int
    public let audioBase64: String
    public let audioDurationSeconds: Double?
    public let ttsChars: Int?
    public let ttsSeconds: Double?
    public let transcriptText: String?
    public let isFinal: Bool?
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
    public static let resumeFeedback = "resume_feedback"
    public static let subscribe = "subscribe"
    public static let capabilityInvoke = "capability_invoke"
    public static let spaceCreate = "space.create"
    public static let spaceGet = "space.get"
    public static let spaceList = "space.list"
    public static let spaceAddAgent = "space.add_agent"
    public static let spaceRemoveAgent = "space.remove_agent"
    public static let spaceUpdateAgentAssignment = "space.update_agent_assignment"
    public static let spaceSetOrchestrator = "space.set_orchestrator"
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
    public static let spaceAddResource = "space.add_resource"
    public static let spaceRemoveResource = "space.remove_resource"
    public static let spaceListResources = "space.list_resources"
    public static let spaceListTurns = "space.list_turns"
    public static let spaceListOrchestrationJournal = "space.list_orchestration_journal"
    public static let profileCreate = "profile.create"
    public static let profileGet = "profile.get"
    public static let profileList = "profile.list"
    public static let profileUpdate = "profile.update"
    public static let profileArchive = "profile.archive"
    public static let presetList = "preset.list"
    public static let presetGet = "preset.get"
    public static let presetApplyToSpace = "preset.apply_to_space"
    public static let presetSaveAgent = "preset.save_agent"
    public static let presetArchiveAgent = "preset.archive_agent"
    public static let spacePreviewTemplate = "space.preview_template"
    public static let spaceCreateFromTemplate = "space.create_from_template"
    public static let spaceSaveTemplate = "space.save_template"
    public static let gatewayDiscoverLocalAgents = "gateway.discover_local_agents"
    public static let gatewayListProviderConfigs = "gateway.list_provider_configs"
    public static let gatewayGetMainAgent = "gateway.get_main_agent"
    public static let gatewaySetMainAgent = "gateway.set_main_agent"
    public static let gatewayListAvailableModels = "gateway.list_available_models"
    public static let gatewayListProviderCatalogs = "gateway.list_provider_catalogs"
    public static let gatewayCreateIntegrationRequest = "gateway.create_integration_request"
    public static let gatewayListIntegrationRequests = "gateway.list_integration_requests"
    public static let gatewayGetProviderTelemetry = "gateway.get_provider_telemetry"
    public static let gatewayGetLocalUsageTelemetry = "gateway.get_local_usage_telemetry"
    public static let gatewayGetProviderSettings = "gateway.get_provider_settings"
    public static let gatewayUpdateProviderSettings = "gateway.update_provider_settings"
    public static let gatewaySetProviderConfig = "gateway.set_provider_config"
    public static let gatewayRemoveProviderConfig = "gateway.remove_provider_config"
    public static let gatewayFactoryReset = "gateway.factory_reset"
    public static let gatewayProvisionLocalProfile = "gateway.provision_local_profile"
    public static let gatewayPutSecretRef = "gateway.put_secret_ref"
    public static let gatewayListSecretRefs = "gateway.list_secret_refs"
    public static let gatewayDeleteSecretRef = "gateway.delete_secret_ref"
    public static let gatewayListConnectorFamilies = "gateway.list_connector_families"
    public static let gatewayListConnectors = "gateway.list_connectors"
    public static let gatewayUpsertConnector = "gateway.upsert_connector"
    public static let gatewayRemoveConnector = "gateway.remove_connector"
    public static let gatewayListConnectorBindings = "gateway.list_connector_bindings"
    public static let gatewayUpsertConnectorBinding = "gateway.upsert_connector_binding"
    public static let gatewayRemoveConnectorBinding = "gateway.remove_connector_binding"
    public static let gatewayGetConnectorPolicy = "gateway.get_connector_policy"
    public static let gatewayUpdateConnectorPolicy = "gateway.update_connector_policy"
    public static let gatewayTestConnector = "gateway.test_connector"
    public static let gatewayGetPolicy = "gateway.get_policy"
    public static let gatewayUpdatePolicy = "gateway.update_policy"
    public static let gatewaySkillList = "gateway.skill_list"
    public static let gatewaySkillGet = "gateway.skill_get"
    public static let gatewaySkillUpsert = "gateway.skill_upsert"
    public static let gatewaySkillDelete = "gateway.skill_delete"
    public static let gatewayKbListEntries = "gateway.kb_list_entries"
    public static let gatewayKbUpsertEntry = "gateway.kb_upsert_entry"
    public static let gatewayKbDeleteEntry = "gateway.kb_delete_entry"
    public static let gatewayListCapabilityGrants = "gateway.list_capability_grants"
    public static let gatewayGrantCapability = "gateway.grant_capability"
    public static let gatewayRevokeCapability = "gateway.revoke_capability"
    public static let usageGetSnapshot = "usage.get_snapshot"
    public static let schedulerCreateJob = "scheduler.create_job"
    public static let schedulerGetJob = "scheduler.get_job"
    public static let schedulerListJobs = "scheduler.list_jobs"
    public static let schedulerUpdateJob = "scheduler.update_job"
    public static let schedulerDeleteJob = "scheduler.delete_job"
    public static let schedulerLinkSpace = "scheduler.link_space"
    public static let schedulerUnlinkSpace = "scheduler.unlink_space"
    public static let schedulerListRuns = "scheduler.list_runs"
    public static let schedulerRunNow = "scheduler.run_now"
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
    public static let spaceGetTurnTrace = "space.get_turn_trace"
    public static let spaceListArtifacts = "space.list_artifacts"
    public static let spaceGetArtifact = "space.get_artifact"
    public static let spaceReset = "space.reset"
    public static let spaceResetAgentUsageSession = "space.reset_agent_usage_session"
    public static let spaceGetEffectiveTools = "space.get_effective_tools"
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
    public static let orchestratorEvent = "orchestrator.event"
    public static let speechEvent = "speech.event"
    public static let error = "error"
    public static let pong = "pong"

    // Notifications
    public static let subscribeNotifications = "subscribe_notifications"
    public static let unsubscribeNotifications = "unsubscribe_notifications"

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
