// SpaceTemplateProtocolPayloads.swift - Space template payloads.

import Foundation

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
