// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Turn Results

/// Result of executing a turn in a space.
public struct TurnResult: Codable, Sendable {
    public let turnId: String
    public let spaceId: String
    public let output: String?
    public let status: TurnStatus
    public let error: String?

    public enum TurnStatus: String, Codable, Sendable {
        case completed
        case pendingFeedback = "pending_feedback"
        case failed
    }
}

/// Result of invoking a capability.
public struct CapabilityResult: Codable, Sendable {
    public let success: Bool
    public let data: AnyCodable?
    public let error: String?
}

// MARK: - Feedback

/// Feedback response type for human-in-the-loop turns.
public enum FeedbackResponse: String, Codable, Sendable {
    case approve
    case reject
    case revise
    case `defer`
}

// MARK: - Gateway Events

/// A turn lifecycle event from the gateway.
public struct TurnEvent: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let turnId: String
    public let eventType: String
    public let data: AnyCodable?
    public let timestamp: String?

    public init(
        spaceId: String,
        spaceUid: String,
        turnId: String,
        eventType: String,
        data: AnyCodable? = nil,
        timestamp: String? = nil
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.turnId = turnId
        self.eventType = eventType
        self.data = data
        self.timestamp = timestamp
    }

    private enum CodingKeys: String, CodingKey {
        case spaceId
        case spaceUid
        case turnId
        case eventType
        case data
        case timestamp
        case event
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let decodedSpaceId = (try? container.decode(String.self, forKey: .spaceId)) ?? ""
        let decodedSpaceUid = (try? container.decode(String.self, forKey: .spaceUid)) ?? decodedSpaceId
        let normalizedSpaceUid = decodedSpaceUid.isEmpty
            ? (decodedSpaceId.isEmpty ? "unknown-space" : decodedSpaceId)
            : decodedSpaceUid
        let normalizedSpaceId = decodedSpaceId.isEmpty ? normalizedSpaceUid : decodedSpaceId
        let turnId = (try? container.decode(String.self, forKey: .turnId)) ?? ""
        let timestamp = try? container.decode(String.self, forKey: .timestamp)

        // Current protocol shape.
        if let eventType = try? container.decode(String.self, forKey: .eventType) {
            let data = try container.decodeIfPresent(AnyCodable.self, forKey: .data)
            self.init(
                spaceId: normalizedSpaceId,
                spaceUid: normalizedSpaceUid,
                turnId: turnId,
                eventType: eventType,
                data: data,
                timestamp: timestamp
            )
            return
        }

        // Compatibility for gateway-internal event envelope shape.
        if let event = try? container.decode(AnyCodable.self, forKey: .event) {
            let mappedEventType = Self.mapEventType(from: event.value) ?? "streaming"
            self.init(
                spaceId: normalizedSpaceId,
                spaceUid: normalizedSpaceUid,
                turnId: turnId,
                eventType: mappedEventType,
                data: event,
                timestamp: timestamp
            )
            return
        }

        // Minimal ack compatibility (older runtimes can return only turnId).
        if !turnId.isEmpty {
            self.init(
                spaceId: normalizedSpaceId,
                spaceUid: normalizedSpaceUid,
                turnId: turnId,
                eventType: "started",
                data: nil,
                timestamp: timestamp
            )
            return
        }

        throw DecodingError.keyNotFound(
            CodingKeys.eventType,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "TurnEvent payload missing eventType/event fields"
            )
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(spaceId, forKey: .spaceId)
        try container.encode(spaceUid, forKey: .spaceUid)
        try container.encode(turnId, forKey: .turnId)
        try container.encode(eventType, forKey: .eventType)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
    }

    private static func mapEventType(from eventValue: Any) -> String? {
        guard let event = eventValue as? [String: Any],
              let type = event["type"] as? String else {
            return nil
        }

        switch type {
        case "text_delta":
            return "streaming"
        case "tool_call_start", "tool_result":
            return "tool_call"
        case "feedback_requested":
            return "feedback_requested"
        case "turn_completed":
            return "completed"
        case "error":
            return "failed"
        default:
            return "streaming"
        }
    }
}

/// A streaming text delta from an agent turn.
public struct TurnStream: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let turnId: String
    public let agentId: String
    public let delta: String
    public let seq: Int
    public let done: Bool
    public let timestamp: String?

    public init(
        spaceId: String,
        spaceUid: String,
        turnId: String,
        agentId: String,
        delta: String,
        seq: Int,
        done: Bool,
        timestamp: String? = nil
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.turnId = turnId
        self.agentId = agentId
        self.delta = delta
        self.seq = seq
        self.done = done
        self.timestamp = timestamp
    }

    private enum CodingKeys: String, CodingKey {
        case spaceId
        case spaceUid
        case turnId
        case agentId
        case delta
        case seq
        case done
        case timestamp
        case event
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let decodedSpaceId = (try? container.decode(String.self, forKey: .spaceId)) ?? ""
        let decodedSpaceUid = (try? container.decode(String.self, forKey: .spaceUid)) ?? decodedSpaceId
        let normalizedSpaceUid = decodedSpaceUid.isEmpty
            ? (decodedSpaceId.isEmpty ? "unknown-space" : decodedSpaceId)
            : decodedSpaceUid
        let normalizedSpaceId = decodedSpaceId.isEmpty ? normalizedSpaceUid : decodedSpaceId
        let turnId = (try? container.decode(String.self, forKey: .turnId)) ?? ""
        let timestamp = try? container.decode(String.self, forKey: .timestamp)

        // Current protocol shape.
        if let delta = try? container.decode(String.self, forKey: .delta) {
            let agentId = (try? container.decode(String.self, forKey: .agentId)) ?? "unknown-agent"
            let seq = (try? container.decode(Int.self, forKey: .seq)) ?? 0
            let done = (try? container.decode(Bool.self, forKey: .done)) ?? false

            self.init(
                spaceId: normalizedSpaceId,
                spaceUid: normalizedSpaceUid,
                turnId: turnId,
                agentId: agentId,
                delta: delta,
                seq: seq,
                done: done,
                timestamp: timestamp
            )
            return
        }

        // Compatibility for gateway-internal envelope:
        // { spaceId, turnId, event: { type: "text_delta", text: "..." } }
        if let event = try? container.decode(AnyCodable.self, forKey: .event),
           let eventDict = event.value as? [String: Any],
           let eventType = eventDict["type"] as? String,
           eventType == "text_delta",
           let text = eventDict["text"] as? String {
            let agentId = (try? container.decode(String.self, forKey: .agentId))
                ?? (eventDict["agentId"] as? String)
                ?? "unknown-agent"
            let seq = (try? container.decode(Int.self, forKey: .seq))
                ?? (eventDict["seq"] as? Int)
                ?? 0
            let done = (try? container.decode(Bool.self, forKey: .done))
                ?? (eventDict["done"] as? Bool)
                ?? false

            self.init(
                spaceId: normalizedSpaceId,
                spaceUid: normalizedSpaceUid,
                turnId: turnId,
                agentId: agentId,
                delta: text,
                seq: seq,
                done: done,
                timestamp: timestamp
            )
            return
        }

        throw DecodingError.keyNotFound(
            CodingKeys.delta,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "TurnStream payload missing delta/event text fields"
            )
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(spaceId, forKey: .spaceId)
        try container.encode(spaceUid, forKey: .spaceUid)
        try container.encode(turnId, forKey: .turnId)
        try container.encode(agentId, forKey: .agentId)
        try container.encode(delta, forKey: .delta)
        try container.encode(seq, forKey: .seq)
        try container.encode(done, forKey: .done)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
    }
}

