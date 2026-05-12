// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Space Lifecycle

public struct SpaceConfig: Codable, Sendable {
    public let id: String
    public let spaceUid: String
    public let workspace: SpaceWorkspace?
    public let status: String?
    public let resourceId: String
    public let name: String
    public let goal: String?
    public let orchestratorAgentDefinitionId: String?
    public let orchestratorProfileId: String?
    public let templateId: String?
    public let conversationTopology: ConversationTopology?
    public let promptPackId: String?
    public let turnModel: String
    public let turnModelConfig: [String: AnyCodable]?
    public let skillIds: [String]?
    public let agents: [SpaceAgentAssignment]
    public let capabilities: [String]
    public let capabilityOverrides: [String: String]
    public let maxTurns: Int?
    public let visibility: SpaceVisibility
    public let thinkingCapturePolicy: ThinkingCapturePolicy
    public let memoryPolicy: SpaceMemoryPolicy
    public let moderatorProfileId: String?
    public let archivedAt: String?
    public let deletedAt: String?
    public let createdAt: String
    public let updatedAt: String
}

extension SpaceConfig {
    private enum CodingKeys: String, CodingKey {
        case id
        case spaceUid
        case workspace
        case status
        case resourceId
        case name
        case goal
        case orchestratorAgentDefinitionId
        case orchestratorProfileId
        case templateId
        case conversationTopology
        case promptPackId
        case turnModel
        case turnModelConfig
        case skillIds
        case agents
        case capabilities
        case capabilityOverrides
        case maxTurns
        case visibility
        case thinkingCapturePolicy
        case memoryPolicy
        case moderatorProfileId
        case archivedAt
        case deletedAt
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .id)
        let decodedSpaceUid = try container.decodeIfPresent(String.self, forKey: .spaceUid)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let spaceUid = (decodedSpaceUid?.isEmpty == false ? decodedSpaceUid : nil) ?? id

        self.id = id
        self.spaceUid = spaceUid
        self.workspace = try container.decodeIfPresent(SpaceWorkspace.self, forKey: .workspace)
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
        self.resourceId = try container.decode(String.self, forKey: .resourceId)
        self.name = try container.decode(String.self, forKey: .name)
        self.goal = try container.decodeIfPresent(String.self, forKey: .goal)
        let decodedOrchestratorAgentDefinitionId = try container.decodeIfPresent(
            String.self,
            forKey: .orchestratorAgentDefinitionId
        )
        let decodedOrchestratorProfileId = try container.decodeIfPresent(
            String.self,
            forKey: .orchestratorProfileId
        )
        self.orchestratorAgentDefinitionId = decodedOrchestratorAgentDefinitionId ?? decodedOrchestratorProfileId
        self.orchestratorProfileId = decodedOrchestratorProfileId ?? decodedOrchestratorAgentDefinitionId
        self.templateId = try container.decodeIfPresent(String.self, forKey: .templateId)
        self.conversationTopology = try container.decodeIfPresent(ConversationTopology.self, forKey: .conversationTopology)
        self.promptPackId = try container.decodeIfPresent(String.self, forKey: .promptPackId)
        self.turnModel = try container.decode(String.self, forKey: .turnModel)
        self.turnModelConfig = try container.decodeIfPresent([String: AnyCodable].self, forKey: .turnModelConfig)
        self.skillIds = try container.decodeIfPresent([String].self, forKey: .skillIds)
        self.agents = try container.decodeIfPresent([SpaceAgentAssignment].self, forKey: .agents) ?? []
        self.capabilities = try container.decodeIfPresent([String].self, forKey: .capabilities) ?? []
        self.capabilityOverrides = try container.decodeIfPresent([String: String].self, forKey: .capabilityOverrides) ?? [:]
        self.maxTurns = try container.decodeIfPresent(Int.self, forKey: .maxTurns)
        self.visibility = try container.decodeIfPresent(SpaceVisibility.self, forKey: .visibility) ?? .shared
        self.thinkingCapturePolicy = try container.decodeIfPresent(
            ThinkingCapturePolicy.self,
            forKey: .thinkingCapturePolicy
        ) ?? .summary
        self.memoryPolicy = try container.decodeIfPresent(
            SpaceMemoryPolicy.self,
            forKey: .memoryPolicy
        ) ?? SpaceMemoryPolicy()
        self.moderatorProfileId = try container.decodeIfPresent(String.self, forKey: .moderatorProfileId)
        self.archivedAt = try container.decodeIfPresent(String.self, forKey: .archivedAt)
        self.deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)
        self.createdAt = try container.decode(String.self, forKey: .createdAt)
        self.updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
}

public struct SpaceAddAgentResult: Codable, Sendable {
    public let assignment: SpaceAgentAssignment
    public let space: SpaceConfig?
}

public struct SpaceRemoveAgentResult: Codable, Sendable {
    public let removed: Bool
    public let spaceId: String
    public let spaceUid: String
    public let agentId: String
    public let space: SpaceConfig?
}

public struct SpaceUpdateAgentAssignmentResult: Codable, Sendable {
    public let assignment: SpaceAgentAssignment
    public let space: SpaceConfig?
}

public struct SpaceResource: Codable, Sendable {
    public let resourceId: String
    public let spaceId: String
    public let spaceUid: String
    public let uri: String
    public let type: String
    public let label: String?
    public let addedAt: String
}

public struct SpaceAddResourceResult: Codable, Sendable {
    public let resource: SpaceResource
}

public struct SpaceRemoveResourceResult: Codable, Sendable {
    public let removed: Bool
    public let spaceId: String
    public let spaceUid: String
    public let resourceId: String
}

public struct SpaceListResourcesResult: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let resources: [SpaceResource]
}

public struct SpaceTurn: Codable, Sendable, Equatable {
    public let turnId: String
    public let rootTurnId: String?
    public let agentId: String
    public let status: String
    public let inputText: String?
    public let outputText: String?
    public let inputContent: ContentEnvelope?
    public let outputContent: ContentEnvelope?
    public let conversationTopology: ConversationTopology?
    public let transcriptVisibility: TranscriptVisibility?
    public let summaryTurnId: String?
    public let promptTokens: Int?
    public let completionTokens: Int?
    public let totalTokens: Int?
    public let createdAt: String
    public let completedAt: String?
    public let replyToTurnId: String?
    public let mode: String?
    public let effort: String?
    public let accessMode: String?
    public let effectiveAccessMode: String?
}

public struct SpaceListTurnsResult: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let turns: [SpaceTurn]
    public let total: Int
    public let nextOffset: Int?
}

public struct OrchestrationJournalEntry: Codable, Sendable {
    public let eventId: String
    public let spaceId: String
    public let spaceUid: String
    public let turnId: String?
    public let seq: Int
    public let eventType: String
    public let actorId: String
    public let lineageId: String?
    public let hopCount: Int
    public let payload: [String: AnyCodable]
    public let createdAt: String
}

public struct SpaceListOrchestrationJournalResult: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let entries: [OrchestrationJournalEntry]
    public let total: Int
    public let nextOffset: Int?
}
