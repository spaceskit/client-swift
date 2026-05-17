// Protocol payload types for Spaceskit Client SDK.

import Foundation

// MARK: - Space Response Payloads

public struct SpaceCreateInitialAgentPayload: Codable, Sendable {
    public let agentId: String
    public let profileId: String
    public let role: String?
    public let turnOrder: Int?
    public let isPrimary: Bool?

    public init(
        agentId: String,
        profileId: String,
        role: String? = nil,
        turnOrder: Int? = nil,
        isPrimary: Bool? = nil
    ) {
        self.agentId = agentId
        self.profileId = profileId
        self.role = role
        self.turnOrder = turnOrder
        self.isPrimary = isPrimary
    }
}

public struct SpaceCreateResponsePayload: Codable, Sendable {
    public let space: SpaceConfig

    public init(space: SpaceConfig) {
        self.space = space
    }
}

public struct SpaceGetResponsePayload: Codable, Sendable {
    public let space: SpaceConfig

    public init(space: SpaceConfig) {
        self.space = space
    }
}

public struct SpaceGetMemoryPolicyResponsePayload: Codable, Sendable {
    public let spaceId: String
    public let memoryPolicy: SpaceMemoryPolicy
}

public struct SpaceListResponsePayload: Codable, Sendable {
    public let spaces: [SpaceConfig]

    public init(spaces: [SpaceConfig]) {
        self.spaces = spaces
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