/// Space state update notification.
public struct SpaceState: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let state: String
    public let turnCount: Int
    public let activeAgentId: String?
    public let pendingFeedback: Int
}

public enum SpaceVisibility: String, Codable, Sendable {
    case shared
    case `private`
}

public enum SpaceAssignmentRole: String, Codable, Sendable {
    case participant
    case globalCoordinator = "global_coordinator"
    case spaceModerator = "space_moderator"
}

public struct SpaceAgentAssignment: Codable, Sendable {
  public let spaceId: String
  public let agentId: String
  public let profileId: String
    public let securityScope: [String: AnyCodable]?
    public let spawnContext: String?
    public let contextOverrides: [String: AnyCodable]?
    public let role: SpaceAssignmentRole
    public let turnOrder: Int
  public let isPrimary: Bool
  public let assignedAt: String
}

public enum SpaceWorkspaceMetadataStatus: String, Codable, Sendable {
    case unknown
    case ready
    case conflict
}

public struct SpaceWorkspace: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let mode: String
    public let explicitWorkspaceRoot: String?
    public let effectiveWorkspaceRoot: String
    public let metaPath: String
    public let logsPath: String
    public let workPath: String
    public let sharedContextPath: String
    public let scratchpadsPath: String
    public let layoutVersion: Int
    public let gitRepoDetected: Bool
    public let metadataStatus: SpaceWorkspaceMetadataStatus
    public let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case spaceId
        case spaceUid
        case mode
        case explicitWorkspaceRoot
        case effectiveWorkspaceRoot
        case metaPath
        case logsPath
        case workPath
        case sharedContextPath
        case scratchpadsPath
        case layoutVersion
        case gitRepoDetected
        case metadataStatus
        case updatedAt
    }

    public init(
        spaceId: String,
        spaceUid: String,
        mode: String,
        explicitWorkspaceRoot: String? = nil,
        effectiveWorkspaceRoot: String,
        metaPath: String,
        logsPath: String,
        workPath: String,
        sharedContextPath: String,
        scratchpadsPath: String,
        layoutVersion: Int,
        gitRepoDetected: Bool = false,
        metadataStatus: SpaceWorkspaceMetadataStatus = .unknown,
        updatedAt: String
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.mode = mode
        self.explicitWorkspaceRoot = explicitWorkspaceRoot
        self.effectiveWorkspaceRoot = effectiveWorkspaceRoot
        self.metaPath = metaPath
        self.logsPath = logsPath
        self.workPath = workPath
        self.sharedContextPath = sharedContextPath
        self.scratchpadsPath = scratchpadsPath
        self.layoutVersion = layoutVersion
        self.gitRepoDetected = gitRepoDetected
        self.metadataStatus = metadataStatus
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        spaceId = try container.decode(String.self, forKey: .spaceId)
        spaceUid = try container.decode(String.self, forKey: .spaceUid)
        mode = try container.decode(String.self, forKey: .mode)
        explicitWorkspaceRoot = try container.decodeIfPresent(String.self, forKey: .explicitWorkspaceRoot)
        effectiveWorkspaceRoot = try container.decode(String.self, forKey: .effectiveWorkspaceRoot)
        metaPath = try container.decode(String.self, forKey: .metaPath)
        logsPath = try container.decode(String.self, forKey: .logsPath)
        workPath = try container.decode(String.self, forKey: .workPath)
        sharedContextPath = try container.decode(String.self, forKey: .sharedContextPath)
        scratchpadsPath = try container.decode(String.self, forKey: .scratchpadsPath)
        layoutVersion = try container.decode(Int.self, forKey: .layoutVersion)
        gitRepoDetected = try container.decodeIfPresent(Bool.self, forKey: .gitRepoDetected) ?? false
        metadataStatus = try container.decodeIfPresent(SpaceWorkspaceMetadataStatus.self, forKey: .metadataStatus) ?? .unknown
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
}

public struct SpaceConfig: Codable, Sendable {
    public let id: String
    public let spaceUid: String
    public let workspace: SpaceWorkspace?
    public let resourceId: String
    public let name: String
    public let goal: String?
    public let orchestratorProfileId: String?
    public let templateId: String?
    public let turnModel: String
    public let turnModelConfig: [String: AnyCodable]?
    public let skillIds: [String]?
    public let agents: [SpaceAgentAssignment]
    public let capabilities: [String]
    public let capabilityOverrides: [String: String]
    public let maxTurns: Int?
    public let visibility: SpaceVisibility
    public let moderatorProfileId: String?
    public let createdAt: String
    public let updatedAt: String
}

