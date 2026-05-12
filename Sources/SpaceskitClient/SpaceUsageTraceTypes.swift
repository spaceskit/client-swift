// SpaceUsageTraceTypes.swift - Space usage, trace, and activity log data types.

import Foundation

public struct SpaceGetUsagePayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let includeAgentSessions: Bool?
    public let includeGlobalLifetime: Bool?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        includeAgentSessions: Bool? = nil,
        includeGlobalLifetime: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.includeAgentSessions = includeAgentSessions
        self.includeGlobalLifetime = includeGlobalLifetime
    }
}

public struct SpaceUsageSnapshot: Codable, Sendable {
    public let spaceId: String
    public let stagingBytes: Int
    public let openChangeSets: Int
    public let appliedChangeSetsPerMonth: Int
    public let inputTokens: Int
    public let outputTokens: Int
    public let totalTokens: Int
    public let tokenSpendUsd: Double
    public let tokenAccuracy: String
    public let usageSource: String
    public let updatedAt: String
}

public struct ParticipantUsageSnapshot: Codable, Sendable {
    public let spaceId: String
    public let principalId: String
    public let stagingBytes: Int
    public let uploadsToday: Int
    public let openChangeSets: Int
    public let toolCallsPerHour: Int
    public let updatedAt: String
}

public struct AgentUsageSessionSnapshot: Codable, Sendable {
    public let sessionId: String
    public let spaceId: String
    public let agentId: String
    public let agentRole: String
    public let displayTitle: String?
    public let status: String
    public let startedAt: String
    public let endedAt: String?
    public let lastActivityAt: String
    public let turnCount: Int
    public let inputTokens: Int
    public let outputTokens: Int
    public let totalTokens: Int
    public let spentUsd: Double
    public let tokenAccuracy: String
    public let usageSource: String
}

public struct SpaceGetUsageResult: Codable, Sendable {
    public let spaceUsage: SpaceUsageSnapshot
    public let participantUsage: ParticipantUsageSnapshot?
    public let agentSessions: [AgentUsageSessionSnapshot]?
    public let globalLifetime: UsageWindowSummary?
}

public struct SpaceGetTurnTracePayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let turnId: String
    public let limit: Int?
    public let offset: Int?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        turnId: String,
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

public struct SpaceTurnTraceEvent: Codable, Sendable {
    public let eventId: String
    public let seq: Int
    public let eventType: String
    public let eventSubtype: String?
    public let agentId: String?
    public let createdAt: String
    public let payload: [String: AnyCodable]
}

public struct SpaceTurnTraceToolCall: Codable, Sendable {
    public let toolCallId: String
    public let toolName: String?
    public let status: String
    public let agentId: String?
    public let startedAt: String?
    public let completedAt: String?
}

public struct SpaceTurnTraceActivity: Codable, Sendable {
    public let activityId: String
    public let seq: Int
    public let eventType: String
    public let agentId: String?
    public let title: String
    public let detail: String?
    public let status: String?
    public let visibility: String
    public let toolCallId: String?
    public let toolName: String?
    public let createdAt: String
    public let payload: [String: AnyCodable]
}

public struct SpaceTurnTraceExecutionRun: Codable, Sendable {
    public let executionId: String
    public let stepIndex: Int
    public let agentId: String?
    public let providerId: String?
    public let modelId: String?
    public let status: String
    public let startedAt: String?
    public let completedAt: String?
    public let durationMs: Int?
    public let workingDirectory: String?
    public let exitCode: Int?
    public let commandPreview: String?
    public let transcriptArtifactId: String?
    public let transcriptTruncated: Bool
}

public struct SpaceTurnTrace: Codable, Sendable {
    public let spaceId: String
    public let turnId: String
    public let total: Int
    public let events: [SpaceTurnTraceEvent]
    public let toolCalls: [SpaceTurnTraceToolCall]
    public let activities: [SpaceTurnTraceActivity]
    public let executionRuns: [SpaceTurnTraceExecutionRun]
    public let artifactIds: [String]

