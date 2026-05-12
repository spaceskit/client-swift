// SpaceArtifactAgentEventTypes.swift - Space artifact and agent update data types.

import Foundation

public struct SpaceListArtifactsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let turnId: String?
    public let limit: Int?
    public let offset: Int?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        turnId: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.turnId = turnId
        self.limit = limit
        self.offset = offset
    }
}

public struct SpaceGetArtifactPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let artifactId: String

    public init(apiVersion: String? = nil, spaceId: String, artifactId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.artifactId = artifactId
    }
}

public struct SpaceGetDebugArtifactPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let artifactId: String

    public init(apiVersion: String? = nil, spaceId: String, artifactId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.artifactId = artifactId
    }
}

public struct SpaceArtifactSummary: Codable, Sendable {
    public let artifactId: String
    public let spaceId: String
    public let turnId: String?
    public let agentId: String?
    public let type: String
    public let title: String
    public let mimeType: String?
    public let sizeBytes: Int
    public let tags: [String]
    public let visibility: String
    public let createdAt: String
    public let updatedAt: String
}

public struct SpaceArtifactDetail: Codable, Sendable {
    public let artifactId: String
    public let spaceId: String
    public let turnId: String?
    public let agentId: String?
    public let type: String
    public let title: String
    public let mimeType: String?
    public let sizeBytes: Int
    public let tags: [String]
    public let visibility: String
    public let createdAt: String
    public let updatedAt: String
    public let content: AnyCodable
    public let contentEnvelope: ContentEnvelope?
    public let previewText: String?
    public let primaryMimeType: String?
}

public struct SpaceListArtifactsResult: Codable, Sendable {
    public let artifacts: [SpaceArtifactSummary]
    public let total: Int
}

public struct SpaceGetArtifactResult: Codable, Sendable {
    public let artifact: SpaceArtifactDetail
}

public struct SpaceGetDebugArtifactResult: Codable, Sendable {
    public let artifact: SpaceArtifactDetail
}

public struct SpaceResetAgentUsageSessionPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let agentId: String

    public init(apiVersion: String? = nil, spaceId: String, agentId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.agentId = agentId
    }
}

public struct SpaceResetAgentUsageSessionResult: Codable, Sendable {
    public let closedSessionId: String?
    public let activeSession: AgentUsageSessionSnapshot
}

public struct SpaceAgentUpdatedEvent: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let agentId: String
    public let oldAgentDefinitionId: String?
    public let newAgentDefinitionId: String?
    public let oldProfileId: String
    public let newProfileId: String
    public let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case spaceId
        case spaceUid
        case agentId
        case oldAgentDefinitionId
        case newAgentDefinitionId
        case oldProfileId
        case newProfileId
        case updatedAt
    }

    public init(
        spaceId: String,
        spaceUid: String,
        agentId: String,
        oldAgentDefinitionId: String? = nil,
        newAgentDefinitionId: String? = nil,
        oldProfileId: String,
        newProfileId: String,
        updatedAt: String
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.agentId = agentId
        self.oldAgentDefinitionId = oldAgentDefinitionId ?? oldProfileId
        self.newAgentDefinitionId = newAgentDefinitionId ?? newProfileId
        self.oldProfileId = oldProfileId
        self.newProfileId = newProfileId
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let oldProfileId = try container.decode(String.self, forKey: .oldProfileId)
        let newProfileId = try container.decode(String.self, forKey: .newProfileId)
        self.init(
            spaceId: try container.decode(String.self, forKey: .spaceId),
            spaceUid: try container.decode(String.self, forKey: .spaceUid),
            agentId: try container.decode(String.self, forKey: .agentId),
            oldAgentDefinitionId: try container.decodeIfPresent(String.self, forKey: .oldAgentDefinitionId),
            newAgentDefinitionId: try container.decodeIfPresent(String.self, forKey: .newAgentDefinitionId),
            oldProfileId: oldProfileId,
            newProfileId: newProfileId,
            updatedAt: try container.decode(String.self, forKey: .updatedAt)
        )
    }
}