extension SpaceConfig {
    private enum CodingKeys: String, CodingKey {
        case id
        case spaceUid
        case workspace
        case resourceId
        case name
        case goal
        case orchestratorProfileId
        case templateId
        case turnModel
        case turnModelConfig
        case skillIds
        case agents
        case capabilities
        case capabilityOverrides
        case maxTurns
        case visibility
        case moderatorProfileId
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
        self.resourceId = try container.decode(String.self, forKey: .resourceId)
        self.name = try container.decode(String.self, forKey: .name)
        self.goal = try container.decodeIfPresent(String.self, forKey: .goal)
        self.orchestratorProfileId = try container.decodeIfPresent(String.self, forKey: .orchestratorProfileId)
        self.templateId = try container.decodeIfPresent(String.self, forKey: .templateId)
        self.turnModel = try container.decode(String.self, forKey: .turnModel)
        self.turnModelConfig = try container.decodeIfPresent([String: AnyCodable].self, forKey: .turnModelConfig)
        self.skillIds = try container.decodeIfPresent([String].self, forKey: .skillIds)
        self.agents = try container.decodeIfPresent([SpaceAgentAssignment].self, forKey: .agents) ?? []
        self.capabilities = try container.decodeIfPresent([String].self, forKey: .capabilities) ?? []
        self.capabilityOverrides = try container.decodeIfPresent([String: String].self, forKey: .capabilityOverrides) ?? [:]
        self.maxTurns = try container.decodeIfPresent(Int.self, forKey: .maxTurns)
        self.visibility = try container.decodeIfPresent(SpaceVisibility.self, forKey: .visibility) ?? .shared
        self.moderatorProfileId = try container.decodeIfPresent(String.self, forKey: .moderatorProfileId)
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
    public let agentId: String
    public let status: String
    public let inputText: String?
    public let outputText: String?
    public let promptTokens: Int?
    public let completionTokens: Int?
    public let totalTokens: Int?
    public let createdAt: String
    public let completedAt: String?
    public let replyToTurnId: String?
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

public struct SpaceTurnTrace: Codable, Sendable {
    public let spaceId: String
    public let turnId: String
    public let total: Int
    public let events: [SpaceTurnTraceEvent]
    public let toolCalls: [SpaceTurnTraceToolCall]
    public let artifactIds: [String]
}

public struct SpaceGetTurnTraceResult: Codable, Sendable {
    public let trace: SpaceTurnTrace
}

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
}

public struct SpaceListArtifactsResult: Codable, Sendable {
    public let artifacts: [SpaceArtifactSummary]
    public let total: Int
}

public struct SpaceGetArtifactResult: Codable, Sendable {
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
    public let oldProfileId: String
    public let newProfileId: String
    public let updatedAt: String
}

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

public struct ProfileSummary: Codable, Sendable {
    public let profileId: String
    public let name: String
    public let description: String
    public let personalityPrompt: String
    public let defaultSkillIds: [String]
    public let providerHint: String?
    public let modelHint: String?
    public let modelConfig: ProfileModelConfig?
    public let canModerate: Bool
    public let isDefault: Bool
    public let status: String
    public let activeRevision: Int
    public let source: String
    public let createdAt: String
    public let updatedAt: String
}

public struct ProfileCreateResult: Codable, Sendable {
    public let profile: ProfileSummary
    public let created: Bool
}

public struct ProfileUpdateResult: Codable, Sendable {
    public let profile: ProfileSummary
    public let newRevision: Int
}

public struct ProfileArchiveResult: Codable, Sendable {
    public let profile: ProfileSummary
    public let archived: Bool
}

public enum PresetKind: String, Codable, Sendable {
    case agent
    case space
}

public enum PresetSource: String, Codable, Sendable {
    case system
    case user
}

public enum CommunicationMode: String, Codable, Sendable {
    case asyncNotes = "async_notes"
    case chatFirst = "chat_first"
    case structuredHandoff = "structured_handoff"
}

public struct TemplateAgentDefinition: Codable, Sendable {
    public let agentId: String
    public let profileId: String
    public let role: SpaceAssignmentRole?
    public let turnOrder: Int?
    public let isPrimary: Bool?