    private enum CodingKeys: String, CodingKey {
        case spaceId
        case turnId
        case total
        case events
        case toolCalls
        case activities
        case executionRuns
        case artifactIds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        spaceId = try container.decode(String.self, forKey: .spaceId)
        turnId = try container.decode(String.self, forKey: .turnId)
        total = try container.decode(Int.self, forKey: .total)
        events = try container.decodeIfPresent([SpaceTurnTraceEvent].self, forKey: .events) ?? []
        toolCalls = try container.decodeIfPresent([SpaceTurnTraceToolCall].self, forKey: .toolCalls) ?? []
        activities = try container.decodeIfPresent([SpaceTurnTraceActivity].self, forKey: .activities) ?? []
        executionRuns = try container.decodeIfPresent([SpaceTurnTraceExecutionRun].self, forKey: .executionRuns) ?? []
        artifactIds = try container.decodeIfPresent([String].self, forKey: .artifactIds) ?? []
    }
}

public struct SpaceGetTurnTraceResult: Codable, Sendable {
    public let trace: SpaceTurnTrace
}

public struct SpaceListActivityLogPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String?
    public let spaceUid: String?
    public let turnId: String?
    public let includeSystem: Bool?
    public let limit: Int?
    public let offset: Int?

    public init(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        spaceUid: String? = nil,
        turnId: String? = nil,
        includeSystem: Bool? = true,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.turnId = turnId
        self.includeSystem = includeSystem
        self.limit = limit
        self.offset = offset
    }
}

public struct SpaceActivityLogEntry: Codable, Sendable {
    public let entryId: String
    public let source: String
    public let category: String
    public let turnId: String?
    public let rootTurnId: String?
    public let summaryTurnId: String?
    public let agentId: String?
    public let actorId: String?
    public let eventType: String
    public let title: String
    public let detail: String?
    public let status: String?
    public let visibility: String
    public let toolCallId: String?
    public let toolName: String?
    public let createdAt: String
    public let seq: Int
    public let payload: [String: AnyCodable]

    private enum CodingKeys: String, CodingKey {
        case entryId
        case source
        case category
        case turnId
        case rootTurnId
        case summaryTurnId
        case agentId
        case actorId
        case eventType
        case title
        case detail
        case status
        case visibility
        case toolCallId
        case toolName
        case createdAt
        case seq
        case payload
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entryId = try container.decode(String.self, forKey: .entryId)
        source = try container.decode(String.self, forKey: .source)
        category = try container.decode(String.self, forKey: .category)
        turnId = try container.decodeIfPresent(String.self, forKey: .turnId)
        rootTurnId = try container.decodeIfPresent(String.self, forKey: .rootTurnId)
        summaryTurnId = try container.decodeIfPresent(String.self, forKey: .summaryTurnId)
        agentId = try container.decodeIfPresent(String.self, forKey: .agentId)
        actorId = try container.decodeIfPresent(String.self, forKey: .actorId)
        eventType = try container.decode(String.self, forKey: .eventType)
        title = try container.decode(String.self, forKey: .title)
        detail = try container.decodeIfPresent(String.self, forKey: .detail)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        visibility = try container.decode(String.self, forKey: .visibility)
        toolCallId = try container.decodeIfPresent(String.self, forKey: .toolCallId)
        toolName = try container.decodeIfPresent(String.self, forKey: .toolName)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        seq = try container.decodeIfPresent(Int.self, forKey: .seq) ?? 0
        payload = try container.decodeIfPresent([String: AnyCodable].self, forKey: .payload) ?? [:]
    }
}

public struct SpaceListActivityLogResult: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let entries: [SpaceActivityLogEntry]
    public let total: Int
    public let nextOffset: Int?

    private enum CodingKeys: String, CodingKey {
        case spaceId
        case spaceUid
        case entries
        case total
        case nextOffset
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        spaceId = try container.decode(String.self, forKey: .spaceId)
        spaceUid = try container.decodeIfPresent(String.self, forKey: .spaceUid) ?? spaceId
        entries = try container.decodeIfPresent([SpaceActivityLogEntry].self, forKey: .entries) ?? []
        total = try container.decodeIfPresent(Int.self, forKey: .total) ?? entries.count
        nextOffset = try container.decodeIfPresent(Int.self, forKey: .nextOffset)
    }
}
