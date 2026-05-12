// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Templates and Library

public enum CommunicationMode: String, Codable, Sendable {
    case asyncNotes = "async_notes"
    case chatFirst = "chat_first"
    case structuredHandoff = "structured_handoff"
}

public enum ConversationTopology: String, Codable, Sendable, CaseIterable {
    case direct
    case sharedTeamChat = "shared_team_chat"
    case broadcastTeam = "broadcast_team"

    public var title: String {
        switch self {
        case .direct:
            return "Single Agent"
        case .sharedTeamChat:
            return "Shared Team Chat"
        case .broadcastTeam:
            return "Broadcast Team"
        }
    }
}

public enum TranscriptVisibility: String, Codable, Sendable {
    case visible
    case activityOnly = "activity_only"
    case summary
}

public enum TurnStreamKind: String, Codable, Sendable {
    case assistantOutput = "assistant_output"
    case providerClient = "provider_client"
}

public enum TemplateAgentProfileBinding: String, Codable, Sendable {
    case explicit
    case gatewayDefaultMain = "gateway_default_main"
}

public struct TemplateAgentDefinition: Codable, Sendable {
    public let agentId: String
    public let agentDefinitionId: String
    public let profileId: String
    public let profileBinding: TemplateAgentProfileBinding?
    public let role: SpaceAssignmentRole?
    public let turnOrder: Int?
    public let isPrimary: Bool?

    private enum CodingKeys: String, CodingKey {
        case agentId
        case agentDefinitionId
        case profileId
        case profileBinding
        case role
        case turnOrder
        case isPrimary
    }

    public init(
        agentId: String,
        agentDefinitionId: String? = nil,
        profileId: String? = nil,
        profileBinding: TemplateAgentProfileBinding? = nil,
        role: SpaceAssignmentRole? = nil,
        turnOrder: Int? = nil,
        isPrimary: Bool? = nil
    ) {
        let resolvedAgentDefinitionId = agentDefinitionId ?? profileId ?? ""
        let resolvedProfileId = profileId ?? resolvedAgentDefinitionId
        self.agentId = agentId
        self.agentDefinitionId = resolvedAgentDefinitionId
        self.profileId = resolvedProfileId
        self.profileBinding = profileBinding
        self.role = role
        self.turnOrder = turnOrder
        self.isPrimary = isPrimary
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedAgentDefinitionId = try container.decodeIfPresent(String.self, forKey: .agentDefinitionId)
        let decodedProfileId = try container.decodeIfPresent(String.self, forKey: .profileId)
        let resolvedAgentDefinitionId = decodedAgentDefinitionId ?? decodedProfileId ?? ""
        let resolvedProfileId = decodedProfileId ?? resolvedAgentDefinitionId
        guard !resolvedAgentDefinitionId.isEmpty else {
            throw DecodingError.keyNotFound(
                CodingKeys.agentDefinitionId,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "TemplateAgentDefinition requires agentDefinitionId or profileId"
                )
            )
        }

        self.init(
            agentId: try container.decode(String.self, forKey: .agentId),
            agentDefinitionId: resolvedAgentDefinitionId,
            profileId: resolvedProfileId,
            profileBinding: try container.decodeIfPresent(TemplateAgentProfileBinding.self, forKey: .profileBinding),
            role: try container.decodeIfPresent(SpaceAssignmentRole.self, forKey: .role),
            turnOrder: try container.decodeIfPresent(Int.self, forKey: .turnOrder),
            isPrimary: try container.decodeIfPresent(Bool.self, forKey: .isPrimary)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(agentId, forKey: .agentId)
        try container.encode(agentDefinitionId, forKey: .agentDefinitionId)
        try container.encode(profileId, forKey: .profileId)
        try container.encodeIfPresent(profileBinding, forKey: .profileBinding)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(turnOrder, forKey: .turnOrder)
        try container.encodeIfPresent(isPrimary, forKey: .isPrimary)
    }
}

public struct SpaceTemplateSummary: Codable, Sendable {
    public let templateId: String
    public let title: String
    public let communicationMode: CommunicationMode
    public let conversationTopology: ConversationTopology?
    public let promptPackId: String?
    public let agentPresetIds: [String]
    public let createdBy: String
    public let updatedAt: String
    public let category: String?
    public let complexityTier: String?
    public let icon: String?
    public let featured: Bool?
    public let sortOrder: Int?
    public let description: String?
    public let agentCount: Int?
}