    public init(
        agentId: String,
        profileId: String,
        role: SpaceAssignmentRole? = nil,
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

public struct SpacePresetConfig: Codable, Sendable {
    public let communicationMode: CommunicationMode
    public let turnModel: String
    public let baseAgents: [TemplateAgentDefinition]
    public let agentPresetIds: [String]
}

public struct AgentPresetConfig: Codable, Sendable {
    public let defaultAgents: [TemplateAgentDefinition]
}

public struct PresetSummary: Codable, Sendable {
    public let presetId: String
    public let kind: PresetKind
    public let title: String
    public let description: String
    public let source: PresetSource
    public let version: Int
    public let tags: [String]
}

public struct PresetDetail: Codable, Sendable {
    public let presetId: String
    public let kind: PresetKind
    public let title: String
    public let description: String
    public let source: PresetSource
    public let version: Int
    public let tags: [String]
    public let spacePreset: SpacePresetConfig?
    public let agentPreset: AgentPresetConfig?
}

public struct PresetApplyToSpaceResult: Codable, Sendable {
    public let applicationId: String
    public let presetId: String
    public let spaceId: String
    public let createdSpace: Bool
    public let appliedAgents: Int
    public let skippedAgents: Int
    public let appliedAt: String
    public let space: SpaceConfig
}

public struct PresetSaveAgentResult: Codable, Sendable {
    public let preset: PresetDetail
    public let created: Bool
}

public struct PresetArchiveAgentResult: Codable, Sendable {
    public let presetId: String
    public let archived: Bool
}

public struct SpaceTemplateSummary: Codable, Sendable {
    public let templateId: String
    public let title: String
    public let communicationMode: CommunicationMode
    public let agentPresetIds: [String]
    public let createdBy: String
    public let updatedAt: String
}

public struct SpaceTemplatePreviewResolved: Codable, Sendable {
    public let templateId: String
    public let templateRevision: Int
    public let name: String
    public let goal: String?
    public let resourceId: String
    public let communicationMode: CommunicationMode
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

public struct DeviceIdentity: Codable, Sendable {
    public let deviceId: String
    public let principalId: String
    public let publicKey: String
    public let platform: String?
    public let keyVersion: String
    public let status: String
    public let createdAt: String
    public let updatedAt: String
    public let lastSeenAt: String?
    public let revokedAt: String?
}

public struct AuthRegisterDeviceResult: Codable, Sendable {
    public let device: DeviceIdentity
    public let created: Bool
}

public struct AuthRotateDeviceKeyResult: Codable, Sendable {
    public let device: DeviceIdentity
}

public struct AuthRevokeDeviceResult: Codable, Sendable {
    public let deviceId: String
    public let revoked: Bool
    public let device: DeviceIdentity?
}

public struct DiscoveredLocalAgent: Codable, Sendable {
    public let id: String
    public let name: String
    public let detected: Bool
    public let executablePath: String?
    public let appPath: String?
    public let serviceReachable: Bool?
    public let recommendedProviderId: String
    public let recommendedModel: String
    public let requiresApiKey: Bool
    public let availableModels: [String]?
    public let detectionError: String?
    public let notes: String?
}

public enum MainAgentSelectionMode: String, Codable, Sendable {
    case providerModel = "provider_model"
    case profileTemplate = "profile_template"
}

public enum GatewayMainAgentStatus: String, Codable, Sendable {
    case healthy
    case repaired
    case fallback
}

public struct GatewayMainAgentState: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let mainAgentId: String
    public let mainProfileId: String
    public let assignedProfileId: String?
    public let providerHint: String?
    public let modelHint: String?
    public let status: GatewayMainAgentStatus
    public let repaired: Bool
    public let fallbackApplied: Bool
    public let fallbackReason: String?
    public let updatedAt: String
}

public struct GatewayProviderRuntimeConfig: Codable, Sendable {
    public let providerId: String
    public let model: String
    public let baseURL: String?
    public let hasApiKey: Bool
    public let apiKeySecretRef: String?
    public let allowedModels: [String]
    public let allowCustomModel: Bool
    public let nativeCliToolsEnabled: Bool
    public let updatedAt: String
    public let source: String

    private enum CodingKeys: String, CodingKey {
        case providerId
        case model
        case baseURL
        case hasApiKey
        case apiKeySecretRef
        case allowedModels
        case allowCustomModel
        case nativeCliToolsEnabled
        case updatedAt
        case source
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.providerId = try container.decode(String.self, forKey: .providerId)
        self.model = try container.decode(String.self, forKey: .model)
        self.baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL)
        self.hasApiKey = try container.decode(Bool.self, forKey: .hasApiKey)
        self.apiKeySecretRef = try container.decodeIfPresent(String.self, forKey: .apiKeySecretRef)
        self.allowedModels = try container.decodeIfPresent([String].self, forKey: .allowedModels) ?? []
        self.allowCustomModel = try container.decodeIfPresent(Bool.self, forKey: .allowCustomModel) ?? true
        self.nativeCliToolsEnabled = try container.decodeIfPresent(Bool.self, forKey: .nativeCliToolsEnabled) ?? false
        self.updatedAt = try container.decode(String.self, forKey: .updatedAt)
        self.source = try container.decode(String.self, forKey: .source)
    }
}

public enum GatewayModelDetectionStatus: String, Codable, Sendable {
    case available
    case unavailable
    case error
}

public enum GatewayModelCatalogSource: String, Codable, Sendable {
    case detected
    case configured
    case fallback
    case allowlist
}

public enum GatewayProviderCatalogGroup: String, Codable, Sendable {
    case cloud
    case executor
    case localRuntime = "local_runtime"
}

public enum GatewayIntegrationClass: String, Codable, Sendable {
    case cloud
    case executor
    case localRuntime = "local_runtime"
}

public enum GatewayIntegrationStatus: String, Codable, Sendable {
    case installed
    case missing
    case needsKey = "needs_key"
    case needsAuth = "needs_auth"
    case reachable
    case noModelsLoaded = "no_models_loaded"
    case policyBlocked = "policy_blocked"
    case unsupported
    case error
}

public struct GatewayModelCatalogEntry: Codable, Sendable {
    public let id: String
    public let displayName: String
    public let source: GatewayModelCatalogSource
    public let available: Bool
    public let contextWindow: Int?
}

public struct GatewayModelProviderCatalog: Codable, Sendable {
    public let providerId: String
    public let displayName: String
    public let group: GatewayProviderCatalogGroup
    public let integrationClass: GatewayIntegrationClass?
    public let status: GatewayIntegrationStatus?
    public let hasApiKey: Bool
    public let requiresApiKey: Bool
    public let baseURL: String?
    public let detectionStatus: GatewayModelDetectionStatus
    public let detectionError: String?
    public let models: [GatewayModelCatalogEntry]
    public let installHint: String?
    public let recommended: Bool
    public let supportsHostedBilling: Bool
    public let configAllowed: Bool

