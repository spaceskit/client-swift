// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Identity Runtime

public struct ProfileModelConfig: Codable, Sendable {
    public let preferredModels: [String]
    public let fallbackModels: [String]?
    public let constraints: [String: AnyCodable]?

    public init(
        preferredModels: [String],
        fallbackModels: [String]? = nil,
        constraints: [String: Any]? = nil
    ) {
        self.preferredModels = preferredModels
        self.fallbackModels = fallbackModels
        self.constraints = constraints?.mapValues { AnyCodable($0) }
    }
}

public enum ManagedRecordStatus: String, Codable, Sendable {
    case active
    case archived
}

public struct AgentDefinitionSummary: Codable, Sendable {
    public let agentDefinitionId: String
    public let personaId: String?
    public let name: String
    public let description: String
    public let instructions: String
    public let defaultSkillIds: [String]
    public let providerHint: String?
    public let modelConfig: ProfileModelConfig?
    public let isDefault: Bool
    public let status: ManagedRecordStatus
    public let activeRevision: Int
    public let source: String
    public let createdAt: String
    public let updatedAt: String
}

public struct AgentDefinitionCreateResult: Codable, Sendable {
    public let agentDefinition: AgentDefinitionSummary
    public let created: Bool
}

public struct AgentDefinitionUpdateResult: Codable, Sendable {
    public let agentDefinition: AgentDefinitionSummary
    public let newRevision: Int
}

public struct AgentDefinitionArchiveResult: Codable, Sendable {
    public let agentDefinition: AgentDefinitionSummary
    public let archived: Bool
}

public struct PersonaSummary: Codable, Sendable {
    public let personaId: String
    public let name: String
    public let description: String
    public let tone: String?
    public let style: String?
    public let emotionalLayer: String?
    public let constraints: [String]
    public let instructions: String
    public let isDefault: Bool
    public let status: ManagedRecordStatus
    public let activeRevision: Int
    public let source: String
    public let createdAt: String
    public let updatedAt: String
}

public struct PersonaCreateResult: Codable, Sendable {
    public let persona: PersonaSummary
    public let created: Bool
}

public struct PersonaUpdateResult: Codable, Sendable {
    public let persona: PersonaSummary
    public let newRevision: Int
}

public struct PersonaArchiveResult: Codable, Sendable {
    public let persona: PersonaSummary
    public let archived: Bool
}

public enum CompiledInstructionSectionKey: String, Codable, Sendable {
    case systemScaffold = "system_scaffold"
    case agentDefinition = "agent_definition"
    case persona
    case skills
    case policyAppendices = "policy_appendices"
    case workspaceContext = "workspace_context"
    case conversationPrompt = "conversation_prompt"
    case assignmentContext = "assignment_context"
}

public struct CompiledInstructionSection: Codable, Sendable {
    public let key: CompiledInstructionSectionKey
    public let title: String
    public let content: String
}

public struct CompiledInstructionsPreview: Codable, Sendable {
    public let agentDefinitionId: String
    public let personaId: String?
    public let sections: [CompiledInstructionSection]
    public let compiledText: String
    public let generatedAt: String
}

public enum RuntimeSystemPromptSectionKey: String, Codable, Sendable {
    case agentDefinition = "agent_definition"
    case persona
    case activeSkillContext = "active_skill_context"
    case workspaceContext = "workspace_context"
    case conversationPrompt = "conversation_prompt"
    case assignmentContext = "assignment_context"
}

public struct RuntimeSystemPromptSection: Codable, Sendable {
    public let key: RuntimeSystemPromptSectionKey
    public let title: String
    public let content: String
}

public struct RuntimeSystemPromptPreview: Codable, Sendable {
    public let spaceId: String
    public let agentId: String?
    public let profileId: String
    public let personaId: String?
    public let targetKind: String
    public let conversationTopology: ConversationTopology?
    public let promptPackId: String?
    public let sections: [RuntimeSystemPromptSection]
    public let compiledText: String
    public let generatedAt: String
}
