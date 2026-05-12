// IdentityProtocolPayloads.swift - Identity and system prompt preview payloads.

import Foundation

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