    private enum CodingKeys: String, CodingKey {
        case providerId
        case displayName
        case group
        case integrationClass
        case status
        case hasApiKey
        case requiresApiKey
        case baseURL
        case detectionStatus
        case detectionError
        case models
        case installHint
        case recommended
        case supportsHostedBilling
        case configAllowed
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.providerId = try container.decode(String.self, forKey: .providerId)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? providerId
        self.group = (try? container.decode(GatewayProviderCatalogGroup.self, forKey: .group))
            ?? (try? container.decode(GatewayIntegrationClass.self, forKey: .integrationClass)).map {
                switch $0 {
                case .cloud:
                    return .cloud
                case .executor:
                    return .executor
                case .localRuntime:
                    return .localRuntime
                }
            }
            ?? .cloud
        self.integrationClass = try container.decodeIfPresent(GatewayIntegrationClass.self, forKey: .integrationClass)
        self.status = try container.decodeIfPresent(GatewayIntegrationStatus.self, forKey: .status)
        self.hasApiKey = try container.decode(Bool.self, forKey: .hasApiKey)
        self.requiresApiKey = try container.decode(Bool.self, forKey: .requiresApiKey)
        self.baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL)
        self.detectionStatus = try container.decode(GatewayModelDetectionStatus.self, forKey: .detectionStatus)
        self.detectionError = try container.decodeIfPresent(String.self, forKey: .detectionError)
        self.models = try container.decode([GatewayModelCatalogEntry].self, forKey: .models)
        self.installHint = try container.decodeIfPresent(String.self, forKey: .installHint)
        self.recommended = try container.decodeIfPresent(Bool.self, forKey: .recommended) ?? false
        self.supportsHostedBilling = try container.decodeIfPresent(Bool.self, forKey: .supportsHostedBilling) ?? false
        self.configAllowed = try container.decodeIfPresent(Bool.self, forKey: .configAllowed) ?? true
    }
}

public struct GatewayIntegrationRequest: Codable, Sendable {
    public let integrationRequestId: String
    public let integrationClass: GatewayIntegrationClass
    public let requestedName: String
    public let useCase: String?
    public let sourceURL: String?
    public let notes: String?
    public let principalId: String?
    public let deviceId: String?
    public let status: String
    public let createdAt: String
    public let updatedAt: String
}

public struct GatewaySecretRef: Codable, Sendable {
    public let secretRef: String
    public let providerId: String
    public let label: String
    public let backend: String
    public let createdAt: String
    public let updatedAt: String
    public let lastUsedAt: String?
}

public struct GatewayPutSecretRefResult: Codable, Sendable {
    public let secretRef: GatewaySecretRef
    public let created: Bool
}

public struct GatewayDeleteSecretRefResult: Codable, Sendable {
    public let secretRef: String
    public let deleted: Bool
}

public struct GatewayProvisionLocalProfileResult: Codable, Sendable {
    public let profileId: String
    public let profileName: String
    public let created: Bool
    public let providerId: String
    public let model: String
    public let agentId: String?
    public let assignmentCreated: Bool?
}

public struct GatewayFactoryResetResult: Codable, Sendable {
    public let gatewayId: String
    public let gatewayUuid: String?
    public let resetAt: String
    public let tablesCleared: Int
    public let rowsDeleted: UInt64
}

public struct SpaceResetPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceResetResult: Codable, Sendable {
    public let spaceId: String
    public let resetAt: String
    public let tablesCleared: Int
    public let rowsDeleted: UInt64
}

public enum GatewayConnectorKind: String, Codable, Sendable {
    case channel
    case capability
    case hybrid
}

public enum GatewayConnectorRuntime: String, Codable, Sendable {
    case adapter
    case connector
    case builtin
}

public enum GatewayConnectorTrustClass: String, Codable, Sendable {
    case embeddedSafe = "embedded_safe"
    case externalOnly = "external_only"
}

public enum GatewayConnectorInstanceStatus: String, Codable, Sendable {
    case active
    case paused
    case error
}

public enum GatewayConnectorBindingType: String, Codable, Sendable {
    case inboundRoute = "inbound_route"
    case outboundAction = "outbound_action"
    case capabilityExport = "capability_export"
}

public enum GatewayConnectorBindingTarget: String, Codable, Sendable {
    case mainOrchestrator = "main_orchestrator"
    case spaceOrchestrator = "space_orchestrator"
}

public enum GatewayConnectorAction: String, Codable, Sendable {
    case notify
    case sendMessage = "send_message"
    case sendMedia = "send_media"
    case sendReaction = "send_reaction"
}

public enum GatewayConnectorPolicyScopeType: String, Codable, Sendable {
    case global
    case family
    case instance
}

public enum GatewayConnectorInboundRouteKind: String, Codable, Sendable {
    case binding
    case mainFallback = "main_fallback"
}

public struct GatewayConnectorFamily: Codable, Sendable {
    public let familyId: String
    public let displayName: String
    public let kind: GatewayConnectorKind
    public let runtime: GatewayConnectorRuntime
    public let trustClass: GatewayConnectorTrustClass
    public let embeddedEnabled: Bool
    public let capabilityTypes: [String]
    public let features: [String: AnyCodable]
    public let createdAt: String
    public let updatedAt: String
}

public struct GatewayConnector: Codable, Sendable {
    public let connectorId: String
    public let familyId: String
    public let displayName: String
    public let accountFingerprintHash: String
    public let labelSlug: String
    public let status: GatewayConnectorInstanceStatus
    public let metadata: [String: AnyCodable]
    public let createdAt: String
    public let updatedAt: String
}

public struct GatewayConnectorBinding: Codable, Sendable {
    public let bindingId: String
    public let connectorId: String
    public let bindingType: GatewayConnectorBindingType
    public let selector: [String: AnyCodable]
    public let targetType: GatewayConnectorBindingTarget
    public let targetSpaceId: String?
    public let allowedActions: [GatewayConnectorAction]
    public let capabilityTypes: [String]
    public let priority: Int
    public let enabled: Bool
    public let createdAt: String
    public let updatedAt: String
}

public struct GatewayConnectorPolicy: Codable, Sendable {
    public let scopeType: GatewayConnectorPolicyScopeType
    public let scopeId: String
    public let requestsPerMinute: Int
    public let burst: Int
    public let disabled: Bool
    public let disableReason: String?
    public let disabledUntil: String?
    public let updatedBy: String
    public let updatedAt: String
}

public struct GatewayConnectorInboundRoute: Codable, Sendable {
    public let route: GatewayConnectorInboundRouteKind
    public let targetType: GatewayConnectorBindingTarget
    public let targetSpaceId: String?
    public let bindingId: String?
    public let matchedScore: Double?
}

public struct GatewayTestConnectorResult: Codable, Sendable {
    public let ok: Bool
    public let reason: String?
    public let connector: GatewayConnector?
    public let inboundRoute: GatewayConnectorInboundRoute?
    public let policy: GatewayConnectorPolicy?
}

public enum GatewayCapabilityGrantLevel: String, Codable, Sendable {
    case read
    case write
    case execute
}

public struct GatewayCapabilityGrant: Codable, Sendable {
    public let principalId: String
    public let deviceId: String
    public let capabilityId: String
    public let level: GatewayCapabilityGrantLevel
    public let source: String
    public let reason: String
    public let grantedBy: String
    public let grantedAt: String
    public let expiresAt: String?
    public let revokedAt: String?
    public let updatedAt: String
}

public struct GatewayRevokeCapabilityResult: Codable, Sendable {
    public let revoked: Bool
    public let capabilityId: String
    public let principalId: String
    public let deviceId: String
    public let grant: GatewayCapabilityGrant?
}

public struct ProviderTelemetryWindow: Codable, Sendable {
    public let scopeId: String
    public let scopeName: String?
    public let window: String
    public let usedPercent: Double?
    public let remainingPercent: Double?
    public let resetsAt: String?
    public let windowDurationMins: Int?
}

public struct ProviderTelemetry: Codable, Sendable {
    public let providerId: String
    public let status: String
    public let source: String
    public let fetchedAt: String
    public let message: String?
    public let accountLabel: String?
    public let windows: [ProviderTelemetryWindow]
    public let usage: ProviderUsageSnapshot?
}

public struct LocalUsageInstallHint: Codable, Sendable {
    public let command: String
    public let docsUrl: String
}

public struct LocalUsageWindow: Codable, Sendable {
    public let window: String
    public let label: String
    public let usedPercent: Double?
    public let remainingPercent: Double?
    public let windowMinutes: Int?
    public let resetsAt: String?
    public let resetDescription: String?
}

public struct CodexBarQuota: Codable, Sendable {
    public let available: Bool
    public let sourceLabel: String?
    public let windows: [LocalUsageWindow]
    public let creditsRemaining: Double?
    public let accountLabel: String?
    public let updatedAt: String?
    public let message: String?
    public let installHint: LocalUsageInstallHint?
}

public struct LocalUsageSession: Codable, Sendable {
    public let sessionId: String
    public let model: String?
    public let startedAt: String?
    public let lastActivityAt: String
    public let inputTokens: Int
    public let cachedInputTokens: Int?
    public let outputTokens: Int
    public let totalTokens: Int
    public let estimatedCostUsd: Double?
    public let tokenAccuracy: String
    public let usageSource: String
}

public struct LocalUsageSummary: Codable, Sendable {
    public let windowDays: Int
    public let sessionCount: Int
    public let inputTokens: Int
    public let cachedInputTokens: Int?
    public let outputTokens: Int
    public let totalTokens: Int
    public let estimatedCostUsd: Double?
    public let tokenAccuracy: String
    public let usageSource: String
}

public struct LocalProviderUsageTelemetry: Codable, Sendable {
    public let providerId: String
    public let status: String
    public let fetchedAt: String
    public let message: String?
    public let quota: CodexBarQuota
    public let summary: LocalUsageSummary
    public let sessions: [LocalUsageSession]
}

public struct UsageWindowSummary: Codable, Sendable {
    public let inputTokens: Int
    public let outputTokens: Int
    public let totalTokens: Int
    public let spentUsd: Double
    public let tokenAccuracy: String
    public let usageSource: String
}

public struct BudgetSummary: Codable, Sendable {
    public let softCapUsd: Double
    public let hardCapUsd: Double
    public let warningThreshold: Double
    public let spentUsd: Double
    public let leftUsd: Double
}

public struct ProviderUsageSnapshot: Codable, Sendable {
    public let providerId: String
    public let status: String
    public let inputTokens: Int
    public let outputTokens: Int
    public let totalTokens: Int
    public let spentUsd: Double
    public let tokenAccuracy: String
    public let usageSource: String
    public let message: String?
}

public struct VoiceUsageWindowSummary: Codable, Sendable {
    public let sttSeconds: Double
    public let ttsChars: Int
    public let ttsSeconds: Double
    public let estimatedCostUsd: Double
}

public struct VoiceUsageSourceSummary: Codable, Sendable {
    public let source: String
    public let sttSeconds: Double
    public let ttsChars: Int
    public let ttsSeconds: Double
    public let estimatedCostUsd: Double
}

public struct VoiceUsageLockSummary: Codable, Sendable {
    public let enabled: Bool
    public let managedSttSecondsMonthlyLimit: Double?
    public let managedTtsCharsMonthlyLimit: Double?
    public let managedTtsSecondsMonthlyLimit: Double?
    public let managedCurrentMonthSttSeconds: Double?
    public let managedCurrentMonthTtsChars: Double?
    public let managedCurrentMonthTtsSeconds: Double?
}

public struct VoiceUsageSnapshot: Codable, Sendable {
    public struct Windows: Codable, Sendable {
        public let last5h: VoiceUsageWindowSummary
        public let last7d: VoiceUsageWindowSummary
        public let last30d: VoiceUsageWindowSummary
        public let lifetime: VoiceUsageWindowSummary
    }

