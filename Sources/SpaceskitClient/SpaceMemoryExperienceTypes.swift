// SpaceMemoryExperienceTypes.swift - Space experience, profile, and memory data types.

import Foundation

public struct SpaceExperienceRecord: Codable, Sendable {
    public let experienceId: String
    public let spaceId: String
    public let title: String?
    public let summary: String?
    public let observationSummary: String?
    public let status: String?
    public let sourceTurnId: String?
    public let createdAt: String
    public let updatedAt: String
    public let metadata: [String: AnyCodable]?

    private enum CodingKeys: String, CodingKey {
        case experienceId
        case spaceId
        case title
        case summary
        case observationSummary
        case status
        case sourceTurnId
        case createdAt
        case updatedAt
        case metadata
    }
}

public struct SpaceListExperiencesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let limit: Int?
    public let offset: Int?

    public init(apiVersion: String? = nil, spaceId: String, limit: Int? = nil, offset: Int? = nil) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.limit = limit
        self.offset = offset
    }
}

public struct SpaceListExperiencesResult: Codable, Sendable {
    public let experiences: [SpaceExperienceRecord]
    public let total: Int
    public let nextOffset: Int?

    private enum CodingKeys: String, CodingKey {
        case experiences
        case total
        case nextOffset
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        experiences = try container.decodeIfPresent([SpaceExperienceRecord].self, forKey: .experiences) ?? []
        total = try container.decodeIfPresent(Int.self, forKey: .total) ?? experiences.count
        nextOffset = try container.decodeIfPresent(Int.self, forKey: .nextOffset)
    }
}

public struct SpaceGetExperiencePayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let experienceId: String

    public init(apiVersion: String? = nil, spaceId: String, experienceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.experienceId = experienceId
    }
}

public struct SpaceGetExperienceResult: Codable, Sendable {
    public let experience: SpaceExperienceRecord
}

public struct SpacePersonalityInsightRecord: Codable, Sendable {
    public let insightId: String
    public let spaceId: String
    public let experienceId: String?
    public let agentId: String?
    public let title: String?
    public let summary: String?
    public let rationale: String?
    public let status: String
    public let createdAt: String
    public let updatedAt: String
    public let acceptedAt: String?
    public let rejectedAt: String?
    public let dismissedAt: String?
    public let metadata: [String: AnyCodable]?
}

public struct SpaceListInsightsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let status: String?
    public let limit: Int?
    public let offset: Int?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        status: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.status = status
        self.limit = limit
        self.offset = offset
    }
}

public struct SpaceListInsightsResult: Codable, Sendable {
    public let insights: [SpacePersonalityInsightRecord]
    public let total: Int
    public let nextOffset: Int?

    private enum CodingKeys: String, CodingKey {
        case insights
        case total
        case nextOffset
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        insights = try container.decodeIfPresent([SpacePersonalityInsightRecord].self, forKey: .insights) ?? []
        total = try container.decodeIfPresent(Int.self, forKey: .total) ?? insights.count
        nextOffset = try container.decodeIfPresent(Int.self, forKey: .nextOffset)
    }
}

public struct SpaceGetInsightPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let insightId: String

    public init(apiVersion: String? = nil, spaceId: String, insightId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.insightId = insightId
    }
}

public struct SpaceGetInsightResult: Codable, Sendable {
    public let insight: SpacePersonalityInsightRecord
}

public struct SpaceAcceptInsightPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let insightId: String
    public let notes: String?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        insightId: String,
        notes: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.insightId = insightId
        self.notes = notes
    }
}

public struct SpaceRejectInsightPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let insightId: String
    public let reason: String?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        insightId: String,
        reason: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.insightId = insightId
        self.reason = reason
    }
}

public struct SpaceDismissInsightPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let insightId: String
    public let reason: String?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        insightId: String,
        reason: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.insightId = insightId
        self.reason = reason
    }
}

public struct SpaceInsightActionResult: Codable, Sendable {
    public let insight: SpacePersonalityInsightRecord
}

public struct SpaceAgentNotesRecord: Codable, Sendable {
    public let spaceId: String
    public let agentId: String
    public let notes: String
    public let updatedAt: String
    public let createdAt: String?
}

public struct SpaceGetSpaceAgentNotesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let agentId: String

    public init(apiVersion: String? = nil, spaceId: String, agentId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.agentId = agentId
    }
}

public struct SpaceUpdateSpaceAgentNotesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let agentId: String
    public let notes: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        agentId: String,
        notes: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.agentId = agentId
        self.notes = notes
    }
}

public struct SpaceAgentNotesResult: Codable, Sendable {
    public let notes: SpaceAgentNotesRecord?
}

public struct SpaceUserProfileRecord: Codable, Sendable {
    public let principalId: String
    public let displayName: String?
    public let summary: String?
    public let facts: [String]
    public let preferences: [String]
    public let corrections: [String]
    public let metadata: [String: AnyCodable]?
    public let updatedAt: String
    public let createdAt: String?

    private enum CodingKeys: String, CodingKey {
        case principalId
        case displayName
        case summary
        case facts
        case preferences
        case corrections
        case metadata
        case updatedAt
        case createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        principalId = try container.decode(String.self, forKey: .principalId)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        facts = try container.decodeIfPresent([String].self, forKey: .facts) ?? []
        preferences = try container.decodeIfPresent([String].self, forKey: .preferences) ?? []
        corrections = try container.decodeIfPresent([String].self, forKey: .corrections) ?? []
        metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }
}

public struct SpaceGetUserProfilePayload: Codable, Sendable {
    public let apiVersion: String?
    public let principalId: String?

    public init(apiVersion: String? = nil, principalId: String? = nil) {
        self.apiVersion = apiVersion
        self.principalId = principalId
    }
}

public struct SpaceUpdateUserProfilePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let principalId: String?
    public let displayName: String?
    public let summary: String?
    public let facts: [String]?
    public let preferences: [String]?
    public let corrections: [String]?
    public let metadata: [String: AnyCodable]?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        principalId: String? = nil,
        displayName: String? = nil,
        summary: String? = nil,
        facts: [String]? = nil,
        preferences: [String]? = nil,
        corrections: [String]? = nil,
        metadata: [String: Any]? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.principalId = principalId
        self.displayName = displayName
        self.summary = summary
        self.facts = facts
        self.preferences = preferences
        self.corrections = corrections
        self.metadata = metadata?.mapValues { AnyCodable($0) }
    }
}

public struct SpaceUserProfileResult: Codable, Sendable {
    public let profile: SpaceUserProfileRecord?
}

public struct SpaceMemoryRecord: Codable, Sendable {
    public let memoryId: String
    public let spaceId: String
    public let principalId: String?
    public let sourceType: String?
    public let sourceId: String?
    public let status: String?
    public let scopeType: String?
    public let scopeId: String?
    public let category: String?
    public let textPreview: String?
    public let importance: Double?
    public let createdAt: String
    public let updatedAt: String
    public let metadata: [String: AnyCodable]?
}

public struct SpaceListMemoriesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let principalId: String?
    public let sourceType: String?
    public let status: String?
    public let limit: Int?
    public let offset: Int?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        principalId: String? = nil,
        sourceType: String? = nil,
        status: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.principalId = principalId
        self.sourceType = sourceType
        self.status = status
        self.limit = limit
        self.offset = offset
    }
}

public struct SpaceListMemoriesResult: Codable, Sendable {
    public let memories: [SpaceMemoryRecord]
    public let total: Int
    public let nextOffset: Int?

    private enum CodingKeys: String, CodingKey {
        case memories
        case total
        case nextOffset
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        memories = try container.decodeIfPresent([SpaceMemoryRecord].self, forKey: .memories) ?? []
        total = try container.decodeIfPresent(Int.self, forKey: .total) ?? memories.count
        nextOffset = try container.decodeIfPresent(Int.self, forKey: .nextOffset)
    }
}

public struct SpaceDeleteMemoryPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let memoryId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        memoryId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.memoryId = memoryId
    }
}

public struct SpaceDeleteMemoryResult: Codable, Sendable {
    public let deleted: Bool
    public let memoryId: String
}

public struct SpaceUpdateMemoryImportancePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let memoryId: String
    public let importance: Double

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        memoryId: String,
        importance: Double
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.memoryId = memoryId
        self.importance = importance
    }
}

public struct SpaceUpdateMemoryImportanceResult: Codable, Sendable {
    public let memory: SpaceMemoryRecord
}