public struct SpaceTemplatePreviewResolved: Codable, Sendable {
    public let templateId: String
    public let templateRevision: Int
    public let name: String
    public let goal: String?
    public let resourceId: String
    public let communicationMode: CommunicationMode
    public let conversationTopology: ConversationTopology?
    public let promptPackId: String?
    public let turnModel: String
    public let initialAgents: [TemplateAgentDefinition]
}

public struct SpacePreviewTemplateResult: Codable, Sendable {
    public let template: SpaceTemplateSummary
    public let resolved: SpaceTemplatePreviewResolved
    public let warnings: [String]
}

public struct SpaceCreateFromTemplateResult: Codable, Sendable {
    public let template: SpaceTemplateSummary
    public let space: SpaceConfig
}

public struct SpaceSaveTemplateResult: Codable, Sendable {
    public let template: SpaceTemplateSummary
    public let created: Bool
}

public enum LibrarySourceKind: String, Codable, Sendable {
    case installed
    case scanned
    case linked
    case verified
    case system
}

public enum LibraryEntryStatus: String, Codable, Sendable {
    case enabled
    case disabled
    case archived
}

public enum LibraryEntrySyncState: String, Codable, Sendable {
    case ready
    case missing
    case parseError = "parse_error"
}

public struct LibraryEntry: Codable, Sendable {
    public let entryId: String
    public let skillId: String?
    public let name: String
    public let description: String?
    public let contentMarkdown: String?
    public let sourceKind: LibrarySourceKind
    public let sourceRef: String?
    public let syncState: LibraryEntrySyncState?
    public let provenance: [String: AnyCodable]?
    public let tags: [String]
    public let status: LibraryEntryStatus
    public let importable: Bool
    public let importedSkillId: String?
    public let createdAt: String
    public let updatedAt: String
}

public struct LibrarySaveSkillResult: Codable, Sendable {
    public let entry: LibraryEntry
    public let created: Bool
}

public struct LibraryImportEntryResult: Codable, Sendable {
    public let entry: LibraryEntry
    public let created: Bool
}

public struct LibraryArchiveEntryResult: Codable, Sendable {
    public let entry: LibraryEntry
    public let archived: Bool
}

public struct LibraryDeleteEntryResult: Codable, Sendable {
    public let entryId: String
    public let deleted: Bool
}

public struct LibraryScanEntriesResult: Codable, Sendable {
    public let entries: [LibraryEntry]
    public let scannedAt: String
}

public struct SkillDraft: Codable, Sendable {
    public let draftId: String
    public let name: String
    public let description: String?
    public let requestPrompt: String
    public let contentMarkdown: String
    public let createdAt: String
    public let updatedAt: String
}

public struct LibraryCreateSkillDraftResult: Codable, Sendable {
    public let draft: SkillDraft
    public let created: Bool
}

public struct LibraryDeleteSkillDraftResult: Codable, Sendable {
    public let draftId: String
    public let deleted: Bool
}

public struct SpaceTemplateRecord: Codable, Sendable {
    public let templateId: String
    public let name: String
    public let description: String?
    public let status: ManagedRecordStatus
    public let activeRevision: Int
    public let communicationMode: CommunicationMode
    public let conversationTopology: ConversationTopology?
    public let promptPackId: String?
    public let turnModel: String
    public let agentDefinitions: [TemplateAgentDefinition]
    public let createdBy: String
    public let createdAt: String
    public let updatedAt: String
    public let category: String?
    public let complexityTier: String?
    public let icon: String?
    public let featured: Bool?
    public let sortOrder: Int?
    public let agentCount: Int?
}

public struct SpaceTemplatePreviewResult: Codable, Sendable {
    public let template: SpaceTemplateRecord
    public let resolved: SpaceTemplatePreviewResolved
    public let warnings: [String]
}

public struct SpaceTemplateCreateSpaceResult: Codable, Sendable {
    public let template: SpaceTemplateRecord
    public let space: SpaceConfig
}

public struct SpaceTemplateSaveResult: Codable, Sendable {
    public let template: SpaceTemplateRecord
    public let created: Bool
}

public struct SpaceTemplateArchiveResult: Codable, Sendable {
    public let template: SpaceTemplateRecord
    public let archived: Bool
}