    public let windows: Windows
    public let bySource: [VoiceUsageSourceSummary]
    public let lock: VoiceUsageLockSummary?
}

public struct UsageSnapshot: Codable, Sendable {
    public struct Windows: Codable, Sendable {
        public let last5h: UsageWindowSummary
        public let last7d: UsageWindowSummary
        public let last30d: UsageWindowSummary
        public let lifetime: UsageWindowSummary
    }

    public let computedAt: String
    public let currency: String
    public let windows: Windows
    public let budget: BudgetSummary
    public let providerUsage: [ProviderUsageSnapshot]
    public let voice: VoiceUsageSnapshot?
}

public struct GatewayPolicy: Codable, Sendable {
    public let allowedCapabilityTypes: [String]
    public let deniedCapabilityTypes: [String]
    public let allowedSkillIds: [String]
    public let deniedSkillIds: [String]
    public let globalFlags: [String: AnyCodable]
    public let updatedAt: String
}

public struct GatewayPolicyUpdate: Sendable {
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
        globalFlags: [String: Any]? = nil
    ) {
        self.apiVersion = apiVersion
        self.allowedCapabilityTypes = allowedCapabilityTypes
        self.deniedCapabilityTypes = deniedCapabilityTypes
        self.allowedSkillIds = allowedSkillIds
        self.deniedSkillIds = deniedSkillIds
        self.globalFlags = globalFlags?.mapValues { AnyCodable($0) }
    }
}

public enum GatewaySkillStatus: String, Codable, Sendable {
    case active
    case archived
}

public struct GatewaySkillEntry: Codable, Sendable {
    public let skillId: String
    public let name: String
    public let description: String?
    public let contentMarkdown: String
    public let sourceRef: String?
    public let tags: [String]
    public let status: GatewaySkillStatus
    public let createdAt: String
    public let updatedAt: String
}

public struct GatewaySkillUpsertResult: Codable, Sendable {
    public let skill: GatewaySkillEntry
    public let created: Bool
}

public struct GatewaySkillDeleteResult: Codable, Sendable {
    public let skillId: String
    public let deleted: Bool
}

public enum GatewayKnowledgeBaseEntryKind: String, Codable, Sendable {
    case web
    case file
    case folder
}

public enum GatewayKnowledgeBaseScopeType: String, Codable, Sendable {
    case global
    case space
}

public struct GatewayKnowledgeBaseEntry: Codable, Sendable {
    public let entryId: String
    public let name: String
    public let kind: GatewayKnowledgeBaseEntryKind
    public let uri: String
    public let description: String?
    public let tags: [String]
    public let scopeType: GatewayKnowledgeBaseScopeType
    public let spaceId: String?
    public let createdAt: String
    public let updatedAt: String
}

public struct OrchestratorCommandEvent: Codable, Sendable {
    public let status: String
    public let event: [String: AnyCodable]
    public let createdAt: String
}

public struct OrchestratorCommandResult: Codable, Sendable {
  public let commandId: String
  public let correlationId: String
  public let apiVersion: String
    public let commandType: String
    public let targetSpaceId: String
    public let targetAgentId: String?
    public let status: String
    public let result: [String: AnyCodable]?
    public let error: GatewayError?
    public let createdAt: String
  public let updatedAt: String
  public let events: [OrchestratorCommandEvent]
}

public struct OrchestratorSummaryParticipant: Codable, Sendable {
    public let agentId: String
    public let turnOrder: Int
    public let isPrimary: Bool
    public let status: String
    public let promptTokens: Int
    public let completionTokens: Int
    public let finalMessage: String?
    public let error: String?
}

public struct OrchestratorSummaryHighlight: Codable, Sendable {
    public let agentId: String
    public let eventType: String
    public let text: String
    public let timestamp: String
}

public struct OrchestratorSummaryArtifact: Codable, Sendable {
    public let summaryId: String
    public let version: String
    public let spaceId: String
    public let turnId: String
    public let turnModel: String
    public let generatedAt: String
    public let status: String
    public let failureReason: String?
    public let participants: [OrchestratorSummaryParticipant]
    public let highlights: [OrchestratorSummaryHighlight]
    public let finalSummaryText: String
}

public struct OrchestratorEvent: Codable, Sendable {
    public let commandId: String
    public let correlationId: String
    public let status: String
    public let event: [String: AnyCodable]
    public let createdAt: String
    public let eventType: String?
    public let spaceId: String?
    public let spaceUid: String?
    public let turnId: String?
}

public enum SchedulerJobStatus: String, Codable, Sendable {
    case active
    case paused
    case invalid
}

public enum SchedulerRunStatus: String, Codable, Sendable {
    case running
    case completed
    case failed
    case skipped
}

public enum SchedulerRunTrigger: String, Codable, Sendable {
    case scheduled
    case manual
}

public enum SchedulerScheduleKind: String, Codable, Sendable {
    case hourly
    case daily
    case weekly
}

public enum SchedulerActionType: String, Codable, Sendable {
    case spacePrompt = "space_prompt"
}

public struct SchedulerSchedulePreset: Codable, Sendable {
    public let kind: SchedulerScheduleKind
    public let intervalHours: Int?
    public let minute: Int
    public let hour: Int?
    public let daysOfWeek: [Int]?

    public init(
        kind: SchedulerScheduleKind,
        intervalHours: Int? = nil,
        minute: Int,
        hour: Int? = nil,
        daysOfWeek: [Int]? = nil
    ) {
        self.kind = kind
        self.intervalHours = intervalHours
        self.minute = minute
        self.hour = hour
        self.daysOfWeek = daysOfWeek
    }
}

public struct SchedulerAction: Codable, Sendable {
    public let type: SchedulerActionType
    public let promptText: String
    public let targetAgentId: String?

    public init(
        type: SchedulerActionType,
        promptText: String,
        targetAgentId: String? = nil
    ) {
        self.type = type
        self.promptText = promptText
        self.targetAgentId = targetAgentId
    }
}

public struct SchedulerLinkedSpace: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let name: String
    public let isPrimary: Bool
    public let linkedAt: String
}

public struct SchedulerJob: Codable, Sendable {
    public let jobId: String
    public let name: String
    public let status: SchedulerJobStatus
    public let enabled: Bool
    public let cronExpression: String
    public let schedulePreset: SchedulerSchedulePreset
    public let timezone: String
    public let action: SchedulerAction
    public let primarySpaceId: String?
    public let invalidReason: String?
    public let nextRunAt: String?
    public let lastRunAt: String?
    public let lastRunStatus: SchedulerRunStatus?
    public let lastErrorCode: String?
    public let lastErrorMessage: String?
    public let createdByPrincipalId: String
    public let createdAt: String
    public let updatedAt: String
    public let linkedSpaces: [SchedulerLinkedSpace]
}

public struct SchedulerJobRun: Codable, Sendable {
    public let runId: String
    public let jobId: String
    public let trigger: SchedulerRunTrigger
    public let status: SchedulerRunStatus
    public let commandId: String?
    public let scheduledFor: String?
    public let startedAt: String?
    public let finishedAt: String?
    public let skipReason: String?
    public let errorCode: String?
    public let errorMessage: String?
    public let result: [String: AnyCodable]?
}

public struct SchedulerDeleteJobResult: Codable, Sendable {
    public let jobId: String
    public let deleted: Bool
}

public struct SchedulerListRunsResult: Codable, Sendable {
    public let runs: [SchedulerJobRun]
    public let total: Int
    public let nextOffset: Int?
}

public struct SchedulerRunNowResult: Codable, Sendable {
    public let run: SchedulerJobRun
    public let job: SchedulerJob
}

public struct SpaceLinkResult: Codable, Sendable {
    public let sourceSpaceId: String
    public let targetSpaceId: String
    public let mode: String
    public let createdAt: String
    public let updatedAt: String
}

public enum SpaceShareAccessMode: String, Codable, Sendable {
    case readOnly = "read_only"
    case collaborator
}

public struct SpaceInviteLink: Codable, Sendable {
    public let version: String
    public let relayInviteId: String
    public let relayUrl: String
    public let spaceIdHint: String?
    public let spaceUidHint: String?
    public let fallbackGatewayUrl: String?
}

public struct SpaceShareInvite: Codable, Sendable {
    public let inviteId: String
    public let spaceId: String
    public let spaceUid: String?
    public let issuedByPrincipalId: String
    public let mode: SpaceShareAccessMode
    public let status: String
    public let expiresAt: String?
    public let createdAt: String
    public let updatedAt: String
    public let inviteToken: String?
    public let inviteLink: SpaceInviteLink?
}

public struct SpaceParticipant: Codable, Sendable {
    public let participantId: String
    public let spaceId: String
    public let spaceUid: String
    public let principalId: String
    public let principalType: String
    public let mode: SpaceShareAccessMode
    public let status: String
    public let joinedViaInviteId: String?
    public let deviceId: String?
    public let devicePublicKey: String?
    public let joinedAt: String
    public let updatedAt: String
    public let revokedAt: String?
}

public struct SpaceShareRevokeResult: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let inviteId: String?
    public let participantId: String?
    public let revokedInvite: Bool
    public let revokedParticipant: Bool
}

public struct SharedContextRef: Codable, Sendable {
    public let transferId: String
    public let sourceSpaceId: String
    public let targetSpaceId: String
    public let artifactId: String
    public let status: String
    public let denialReason: String?
    public let createdAt: String
    public let appliedAt: String?
}

public struct SpacePullSharedContextResult: Codable, Sendable {
    public struct ImportedArtifact: Codable, Sendable {
        public let sourceArtifactId: String
        public let importedArtifactId: String
    }

    public struct DeniedTransfer: Codable, Sendable {
        public let transferId: String
        public let reason: String
    }

    public let importedArtifacts: [ImportedArtifact]
    public let denied: [DeniedTransfer]
}

public struct SyncResourceRef: Codable, Sendable {
    public let resourceType: String
    public let resourceId: String
    public let title: String?
    public let updatedAt: String?
    public let tags: [String]?
}

public struct SyncResource: Codable, Sendable {
    public let ref: SyncResourceRef
    public let content: [String: AnyCodable]
}

public struct SyncResourceDenied: Codable, Sendable {
    public let ref: SyncResourceRef
    public let reason: String
}

public struct SyncAnnounceResult: Codable, Sendable {
    public let peerId: String
    public let resourceId: String
    public let gatewayVersion: String
    public let syncEnabled: Bool
    public let announcedAt: String
}

public struct SyncQueryResourcesResult: Codable, Sendable {
    public let resources: [SyncResourceRef]
    public let nextCursor: String?
}

public struct SyncPullResourcesResult: Codable, Sendable {
    public let resources: [SyncResource]
    public let denied: [SyncResourceDenied]
    public let appliedCount: Int
    public let skippedCount: Int
}

public struct SpeechSessionEvent: Codable, Sendable {
    public struct UsageMetrics: Codable, Sendable {
        public let sttSeconds: Double
        public let ttsChars: Int
        public let ttsSeconds: Double
    }

    public let sessionId: String
    public let spaceId: String
    public let spaceUid: String
    public let state: String
    public let eventType: String
    public let providerSource: String?
    public let providerId: String?
    public let fallbackReason: String?
    public let usage: UsageMetrics?
    public let lockReason: String?
    public let transcript: String?
    public let turnId: String?
    public let sequence: Int?
    public let reason: String?
    public let ts: String
}

public struct MainSpaceBootstrapOptions: Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let resourceId: String
    public let name: String
    public let goal: String
    public let createIfMissing: Bool
    public let subscribe: Bool
    public let initialAgents: [SpaceCreateInitialAgentPayload]?

    public init(
        apiVersion: String? = nil,
        spaceId: String = "main-space",
        resourceId: String = "resource:main",
        name: String = "Main Space",
        goal: String = "Default shared space for gateway startup and orchestrator coordination.",
        createIfMissing: Bool = true,
        subscribe: Bool = true,
        initialAgents: [SpaceCreateInitialAgentPayload]? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.resourceId = resourceId
        self.name = name
        self.goal = goal
        self.createIfMissing = createIfMissing
        self.subscribe = subscribe
        self.initialAgents = initialAgents
    }
}

public struct MainSpaceBootstrapResult: Sendable {
    public let space: SpaceConfig
    public let created: Bool
    public let subscribed: Bool
}

public struct ConnectAndBootstrapResult: Sendable {
    public let space: SpaceConfig
    public let created: Bool
    public let subscribed: Bool
    public let connected: Bool
}

/// Notification from the gateway.
public struct GatewayNotification: Codable, Sendable {
    public let notificationId: String
    public let category: String
    public let severity: String
    public let title: String
    public let body: String
    public let spaceId: String?
    public let spaceUid: String?
    public let agentId: String?
    public let createdAt: String
}

// MARK: - Inter-Agent Events

/// A direct message between agents in a space.
public struct AgentMessage: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let fromAgentId: String
    public let toAgentId: String
    public let content: String
}

/// An agent poke notification (wake up an idle agent).
public struct AgentPoke: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let targetAgentId: String
    public let reason: String
    public let unblockedByTurnId: String?
}

/// Agent idle notification from the gateway.
public struct AgentIdle: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let agentId: String
    public let idleDurationMs: Double
    public let lastTurnId: String?
}

/// Task dependency resolved notification.
public struct TaskDependencyResolved: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let unblockedTurnId: String
    public let resolvedByTurnId: String
}

/// Error from the gateway.
public struct GatewayError: Codable, Sendable, Error, LocalizedError {
    public let code: String
    public let message: String
    public let details: AnyCodable?
    public let retryable: Bool?
    public let correlationId: String?

    public init(
        code: String,
        message: String,
        details: AnyCodable? = nil,
        retryable: Bool? = nil,
        correlationId: String? = nil
    ) {
        self.code = code
        self.message = message
        self.details = details
        self.retryable = retryable
        self.correlationId = correlationId
    }

    public var errorDescription: String? { "[\(code)] \(message)" }
}

// MARK: - Connection State

/// Current connection state of the client.
public enum ConnectionState: Sendable, Equatable {
    case disconnected
    case connecting
    case authenticating
    case connected
    case reconnecting(attempt: Int)
}

// MARK: - AnyCodable Helper

/// Type-erased Codable wrapper for dynamic JSON values.
public struct AnyCodable: Codable, Equatable, @unchecked Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        deepEqual(lhs.value, rhs.value)
    }

    private static func deepEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        switch (lhs, rhs) {
        case (_ as NSNull, _ as NSNull):
            return true
        case let (l as Bool, r as Bool):
            return l == r
        case let (l as Int, r as Int):
            return l == r
        case let (l as Double, r as Double):
            return l == r
        case let (l as Int, r as Double):
            return Double(l) == r
        case let (l as Double, r as Int):
            return l == Double(r)
        case let (l as String, r as String):
            return l == r
        case let (l as [Any], r as [Any]):
            guard l.count == r.count else { return false }
            for (lv, rv) in zip(l, r) {
                if !deepEqual(lv, rv) {
                    return false
                }
            }
            return true
        case let (l as [String: Any], r as [String: Any]):
            guard l.count == r.count else { return false }
            for (key, lv) in l {
                guard let rv = r[key], deepEqual(lv, rv) else {
                    return false
                }
            }
            return true
        case let (l as [AnyCodable], r as [AnyCodable]):
            return l == r
        case let (l as [String: AnyCodable], r as [String: AnyCodable]):
            guard l.count == r.count else { return false }
            for (key, lv) in l {
                guard let rv = r[key], lv == rv else {
                    return false
                }
            }
            return true
        default:
            return false
        }
    }
}
