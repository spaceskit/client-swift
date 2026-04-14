// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Turn Results

/// Options for executing a turn in a space.
public struct ExecuteTurnOptions: Sendable, Equatable {
    public let spaceUid: String
    public let input: String
    public let targetAgentId: String?
    public let targetAgentIds: [String]?
    public let replyToTurnId: String?
    public let conversationTopology: ConversationTopology?
    public let mode: String?
    public let effort: String?
    public let accessMode: String?

    public init(
        spaceUid: String,
        input: String,
        targetAgentId: String? = nil,
        targetAgentIds: [String]? = nil,
        replyToTurnId: String? = nil,
        conversationTopology: ConversationTopology? = nil,
        mode: String? = nil,
        effort: String? = nil,
        accessMode: String? = nil
    ) {
        self.spaceUid = spaceUid
        self.input = input
        self.targetAgentId = targetAgentId
        self.targetAgentIds = targetAgentIds
        self.replyToTurnId = replyToTurnId
        self.conversationTopology = conversationTopology
        self.mode = mode
        self.effort = effort
        self.accessMode = accessMode
    }
}

/// Result of executing a turn in a space.
public struct TurnResult: Codable, Sendable {
    public let turnId: String
    public let spaceId: String
    public let output: String?
    public let status: TurnStatus
    public let error: String?
    public let mode: String?
    public let effort: String?
    public let accessMode: String?
    public let effectiveAccessMode: String?
    public let effectiveSafetyProfileId: String?

    public enum TurnStatus: String, Codable, Sendable {
        case completed
        case pendingFeedback = "pending_feedback"
        case cancelled
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

public enum ThinkingCapturePolicy: String, Codable, CaseIterable, Sendable {
    case off = "OFF"
    case summary = "SUMMARY"
    case full = "FULL"

    public var title: String {
        switch self {
        case .off:
            return "Off"
        case .summary:
            return "Summarized"
        case .full:
            return "Full"
        }
    }
}

public enum SpaceExperienceCaptureMode: String, Codable, CaseIterable, Sendable {
    case inherit = "INHERIT"
    case enabled = "ENABLED"
    case disabled = "DISABLED"

    public var title: String {
        switch self {
        case .inherit:
            return "Inherit"
        case .enabled:
            return "Enabled"
        case .disabled:
            return "Disabled"
        }
    }
}

public enum SpacePrivacyMode: String, Codable, CaseIterable, Sendable {
    case standard = "STANDARD"
    case incognitoSession = "INCOGNITO_SESSION"

    public var title: String {
        switch self {
        case .standard:
            return "Standard"
        case .incognitoSession:
            return "Incognito"
        }
    }
}

public struct SpaceMemoryPolicy: Codable, Sendable, Equatable {
    public let experienceCapture: SpaceExperienceCaptureMode
    public let privacyMode: SpacePrivacyMode

    public init(
        experienceCapture: SpaceExperienceCaptureMode = .inherit,
        privacyMode: SpacePrivacyMode = .standard
    ) {
        self.experienceCapture = experienceCapture
        self.privacyMode = privacyMode
    }
}

public struct GatewayMemoryDefaults: Codable, Sendable, Equatable {
    public let defaultExperienceCapture: SpaceExperienceCaptureMode
    public let defaultSpacePrivacyMode: SpacePrivacyMode
    public let updatedAt: String

    public init(
        defaultExperienceCapture: SpaceExperienceCaptureMode,
        defaultSpacePrivacyMode: SpacePrivacyMode = .standard,
        updatedAt: String
    ) {
        self.defaultExperienceCapture = defaultExperienceCapture
        self.defaultSpacePrivacyMode = defaultSpacePrivacyMode
        self.updatedAt = updatedAt
    }
}

public enum AgentActivityState: String, Codable, CaseIterable, Sendable {
    case idle
    case thinking
    case acting
    case needsFeedback = "needs_feedback"
    case errored

    public init?(normalizing rawValue: String?) {
        guard let normalized = rawValue?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
            !normalized.isEmpty else {
            return nil
        }

        switch normalized {
        case "idle", "done", "completed", "finished", "stopped", "ready":
            self = .idle
        case "thinking", "reasoning", "planning":
            self = .thinking
        case "acting", "executing", "running_tools", "running-tools", "working", "running", "streaming":
            self = .acting
        case "needs_feedback", "needs-feedback", "needsfeedback",
            "waiting_for_approval", "waiting-for-approval", "awaiting_approval",
            "pending_feedback", "waiting_on_you", "waiting-on-you":
            self = .needsFeedback
        case "errored", "error", "failed":
            self = .errored
        default:
            return nil
        }
    }

    public var isActive: Bool {
        self == .thinking || self == .acting
    }

    public var requiresFeedback: Bool {
        self == .needsFeedback
    }
}

// MARK: - Gateway Events

/// A turn lifecycle event from the gateway.
public struct TurnEvent: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let turnId: String
    public let rootTurnId: String?
    public let conversationTopology: ConversationTopology?
    public let transcriptVisibility: TranscriptVisibility?
    public let summaryTurnId: String?
    public let eventType: String
    public let agentId: String?
    public let seq: Int?
    public let data: AnyCodable?
    public let typedPayload: TypedTurnEventPayload?
    public let timestamp: String?

    public init(
        spaceId: String,
        spaceUid: String,
        turnId: String,
        rootTurnId: String? = nil,
        conversationTopology: ConversationTopology? = nil,
        transcriptVisibility: TranscriptVisibility? = nil,
        summaryTurnId: String? = nil,
        eventType: String,
        agentId: String? = nil,
        seq: Int? = nil,
        data: AnyCodable? = nil,
        typedPayload: TypedTurnEventPayload? = nil,
        timestamp: String? = nil
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.turnId = turnId
        self.rootTurnId = rootTurnId
        self.conversationTopology = conversationTopology
        self.transcriptVisibility = transcriptVisibility
        self.summaryTurnId = summaryTurnId
        self.eventType = eventType
        self.agentId = agentId
        self.seq = seq
        self.data = data
        self.typedPayload = typedPayload
        self.timestamp = timestamp
    }

    private enum CodingKeys: String, CodingKey {
        case spaceId
        case spaceUid
        case turnId
        case rootTurnId
        case conversationTopology
        case transcriptVisibility
        case summaryTurnId
        case eventType
        case agentId
        case seq
        case data
        case typedPayload
        case timestamp
        case event
        case ts
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
        let rootTurnId = try? container.decodeIfPresent(String.self, forKey: .rootTurnId)
        let conversationTopology = try? container.decodeIfPresent(ConversationTopology.self, forKey: .conversationTopology)
        let transcriptVisibility = try? container.decodeIfPresent(TranscriptVisibility.self, forKey: .transcriptVisibility)
        let summaryTurnId = try? container.decodeIfPresent(String.self, forKey: .summaryTurnId)
        let agentId = try? container.decodeIfPresent(String.self, forKey: .agentId)
        let seq = try? container.decodeIfPresent(Int.self, forKey: .seq)
        let timestamp = (try? container.decode(String.self, forKey: .timestamp))
            ?? (try? container.decode(String.self, forKey: .ts))
        let typedPayload = try? container.decodeIfPresent(TypedTurnEventPayload.self, forKey: .typedPayload)

        // Current protocol shape.
        if let eventType = try? container.decode(String.self, forKey: .eventType) {
            let data = try container.decodeIfPresent(AnyCodable.self, forKey: .data)
            self.init(
                spaceId: normalizedSpaceId,
                spaceUid: normalizedSpaceUid,
                turnId: turnId,
                rootTurnId: rootTurnId,
                conversationTopology: conversationTopology,
                transcriptVisibility: transcriptVisibility,
                summaryTurnId: summaryTurnId,
                eventType: eventType,
                agentId: agentId,
                seq: seq,
                data: data,
                typedPayload: typedPayload,
                timestamp: timestamp
            )
            return
        }

        // Compatibility for gateway-internal event envelope shape.
        if let event = try? container.decode(AnyCodable.self, forKey: .event) {
            let mappedEventType = Self.mapEventType(from: event.value) ?? "started"
            let mappedAgentId = agentId ?? Self.extractAgentId(from: event.value)
            self.init(
                spaceId: normalizedSpaceId,
                spaceUid: normalizedSpaceUid,
                turnId: turnId,
                rootTurnId: rootTurnId,
                conversationTopology: conversationTopology,
                transcriptVisibility: transcriptVisibility,
                summaryTurnId: summaryTurnId,
                eventType: mappedEventType,
                agentId: mappedAgentId,
                seq: seq,
                data: event,
                typedPayload: typedPayload,
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
                rootTurnId: rootTurnId,
                conversationTopology: conversationTopology,
                transcriptVisibility: transcriptVisibility,
                summaryTurnId: summaryTurnId,
                eventType: "started",
                agentId: agentId,
                seq: seq,
                data: nil,
                typedPayload: typedPayload,
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
        try container.encodeIfPresent(rootTurnId, forKey: .rootTurnId)
        try container.encodeIfPresent(conversationTopology, forKey: .conversationTopology)
        try container.encodeIfPresent(transcriptVisibility, forKey: .transcriptVisibility)
        try container.encodeIfPresent(summaryTurnId, forKey: .summaryTurnId)
        try container.encode(eventType, forKey: .eventType)
        try container.encodeIfPresent(agentId, forKey: .agentId)
        try container.encodeIfPresent(seq, forKey: .seq)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(typedPayload, forKey: .typedPayload)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
    }

    private static func mapEventType(from eventValue: Any) -> String? {
        guard let event = eventValue as? [String: Any],
              let type = event["type"] as? String else {
            return nil
        }

        switch type {
        case "turn_started":
            return "started"
        case "text_delta":
            return "streaming"
        case "reasoning_delta":
            return "streaming"
        case "tool_call", "tool_call_start", "tool_result":
            return "tool_call"
        case "feedback_requested":
            return "feedback_requested"
        case "feedback_resolved", "context_summarizing", "context_summarized":
            return "streaming"
        case "rate_limited":
            return "rate_limited"
        case "state_changed":
            return "state_changed"
        case "turn_completed":
            return "completed"
        case "error":
            return "failed"
        default:
            return "started"
        }
    }

    private static func extractAgentId(from eventValue: Any) -> String? {
        guard let event = eventValue as? [String: Any] else {
            return nil
        }
        if let agentId = event["agentId"] as? String, !agentId.isEmpty {
            return agentId
        }
        if let result = event["result"] as? [String: Any],
           let agentId = result["agentId"] as? String,
           !agentId.isEmpty {
            return agentId
        }
        return nil
    }

    // MARK: - Convenience Accessors (try typedPayload first, fall back to data)

    public var resolvedAgentActivityState: AgentActivityState? {
        if case .stateChanged(let payload) = typedPayload {
            return payload.state
        }
        if let dict = data?.value as? [String: Any] {
            return AgentActivityState(normalizing: dict["state"] as? String)
        }
        return nil
    }

    /// The resolved agent state, from typedPayload or data dictionary.
    public var resolvedAgentState: String? {
        resolvedAgentActivityState?.rawValue
    }

    /// Tool call ID from typedPayload, if this is a tool event.
    public var resolvedToolCallId: String? {
        switch typedPayload {
        case .toolStarted(let p): return p.toolCallId
        case .toolCompleted(let p): return p.toolCallId
        default: break
        }
        if let dict = data?.value as? [String: Any] {
            return (dict["toolCallId"] as? String) ?? (dict["id"] as? String)
        }
        return nil
    }

    /// Tool name from typedPayload.
    public var resolvedToolName: String? {
        switch typedPayload {
        case .toolStarted(let p): return p.toolName
        case .toolCompleted(let p): return p.toolName
        default: break
        }
        if let dict = data?.value as? [String: Any] {
            return (dict["toolName"] as? String) ?? (dict["name"] as? String)
        }
        return nil
    }

    /// Error message from typedPayload.
    public var resolvedErrorMessage: String? {
        if case .turnFailed(let p) = typedPayload { return p.errorMessage }
        if let dict = data?.value as? [String: Any] {
            return (dict["message"] as? String) ?? (dict["error"] as? String)
        }
        return nil
    }

    /// Structured usage from typedPayload.
    public var resolvedUsage: TurnUsagePayload? {
        if case .turnCompleted(let p) = typedPayload { return p.usage }
        return nil
    }

    /// Structured metadata from typedPayload.
    public var resolvedMetadata: TurnMetadataPayload? {
        if case .turnCompleted(let p) = typedPayload { return p.metadata }
        return nil
    }
}

/// A streaming text delta from an agent turn.
public struct TurnStream: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let turnId: String
    public let rootTurnId: String?
    public let agentId: String
    public let conversationTopology: ConversationTopology?
    public let transcriptVisibility: TranscriptVisibility?
    public let summaryTurnId: String?
    public let streamKind: TurnStreamKind?
    public let delta: String
    public let seq: Int
    public let done: Bool
    public let timestamp: String?

    public init(
        spaceId: String,
        spaceUid: String,
        turnId: String,
        rootTurnId: String? = nil,
        agentId: String,
        conversationTopology: ConversationTopology? = nil,
        transcriptVisibility: TranscriptVisibility? = nil,
        summaryTurnId: String? = nil,
        streamKind: TurnStreamKind? = nil,
        delta: String,
        seq: Int,
        done: Bool,
        timestamp: String? = nil
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.turnId = turnId
        self.rootTurnId = rootTurnId
        self.agentId = agentId
        self.conversationTopology = conversationTopology
        self.transcriptVisibility = transcriptVisibility
        self.summaryTurnId = summaryTurnId
        self.streamKind = streamKind
        self.delta = delta
        self.seq = seq
        self.done = done
        self.timestamp = timestamp
    }

    private enum CodingKeys: String, CodingKey {
        case spaceId
        case spaceUid
        case turnId
        case rootTurnId
        case agentId
        case conversationTopology
        case transcriptVisibility
        case summaryTurnId
        case streamKind
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
        let rootTurnId = try? container.decodeIfPresent(String.self, forKey: .rootTurnId)
        let conversationTopology = try? container.decodeIfPresent(ConversationTopology.self, forKey: .conversationTopology)
        let transcriptVisibility = try? container.decodeIfPresent(TranscriptVisibility.self, forKey: .transcriptVisibility)
        let summaryTurnId = try? container.decodeIfPresent(String.self, forKey: .summaryTurnId)
        let streamKind = try? container.decodeIfPresent(TurnStreamKind.self, forKey: .streamKind)
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
                rootTurnId: rootTurnId,
                agentId: agentId,
                conversationTopology: conversationTopology,
                transcriptVisibility: transcriptVisibility,
                summaryTurnId: summaryTurnId,
                streamKind: streamKind,
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
                rootTurnId: rootTurnId,
                agentId: agentId,
                conversationTopology: conversationTopology,
                transcriptVisibility: transcriptVisibility,
                summaryTurnId: summaryTurnId,
                streamKind: streamKind,
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
        try container.encodeIfPresent(rootTurnId, forKey: .rootTurnId)
        try container.encode(agentId, forKey: .agentId)
        try container.encodeIfPresent(conversationTopology, forKey: .conversationTopology)
        try container.encodeIfPresent(transcriptVisibility, forKey: .transcriptVisibility)
        try container.encodeIfPresent(summaryTurnId, forKey: .summaryTurnId)
        try container.encodeIfPresent(streamKind, forKey: .streamKind)
        try container.encode(delta, forKey: .delta)
        try container.encode(seq, forKey: .seq)
        try container.encode(done, forKey: .done)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
    }
}

// MARK: - Typed Turn Event Payloads

/// Structured turn usage information.
public struct TurnUsagePayload: Codable, Sendable, Equatable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int
}

/// Structured turn metadata.
public struct TurnMetadataPayload: Codable, Sendable, Equatable {
    public let modelId: String?
    public let providerId: String?
    public let durationMs: Int?
    public let finishReason: String?
    public let startedAt: String?
    public let completedAt: String?
    public let tokensPerSecond: Double?
}

public struct TurnStartedPayload: Codable, Sendable, Equatable {
    public let agentId: String
    public let turnId: String
    public let rootTurnId: String?
    public let conversationTopology: String?
    public let transcriptVisibility: String?
}

public struct TurnCompletedPayload: Codable, Sendable, Equatable {
    public let agentId: String
    public let usage: TurnUsagePayload?
    public let metadata: TurnMetadataPayload?
    public let finalMessage: String?
    public let effectiveSafetyProfileId: String?
}

public struct TurnCancelledPayload: Codable, Sendable, Equatable {
    public let agentId: String?
}

public struct TurnFailedPayload: Codable, Sendable, Equatable {
    public let errorMessage: String
    public let errorCode: String?
}

public struct ReasoningDeltaPayload: Codable, Sendable, Equatable {
    public let text: String
}

public struct ToolStartedPayload: Codable, Sendable, Equatable {
    public let toolCallId: String
    public let toolName: String
    public let arguments: AnyCodable?
    public let agentId: String?
}

public struct ToolCompletedPayload: Codable, Sendable, Equatable {
    public let toolCallId: String
    public let toolName: String?
    public let result: AnyCodable?
    public let isError: Bool
    public let agentId: String?
}

public struct StateChangedPayload: Codable, Sendable, Equatable {
    public let state: AgentActivityState

    public init(state: AgentActivityState) {
        self.state = state
    }

    private enum CodingKeys: String, CodingKey {
        case state
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawState = try container.decode(String.self, forKey: .state)
        guard let state = AgentActivityState(normalizing: rawState) else {
            throw DecodingError.dataCorruptedError(
                forKey: .state,
                in: container,
                debugDescription: "Unknown agent activity state: \(rawState)"
            )
        }
        self.state = state
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(state.rawValue, forKey: .state)
    }
}

public struct ApprovalRequestedPayload: Codable, Sendable, Equatable {
    public let requestId: String
    public let agentId: String
    public let description: String
    public let options: [String]
    public let context: AnyCodable?
}

public struct ApprovalResolvedPayload: Codable, Sendable, Equatable {
    public let requestId: String
    public let response: String
    public let agentId: String?
}

public struct RateLimitedPayload: Codable, Sendable, Equatable {
    public let retryAfterMs: Int
    public let attempt: Int
    public let maxAttempts: Int
    public let providerId: String
    public let retryAt: String
}

/// Discriminated union of typed turn event payloads, decoded via the `kind` field.
public enum TypedTurnEventPayload: Sendable, Equatable {
    case turnStarted(TurnStartedPayload)
    case turnCompleted(TurnCompletedPayload)
    case turnCancelled(TurnCancelledPayload)
    case turnFailed(TurnFailedPayload)
    case reasoningDelta(ReasoningDeltaPayload)
    case toolStarted(ToolStartedPayload)
    case toolCompleted(ToolCompletedPayload)
    case stateChanged(StateChangedPayload)
    case approvalRequested(ApprovalRequestedPayload)
    case approvalResolved(ApprovalResolvedPayload)
    case rateLimited(RateLimitedPayload)
}

extension TypedTurnEventPayload: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        let singleValueContainer = try decoder.singleValueContainer()

        switch kind {
        case "turn.started":
            self = .turnStarted(try singleValueContainer.decode(TurnStartedPayload.self))
        case "turn.completed":
            self = .turnCompleted(try singleValueContainer.decode(TurnCompletedPayload.self))
        case "turn.cancelled":
            self = .turnCancelled(try singleValueContainer.decode(TurnCancelledPayload.self))
        case "turn.failed":
            self = .turnFailed(try singleValueContainer.decode(TurnFailedPayload.self))
        case "reasoning.delta":
            self = .reasoningDelta(try singleValueContainer.decode(ReasoningDeltaPayload.self))
        case "tool.started":
            self = .toolStarted(try singleValueContainer.decode(ToolStartedPayload.self))
        case "tool.completed":
            self = .toolCompleted(try singleValueContainer.decode(ToolCompletedPayload.self))
        case "state.changed":
            self = .stateChanged(try singleValueContainer.decode(StateChangedPayload.self))
        case "approval.requested":
            self = .approvalRequested(try singleValueContainer.decode(ApprovalRequestedPayload.self))
        case "approval.resolved":
            self = .approvalResolved(try singleValueContainer.decode(ApprovalResolvedPayload.self))
        case "rate_limited":
            self = .rateLimited(try singleValueContainer.decode(RateLimitedPayload.self))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .kind,
                in: container,
                debugDescription: "Unknown typed payload kind: \(kind)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        // Encode the case payload — the kind field is embedded in each payload struct
        switch self {
        case .turnStarted(let p): try p.encode(to: encoder)
        case .turnCompleted(let p): try p.encode(to: encoder)
        case .turnCancelled(let p): try p.encode(to: encoder)
        case .turnFailed(let p): try p.encode(to: encoder)
        case .reasoningDelta(let p): try p.encode(to: encoder)
        case .toolStarted(let p): try p.encode(to: encoder)
        case .toolCompleted(let p): try p.encode(to: encoder)
        case .stateChanged(let p): try p.encode(to: encoder)
        case .approvalRequested(let p): try p.encode(to: encoder)
        case .approvalResolved(let p): try p.encode(to: encoder)
        case .rateLimited(let p): try p.encode(to: encoder)
        }
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

    public var resolvedAgentActivityState: AgentActivityState? {
        AgentActivityState(normalizing: state)
    }
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
    public let agentDefinitionId: String
    public let profileId: String
    public let safetyProfileId: String?
    public let toolPolicyOverride: ToolAccessPolicy?
    public let effectiveToolAccess: EffectiveToolAccess?
    public let securityScope: [String: AnyCodable]?
    public let spawnContext: String?
    public let contextOverrides: [String: AnyCodable]?
    public let role: SpaceAssignmentRole
    public let turnOrder: Int
    public let isPrimary: Bool
    public let assignedAt: String

    private enum CodingKeys: String, CodingKey {
        case spaceId
        case agentId
        case agentDefinitionId
        case profileId
        case safetyProfileId
        case toolPolicyOverride
        case effectiveToolAccess
        case securityScope
        case spawnContext
        case contextOverrides
        case role
        case turnOrder
        case isPrimary
        case assignedAt
    }

    public init(
        spaceId: String,
        agentId: String,
        agentDefinitionId: String? = nil,
        profileId: String? = nil,
        safetyProfileId: String? = nil,
        toolPolicyOverride: ToolAccessPolicy? = nil,
        effectiveToolAccess: EffectiveToolAccess? = nil,
        securityScope: [String: AnyCodable]? = nil,
        spawnContext: String? = nil,
        contextOverrides: [String: AnyCodable]? = nil,
        role: SpaceAssignmentRole,
        turnOrder: Int,
        isPrimary: Bool,
        assignedAt: String
    ) {
        let resolvedAgentDefinitionId = agentDefinitionId ?? profileId ?? ""
        let resolvedProfileId = profileId ?? resolvedAgentDefinitionId
        self.spaceId = spaceId
        self.agentId = agentId
        self.agentDefinitionId = resolvedAgentDefinitionId
        self.profileId = resolvedProfileId
        self.safetyProfileId = safetyProfileId
        self.toolPolicyOverride = toolPolicyOverride
        self.effectiveToolAccess = effectiveToolAccess
        self.securityScope = securityScope
        self.spawnContext = spawnContext
        self.contextOverrides = contextOverrides
        self.role = role
        self.turnOrder = turnOrder
        self.isPrimary = isPrimary
        self.assignedAt = assignedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let spaceId = try container.decode(String.self, forKey: .spaceId)
        let agentId = try container.decode(String.self, forKey: .agentId)
        let decodedAgentDefinitionId = try container.decodeIfPresent(String.self, forKey: .agentDefinitionId)
        let decodedProfileId = try container.decodeIfPresent(String.self, forKey: .profileId)
        let resolvedAgentDefinitionId = decodedAgentDefinitionId ?? decodedProfileId ?? ""
        let resolvedProfileId = decodedProfileId ?? resolvedAgentDefinitionId
        guard !resolvedAgentDefinitionId.isEmpty else {
            throw DecodingError.keyNotFound(
                CodingKeys.agentDefinitionId,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "SpaceAgentAssignment requires agentDefinitionId or profileId"
                )
            )
        }

        self.init(
            spaceId: spaceId,
            agentId: agentId,
            agentDefinitionId: resolvedAgentDefinitionId,
            profileId: resolvedProfileId,
            safetyProfileId: try container.decodeIfPresent(String.self, forKey: .safetyProfileId),
            toolPolicyOverride: try container.decodeIfPresent(ToolAccessPolicy.self, forKey: .toolPolicyOverride),
            effectiveToolAccess: try container.decodeIfPresent(EffectiveToolAccess.self, forKey: .effectiveToolAccess),
            securityScope: try container.decodeIfPresent([String: AnyCodable].self, forKey: .securityScope),
            spawnContext: try container.decodeIfPresent(String.self, forKey: .spawnContext),
            contextOverrides: try container.decodeIfPresent([String: AnyCodable].self, forKey: .contextOverrides),
            role: try container.decodeIfPresent(SpaceAssignmentRole.self, forKey: .role) ?? .participant,
            turnOrder: try container.decodeIfPresent(Int.self, forKey: .turnOrder) ?? 0,
            isPrimary: try container.decodeIfPresent(Bool.self, forKey: .isPrimary) ?? false,
            assignedAt: try container.decode(String.self, forKey: .assignedAt)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(spaceId, forKey: .spaceId)
        try container.encode(agentId, forKey: .agentId)
        try container.encode(agentDefinitionId, forKey: .agentDefinitionId)
        try container.encode(profileId, forKey: .profileId)
        try container.encodeIfPresent(safetyProfileId, forKey: .safetyProfileId)
        try container.encodeIfPresent(toolPolicyOverride, forKey: .toolPolicyOverride)
        try container.encodeIfPresent(effectiveToolAccess, forKey: .effectiveToolAccess)
        try container.encodeIfPresent(securityScope, forKey: .securityScope)
        try container.encodeIfPresent(spawnContext, forKey: .spawnContext)
        try container.encodeIfPresent(contextOverrides, forKey: .contextOverrides)
        try container.encode(role, forKey: .role)
        try container.encode(turnOrder, forKey: .turnOrder)
        try container.encode(isPrimary, forKey: .isPrimary)
        try container.encode(assignedAt, forKey: .assignedAt)
    }
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
    public let artifactsPath: String
    public let layoutVersion: Int
    public let gitRepoDetected: Bool
    public let metadataStatus: SpaceWorkspaceMetadataStatus
    public let discoveredProjectFiles: [String]
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
        case artifactsPath
        case layoutVersion
        case gitRepoDetected
        case metadataStatus
        case discoveredProjectFiles
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
        artifactsPath: String,
        layoutVersion: Int,
        gitRepoDetected: Bool = false,
        metadataStatus: SpaceWorkspaceMetadataStatus = .unknown,
        discoveredProjectFiles: [String] = [],
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
        self.artifactsPath = artifactsPath
        self.layoutVersion = layoutVersion
        self.gitRepoDetected = gitRepoDetected
        self.metadataStatus = metadataStatus
        self.discoveredProjectFiles = discoveredProjectFiles
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        spaceId = try container.decode(String.self, forKey: .spaceId)
        let decodedSpaceUid = try container.decodeIfPresent(String.self, forKey: .spaceUid)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        spaceUid = (decodedSpaceUid?.isEmpty == false ? decodedSpaceUid : nil) ?? spaceId
        explicitWorkspaceRoot = try container.decodeIfPresent(String.self, forKey: .explicitWorkspaceRoot)
        let decodedEffectiveWorkspaceRoot = try container.decodeIfPresent(
            String.self,
            forKey: .effectiveWorkspaceRoot
        )?.trimmingCharacters(in: .whitespacesAndNewlines)
        let decodedMetaPath = try container.decodeIfPresent(String.self, forKey: .metaPath)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        effectiveWorkspaceRoot = Self.resolveEffectiveWorkspaceRoot(
            decodedEffectiveWorkspaceRoot,
            explicitWorkspaceRoot: explicitWorkspaceRoot,
            metaPath: decodedMetaPath
        )
        let resolvedMetaPath = Self.resolveMetaPath(
            decodedMetaPath,
            effectiveWorkspaceRoot: effectiveWorkspaceRoot
        )
        metaPath = resolvedMetaPath
        logsPath = Self.resolvePath(
            try container.decodeIfPresent(String.self, forKey: .logsPath),
            fallbackBasePath: resolvedMetaPath,
            component: "logs"
        )
        workPath = Self.resolvePath(
            try container.decodeIfPresent(String.self, forKey: .workPath),
            fallbackBasePath: resolvedMetaPath,
            component: "work"
        )
        sharedContextPath = Self.resolvePath(
            try container.decodeIfPresent(String.self, forKey: .sharedContextPath),
            fallbackBasePath: resolvedMetaPath,
            component: "shared-context"
        )
        scratchpadsPath = Self.resolvePath(
            try container.decodeIfPresent(String.self, forKey: .scratchpadsPath),
            fallbackBasePath: resolvedMetaPath,
            component: "scratchpads"
        )
        artifactsPath = Self.resolvePath(
            try container.decodeIfPresent(String.self, forKey: .artifactsPath),
            fallbackBasePath: resolvedMetaPath,
            component: "artifacts"
        )
        layoutVersion = try container.decodeIfPresent(Int.self, forKey: .layoutVersion) ?? 2
        gitRepoDetected = try container.decodeIfPresent(Bool.self, forKey: .gitRepoDetected) ?? false
        metadataStatus = try container.decodeIfPresent(SpaceWorkspaceMetadataStatus.self, forKey: .metadataStatus) ?? .unknown
        discoveredProjectFiles = try container.decodeIfPresent([String].self, forKey: .discoveredProjectFiles) ?? []
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
            ?? ISO8601DateFormatter().string(from: Date())
        mode = try container.decodeIfPresent(String.self, forKey: .mode)
            ?? (explicitWorkspaceRoot == nil ? "managed" : "folder_bound")
    }

    private static func resolveEffectiveWorkspaceRoot(
        _ decodedEffectiveWorkspaceRoot: String?,
        explicitWorkspaceRoot: String?,
        metaPath: String?
    ) -> String {
        if let decodedEffectiveWorkspaceRoot, !decodedEffectiveWorkspaceRoot.isEmpty {
            return decodedEffectiveWorkspaceRoot
        }
        if let explicitWorkspaceRoot, !explicitWorkspaceRoot.isEmpty {
            return explicitWorkspaceRoot
        }
        if let metaPath, !metaPath.isEmpty {
            return (metaPath as NSString).deletingLastPathComponent
        }
        return ""
    }

    private static func resolveMetaPath(
        _ decodedMetaPath: String?,
        effectiveWorkspaceRoot: String
    ) -> String {
        if let decodedMetaPath, !decodedMetaPath.isEmpty {
            return decodedMetaPath
        }
        guard !effectiveWorkspaceRoot.isEmpty else { return ".space" }
        return (effectiveWorkspaceRoot as NSString).appendingPathComponent(".space")
    }

    private static func resolvePath(
        _ decodedPath: String?,
        fallbackBasePath: String,
        component: String
    ) -> String {
        let trimmedPath = decodedPath?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedPath, !trimmedPath.isEmpty {
            return trimmedPath
        }
        return (fallbackBasePath as NSString).appendingPathComponent(component)
    }
}

public struct GatewayWorkspaceDefaults: Codable, Sendable {
    public let spaceHomeRoot: String
    public let updatedAt: String

    public init(spaceHomeRoot: String, updatedAt: String) {
        self.spaceHomeRoot = spaceHomeRoot
        self.updatedAt = updatedAt
    }
}

public struct GatewayExternalConnectivitySettings: Codable, Sendable {
    public let mode: String
    public let updatedAt: String

    public init(mode: String, updatedAt: String) {
        self.mode = mode
        self.updatedAt = updatedAt
    }
}

public struct GatewayExternalConnectivityAdvertisedEndpoint: Codable, Sendable {
    public let provider: String
    public let label: String
    public let host: String
    public let port: Int
    public let websocketUrl: String
    public let healthUrl: String

    public init(
        provider: String,
        label: String,
        host: String,
        port: Int,
        websocketUrl: String,
        healthUrl: String
    ) {
        self.provider = provider
        self.label = label
        self.host = host
        self.port = port
        self.websocketUrl = websocketUrl
        self.healthUrl = healthUrl
    }
}

public struct GatewayExternalConnectivityTailscaleStatus: Codable, Sendable {
    public let cliAvailable: Bool
    public let version: String?
    public let backendState: String?
    public let health: [String]
    public let hostName: String?
    public let dnsName: String?
    public let magicDnsSuffix: String?
    public let tailscaleIps: [String]
    public let serveConfigured: Bool
    public let serveTarget: String?
    public let servePort: Int?

    public init(
        cliAvailable: Bool,
        version: String? = nil,
        backendState: String? = nil,
        health: [String],
        hostName: String? = nil,
        dnsName: String? = nil,
        magicDnsSuffix: String? = nil,
        tailscaleIps: [String],
        serveConfigured: Bool,
        serveTarget: String? = nil,
        servePort: Int? = nil
    ) {
        self.cliAvailable = cliAvailable
        self.version = version
        self.backendState = backendState
        self.health = health
        self.hostName = hostName
        self.dnsName = dnsName
        self.magicDnsSuffix = magicDnsSuffix
        self.tailscaleIps = tailscaleIps
        self.serveConfigured = serveConfigured
        self.serveTarget = serveTarget
        self.servePort = servePort
    }
}

public struct GatewayExternalConnectivityStatus: Codable, Sendable {
    public let state: String
    public let summary: String
    public let remediation: String?
    public let advertisedEndpoints: [GatewayExternalConnectivityAdvertisedEndpoint]
    public let tailscaleStatus: GatewayExternalConnectivityTailscaleStatus?

    public init(
        state: String,
        summary: String,
        remediation: String? = nil,
        advertisedEndpoints: [GatewayExternalConnectivityAdvertisedEndpoint],
        tailscaleStatus: GatewayExternalConnectivityTailscaleStatus? = nil
    ) {
        self.state = state
        self.summary = summary
        self.remediation = remediation
        self.advertisedEndpoints = advertisedEndpoints
        self.tailscaleStatus = tailscaleStatus
    }
}

public enum SpaceOpenWorkspaceStatus: String, Codable, Sendable {
    case openedExisting = "opened_existing"
    case createdNew = "created_new"
    case unbound
    case conflict
}

public struct SpaceOpenWorkspaceConflict: Codable, Sendable {
    public let reason: String
    public let message: String
    public let workspaceRoot: String
    public let metadataPath: String?
    public let existingSpaceId: String?
    public let existingSpaceUid: String?
    public let existingWorkspaceRoot: String?
    public let requestedSpaceId: String?
    public let requestedSpaceUid: String?

    public init(
        reason: String,
        message: String,
        workspaceRoot: String,
        metadataPath: String? = nil,
        existingSpaceId: String? = nil,
        existingSpaceUid: String? = nil,
        existingWorkspaceRoot: String? = nil,
        requestedSpaceId: String? = nil,
        requestedSpaceUid: String? = nil
    ) {
        self.reason = reason
        self.message = message
        self.workspaceRoot = workspaceRoot
        self.metadataPath = metadataPath
        self.existingSpaceId = existingSpaceId
        self.existingSpaceUid = existingSpaceUid
        self.existingWorkspaceRoot = existingWorkspaceRoot
        self.requestedSpaceId = requestedSpaceId
        self.requestedSpaceUid = requestedSpaceUid
    }
}

public struct SpaceOpenWorkspaceResult: Codable, Sendable {
    public let status: SpaceOpenWorkspaceStatus
    public let workspaceRoot: String
    public let gitRepoDetected: Bool
    public let hasSpaceMetadata: Bool
    public let space: SpaceConfig?
    public let workspace: SpaceWorkspace?
    public let conflict: SpaceOpenWorkspaceConflict?

    public init(
        status: SpaceOpenWorkspaceStatus,
        workspaceRoot: String,
        gitRepoDetected: Bool,
        hasSpaceMetadata: Bool,
        space: SpaceConfig? = nil,
        workspace: SpaceWorkspace? = nil,
        conflict: SpaceOpenWorkspaceConflict? = nil
    ) {
        self.status = status
        self.workspaceRoot = workspaceRoot
        self.gitRepoDetected = gitRepoDetected
        self.hasSpaceMetadata = hasSpaceMetadata
        self.space = space
        self.workspace = workspace
        self.conflict = conflict
    }
}

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
    public let modelHint: String?
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
    public let version: String?
    public let resolutionSource: GatewayExecutableResolutionSource
    public let manualPathConfigured: Bool
    public let serviceReachable: Bool?
    public let recommendedProviderId: String
    public let recommendedModel: String
    public let requiresApiKey: Bool
    public let availableModels: [String]?
    public let detectionError: String?
    public let notes: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case detected
        case executablePath
        case appPath
        case version
        case resolutionSource
        case manualPathConfigured
        case serviceReachable
        case recommendedProviderId
        case recommendedModel
        case requiresApiKey
        case availableModels
        case detectionError
        case notes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.detected = try container.decode(Bool.self, forKey: .detected)
        self.executablePath = try container.decodeIfPresent(String.self, forKey: .executablePath)
        self.appPath = try container.decodeIfPresent(String.self, forKey: .appPath)
        self.version = try container.decodeIfPresent(String.self, forKey: .version)
        self.resolutionSource = try container.decodeIfPresent(
            GatewayExecutableResolutionSource.self,
            forKey: .resolutionSource
        ) ?? .notFound
        self.manualPathConfigured = try container.decodeIfPresent(Bool.self, forKey: .manualPathConfigured) ?? false
        self.serviceReachable = try container.decodeIfPresent(Bool.self, forKey: .serviceReachable)
        self.recommendedProviderId = try container.decode(String.self, forKey: .recommendedProviderId)
        self.recommendedModel = try container.decode(String.self, forKey: .recommendedModel)
        self.requiresApiKey = try container.decode(Bool.self, forKey: .requiresApiKey)
        self.availableModels = try container.decodeIfPresent([String].self, forKey: .availableModels)
        self.detectionError = try container.decodeIfPresent(String.self, forKey: .detectionError)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}

public enum GatewayExecutableResolutionSource: String, Codable, Sendable {
    case manual
    case cache
    case processPath = "process_path"
    case loginShell = "login_shell"
    case commonPath = "common_path"
    case appBundle = "app_bundle"
    case notFound = "not_found"
}

public enum MainAgentSelectionMode: String, Codable, Sendable {
    case providerModel = "provider_model"
    case agentDefinition = "agent_definition"
}

public typealias ConciergeAgentSelectionMode = MainAgentSelectionMode

public enum GatewayMainAgentStatus: String, Codable, Sendable {
    case healthy
    case repaired
    case degraded
    case fallback
}

public typealias GatewayConciergeAgentStatus = GatewayMainAgentStatus

public struct GatewayMainAgentState: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let mainAgentId: String
    public let mainAgentDefinitionId: String?
    public let mainProfileId: String
    public let assignedAgentDefinitionId: String?
    public let assignedProfileId: String?
    public let providerHint: String?
    public let modelHint: String?
    public let status: GatewayMainAgentStatus
    public let repaired: Bool
    public let fallbackApplied: Bool
    public let fallbackReason: String?
    public let runtimeIssueReason: String?
    public let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case spaceId
        case spaceUid
        case mainAgentId
        case mainAgentDefinitionId
        case mainProfileId
        case assignedAgentDefinitionId
        case assignedProfileId
        case providerHint
        case modelHint
        case status
        case repaired
        case fallbackApplied
        case fallbackReason
        case runtimeIssueReason
        case updatedAt
    }

    public init(
        spaceId: String,
        spaceUid: String,
        mainAgentId: String,
        mainAgentDefinitionId: String? = nil,
        mainProfileId: String,
        assignedAgentDefinitionId: String? = nil,
        assignedProfileId: String? = nil,
        providerHint: String? = nil,
        modelHint: String? = nil,
        status: GatewayMainAgentStatus,
        repaired: Bool,
        fallbackApplied: Bool,
        fallbackReason: String? = nil,
        runtimeIssueReason: String? = nil,
        updatedAt: String
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.mainAgentId = mainAgentId
        self.mainAgentDefinitionId = mainAgentDefinitionId ?? mainProfileId
        self.mainProfileId = mainProfileId
        self.assignedAgentDefinitionId = assignedAgentDefinitionId ?? assignedProfileId
        self.assignedProfileId = assignedProfileId ?? assignedAgentDefinitionId
        self.providerHint = providerHint
        self.modelHint = modelHint
        self.status = status
        self.repaired = repaired
        self.fallbackApplied = fallbackApplied
        self.fallbackReason = fallbackReason
        self.runtimeIssueReason = runtimeIssueReason
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let mainAgentDefinitionId = try container.decodeIfPresent(String.self, forKey: .mainAgentDefinitionId)
        let mainProfileId = try container.decode(String.self, forKey: .mainProfileId)
        let assignedAgentDefinitionId = try container.decodeIfPresent(
            String.self,
            forKey: .assignedAgentDefinitionId
        )
        let assignedProfileId = try container.decodeIfPresent(String.self, forKey: .assignedProfileId)
        let fallbackReason = try container.decodeIfPresent(String.self, forKey: .fallbackReason)
        let runtimeIssueReason = try container.decodeIfPresent(String.self, forKey: .runtimeIssueReason)
            ?? fallbackReason

        self.init(
            spaceId: try container.decode(String.self, forKey: .spaceId),
            spaceUid: try container.decode(String.self, forKey: .spaceUid),
            mainAgentId: try container.decode(String.self, forKey: .mainAgentId),
            mainAgentDefinitionId: mainAgentDefinitionId ?? mainProfileId,
            mainProfileId: mainProfileId,
            assignedAgentDefinitionId: assignedAgentDefinitionId ?? assignedProfileId,
            assignedProfileId: assignedProfileId ?? assignedAgentDefinitionId,
            providerHint: try container.decodeIfPresent(String.self, forKey: .providerHint),
            modelHint: try container.decodeIfPresent(String.self, forKey: .modelHint),
            status: try container.decode(GatewayMainAgentStatus.self, forKey: .status),
            repaired: try container.decode(Bool.self, forKey: .repaired),
            fallbackApplied: try container.decode(Bool.self, forKey: .fallbackApplied),
            fallbackReason: fallbackReason,
            runtimeIssueReason: runtimeIssueReason,
            updatedAt: try container.decode(String.self, forKey: .updatedAt)
        )
    }
}

public struct GatewayConciergeAgentState: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let conciergeAgentId: String
    public let conciergeAgentDefinitionId: String?
    public let conciergeProfileId: String
    public let assignedAgentDefinitionId: String?
    public let assignedProfileId: String?
    public let providerHint: String?
    public let modelHint: String?
    public let status: GatewayConciergeAgentStatus
    public let repaired: Bool
    public let fallbackApplied: Bool
    public let fallbackReason: String?
    public let runtimeIssueReason: String?
    public let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case spaceId
        case spaceUid
        case conciergeAgentId
        case conciergeAgentDefinitionId
        case conciergeProfileId
        case assignedAgentDefinitionId
        case assignedProfileId
        case providerHint
        case modelHint
        case status
        case repaired
        case fallbackApplied
        case fallbackReason
        case runtimeIssueReason
        case updatedAt
    }

    public init(
        spaceId: String,
        spaceUid: String,
        conciergeAgentId: String,
        conciergeAgentDefinitionId: String? = nil,
        conciergeProfileId: String,
        assignedAgentDefinitionId: String? = nil,
        assignedProfileId: String? = nil,
        providerHint: String? = nil,
        modelHint: String? = nil,
        status: GatewayConciergeAgentStatus,
        repaired: Bool,
        fallbackApplied: Bool,
        fallbackReason: String? = nil,
        runtimeIssueReason: String? = nil,
        updatedAt: String
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.conciergeAgentId = conciergeAgentId
        self.conciergeAgentDefinitionId = conciergeAgentDefinitionId ?? conciergeProfileId
        self.conciergeProfileId = conciergeProfileId
        self.assignedAgentDefinitionId = assignedAgentDefinitionId ?? assignedProfileId
        self.assignedProfileId = assignedProfileId ?? assignedAgentDefinitionId
        self.providerHint = providerHint
        self.modelHint = modelHint
        self.status = status
        self.repaired = repaired
        self.fallbackApplied = fallbackApplied
        self.fallbackReason = fallbackReason
        self.runtimeIssueReason = runtimeIssueReason
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let conciergeAgentDefinitionId = try container.decodeIfPresent(
            String.self,
            forKey: .conciergeAgentDefinitionId
        )
        let conciergeProfileId = try container.decode(String.self, forKey: .conciergeProfileId)
        let assignedAgentDefinitionId = try container.decodeIfPresent(
            String.self,
            forKey: .assignedAgentDefinitionId
        )
        let assignedProfileId = try container.decodeIfPresent(String.self, forKey: .assignedProfileId)
        let fallbackReason = try container.decodeIfPresent(String.self, forKey: .fallbackReason)
        let runtimeIssueReason = try container.decodeIfPresent(String.self, forKey: .runtimeIssueReason)
            ?? fallbackReason

        self.init(
            spaceId: try container.decode(String.self, forKey: .spaceId),
            spaceUid: try container.decode(String.self, forKey: .spaceUid),
            conciergeAgentId: try container.decode(String.self, forKey: .conciergeAgentId),
            conciergeAgentDefinitionId: conciergeAgentDefinitionId ?? conciergeProfileId,
            conciergeProfileId: conciergeProfileId,
            assignedAgentDefinitionId: assignedAgentDefinitionId ?? assignedProfileId,
            assignedProfileId: assignedProfileId ?? assignedAgentDefinitionId,
            providerHint: try container.decodeIfPresent(String.self, forKey: .providerHint),
            modelHint: try container.decodeIfPresent(String.self, forKey: .modelHint),
            status: try container.decode(GatewayConciergeAgentStatus.self, forKey: .status),
            repaired: try container.decode(Bool.self, forKey: .repaired),
            fallbackApplied: try container.decode(Bool.self, forKey: .fallbackApplied),
            fallbackReason: fallbackReason,
            runtimeIssueReason: runtimeIssueReason,
            updatedAt: try container.decode(String.self, forKey: .updatedAt)
        )
    }
}

public struct GatewayRuntimeDefaultSelection: Codable, Sendable, Equatable {
    public let providerId: String
    public let modelId: String

    public init(providerId: String, modelId: String) {
        self.providerId = providerId
        self.modelId = modelId
    }
}

public struct GatewayRuntimeDefaults: Codable, Sendable, Equatable {
    public let main: GatewayRuntimeDefaultSelection
    public let concierge: GatewayRuntimeDefaultSelection
    public let updatedAt: String

    public init(
        main: GatewayRuntimeDefaultSelection,
        concierge: GatewayRuntimeDefaultSelection,
        updatedAt: String
    ) {
        self.main = main
        self.concierge = concierge
        self.updatedAt = updatedAt
    }
}

public struct GatewaySetRuntimeDefaultsResult: Codable, Sendable {
    public let defaults: GatewayRuntimeDefaults
    public let mainAgentState: GatewayMainAgentState
    public let conciergeAgentState: GatewayConciergeAgentState

    public init(
        defaults: GatewayRuntimeDefaults,
        mainAgentState: GatewayMainAgentState,
        conciergeAgentState: GatewayConciergeAgentState
    ) {
        self.defaults = defaults
        self.mainAgentState = mainAgentState
        self.conciergeAgentState = conciergeAgentState
    }
}

public struct GatewayProviderRuntimeConfig: Codable, Sendable {
    public let providerId: String
    public let model: String
    public let baseURL: String?
    public let executablePath: String?
    public let hasApiKey: Bool
    public let apiKeySecretRef: String?
    public let authMode: GatewayProviderAuthMode?
    public let allowedModels: [String]
    public let allowCustomModel: Bool
    public let updatedAt: String
    public let source: String

    private enum CodingKeys: String, CodingKey {
        case providerId
        case model
        case baseURL
        case executablePath
        case hasApiKey
        case apiKeySecretRef
        case authMode
        case allowedModels
        case allowCustomModel
        case updatedAt
        case source
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.providerId = try container.decode(String.self, forKey: .providerId)
        self.model = try container.decode(String.self, forKey: .model)
        self.baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL)
        self.executablePath = try container.decodeIfPresent(String.self, forKey: .executablePath)
        self.hasApiKey = try container.decode(Bool.self, forKey: .hasApiKey)
        self.apiKeySecretRef = try container.decodeIfPresent(String.self, forKey: .apiKeySecretRef)
        self.authMode = try container.decodeIfPresent(GatewayProviderAuthMode.self, forKey: .authMode)
        self.allowedModels = try container.decodeIfPresent([String].self, forKey: .allowedModels) ?? []
        self.allowCustomModel = try container.decodeIfPresent(Bool.self, forKey: .allowCustomModel) ?? true
        self.updatedAt = try container.decode(String.self, forKey: .updatedAt)
        self.source = try container.decode(String.self, forKey: .source)
    }
}

public enum GatewayProviderAuthMode: String, Codable, Sendable, Equatable {
    case apiKey = "api_key"
    case hostLogin = "host_login"
}

public enum GatewayProviderAuthStatus: String, Codable, Sendable, Equatable {
    case authenticated
    case needsKey = "needs_key"
    case needsAuth = "needs_auth"
    case error
    case unsupported
}

public struct GatewayProviderAuthAccount: Codable, Sendable, Equatable {
    public let email: String?
    public let organization: String?
    public let subscriptionType: String?
    public let apiProvider: String?
    public let tokenSource: String?
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

    public init(
        id: String,
        displayName: String,
        source: GatewayModelCatalogSource,
        available: Bool,
        contextWindow: Int? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.source = source
        self.available = available
        self.contextWindow = contextWindow
    }
}

public struct GatewayModelProviderCatalog: Codable, Sendable {
    public let providerId: String
    public let displayName: String
    public let group: GatewayProviderCatalogGroup
    public let integrationClass: GatewayIntegrationClass?
    public let status: GatewayIntegrationStatus?
    public let hasApiKey: Bool
    public let requiresApiKey: Bool
    public let supportedAuthModes: [GatewayProviderAuthMode]
    public let authMode: GatewayProviderAuthMode?
    public let authStatus: GatewayProviderAuthStatus?
    public let authAccount: GatewayProviderAuthAccount?
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
        case supportedAuthModes
        case authMode
        case authStatus
        case authAccount
        case baseURL
        case detectionStatus
        case detectionError
        case models
        case installHint
        case recommended
        case supportsHostedBilling
        case configAllowed
    }

    public init(
        providerId: String,
        displayName: String,
        group: GatewayProviderCatalogGroup,
        integrationClass: GatewayIntegrationClass? = nil,
        status: GatewayIntegrationStatus? = nil,
        hasApiKey: Bool,
        requiresApiKey: Bool,
        supportedAuthModes: [GatewayProviderAuthMode] = [],
        authMode: GatewayProviderAuthMode? = nil,
        authStatus: GatewayProviderAuthStatus? = nil,
        authAccount: GatewayProviderAuthAccount? = nil,
        baseURL: String? = nil,
        detectionStatus: GatewayModelDetectionStatus,
        detectionError: String? = nil,
        models: [GatewayModelCatalogEntry],
        installHint: String? = nil,
        recommended: Bool,
        supportsHostedBilling: Bool,
        configAllowed: Bool
    ) {
        self.providerId = providerId
        self.displayName = displayName
        self.group = group
        self.integrationClass = integrationClass
        self.status = status
        self.hasApiKey = hasApiKey
        self.requiresApiKey = requiresApiKey
        self.supportedAuthModes = supportedAuthModes
        self.authMode = authMode
        self.authStatus = authStatus
        self.authAccount = authAccount
        self.baseURL = baseURL
        self.detectionStatus = detectionStatus
        self.detectionError = detectionError
        self.models = models
        self.installHint = installHint
        self.recommended = recommended
        self.supportsHostedBilling = supportsHostedBilling
        self.configAllowed = configAllowed
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
        self.supportedAuthModes = try container.decodeIfPresent([GatewayProviderAuthMode].self, forKey: .supportedAuthModes) ?? []
        self.authMode = try container.decodeIfPresent(GatewayProviderAuthMode.self, forKey: .authMode)
        self.authStatus = try container.decodeIfPresent(GatewayProviderAuthStatus.self, forKey: .authStatus)
        self.authAccount = try container.decodeIfPresent(GatewayProviderAuthAccount.self, forKey: .authAccount)
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

public enum GatewayToolDangerLevel: String, Codable, Sendable {
    case standard
    case destructive
}

public enum GatewayToolHealthStatus: String, Codable, Sendable {
    case unknown
    case ok
    case degraded
}

public enum GatewayToolApprovalGrantMode: String, Codable, Sendable {
    case once
    case timeWindow = "time_window"
    case durable
}

public struct GatewayToolExample: Codable, Sendable {
    public let name: String
    public let description: String?
    public let arguments: [String: AnyCodable]
    public let expectedOutput: String?

    public init(
        name: String,
        description: String? = nil,
        arguments: [String: Any] = [:],
        expectedOutput: String? = nil
    ) {
        self.name = name
        self.description = description
        self.arguments = arguments.mapValues { AnyCodable($0) }
        self.expectedOutput = expectedOutput
    }
}

public struct GatewayTool: Codable, Sendable {
    public let schemaVersion: Int
    public let id: String
    public let providerId: String
    public let displayName: String
    public let description: String
    public let bundleId: String?
    public let bundleDisplayName: String?
    public let bundleDescription: String?
    public let toolGroupId: String?
    public let toolGroupDisplayName: String?
    public let executable: String
    public let resolvedExecutable: String
    public let argsTemplate: [String]
    public let inputSchema: [String: AnyCodable]
    public let instructions: String?
    public let examples: [GatewayToolExample]
    public let timeoutMs: Int
    public let maxOutputBytes: Int
    public let cwdMode: String
    public let fixedCwd: String?
    public let outputMode: String
    public let dangerLevel: GatewayToolDangerLevel
    public let enabled: Bool
    public let available: Bool
    public let healthStatus: GatewayToolHealthStatus
    public let healthMessage: String?
    public let manifestPath: String
    public let readmePath: String?
    public let readmeContent: String?
    public let requiresApproval: Bool
    public let createdAt: String
    public let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case id
        case providerId
        case displayName
        case description
        case bundleId
        case bundleDisplayName
        case bundleDescription
        case toolGroupId
        case toolGroupDisplayName
        case executable
        case resolvedExecutable
        case argsTemplate
        case inputSchema
        case instructions
        case examples
        case timeoutMs
        case maxOutputBytes
        case cwdMode
        case fixedCwd
        case outputMode
        case dangerLevel
        case enabled
        case available
        case healthStatus
        case healthMessage
        case manifestPath
        case readmePath
        case readmeContent
        case requiresApproval
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        id = try container.decode(String.self, forKey: .id)
        providerId = try container.decode(String.self, forKey: .providerId)
        displayName = try container.decode(String.self, forKey: .displayName)
        description = try container.decode(String.self, forKey: .description)
        bundleId = try container.decodeIfPresent(String.self, forKey: .bundleId)
        bundleDisplayName = try container.decodeIfPresent(String.self, forKey: .bundleDisplayName)
        bundleDescription = try container.decodeIfPresent(String.self, forKey: .bundleDescription)
        toolGroupId = try container.decodeIfPresent(String.self, forKey: .toolGroupId)
        toolGroupDisplayName = try container.decodeIfPresent(String.self, forKey: .toolGroupDisplayName)
        executable = try container.decode(String.self, forKey: .executable)
        resolvedExecutable = try container.decode(String.self, forKey: .resolvedExecutable)
        argsTemplate = try container.decode([String].self, forKey: .argsTemplate)
        inputSchema = try container.decode([String: AnyCodable].self, forKey: .inputSchema)
        instructions = try container.decodeIfPresent(String.self, forKey: .instructions)
        examples = try container.decode([GatewayToolExample].self, forKey: .examples)
        timeoutMs = try container.decode(Int.self, forKey: .timeoutMs)
        maxOutputBytes = try container.decode(Int.self, forKey: .maxOutputBytes)
        cwdMode = try container.decode(String.self, forKey: .cwdMode)
        fixedCwd = try container.decodeIfPresent(String.self, forKey: .fixedCwd)
        outputMode = try container.decode(String.self, forKey: .outputMode)
        dangerLevel = try container.decode(GatewayToolDangerLevel.self, forKey: .dangerLevel)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        available = try container.decode(Bool.self, forKey: .available)
        healthStatus = try container.decode(GatewayToolHealthStatus.self, forKey: .healthStatus)
        healthMessage = try container.decodeIfPresent(String.self, forKey: .healthMessage)
        manifestPath = try container.decode(String.self, forKey: .manifestPath)
        readmePath = try container.decodeIfPresent(String.self, forKey: .readmePath)
        readmeContent = try container.decodeIfPresent(String.self, forKey: .readmeContent)
        requiresApproval = try container.decode(Bool.self, forKey: .requiresApproval)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
}

public struct GatewayToolApprovalGrant: Codable, Sendable {
    public let principalId: String
    public let deviceId: String
    public let spaceId: String
    public let toolId: String
    public let mode: GatewayToolApprovalGrantMode
    public let source: String
    public let reason: String
    public let grantedBy: String
    public let grantedAt: String
    public let expiresAt: String?
    public let revokedAt: String?
    public let updatedAt: String
}

public struct GatewayScaffoldedToolBundle: Codable, Sendable {
    public let manifest: GatewayRegisterToolPayload
    public let readme: String
}

public struct GatewayJiraCliRescanResult: Codable, Sendable {
    public let detected: Bool
    public let toolCount: Int
    public let toolIds: [String]
    public let removedToolIds: [String]
    public let healthStatus: GatewayToolHealthStatus
    public let healthMessage: String?
    public let executablePath: String?
}

public struct GatewayRevokeToolApprovalGrantResult: Codable, Sendable {
    public let revoked: Bool
    public let toolId: String
    public let spaceId: String
    public let grant: GatewayToolApprovalGrant?
}

public enum SpaceMcpTransport: String, Codable, Sendable {
    case sse
    case stdio
}

public enum SpaceMcpHealthStatus: String, Codable, Sendable {
    case unknown
    case ok
    case degraded
    case error
}

public struct SpaceMcpEndpoint: Codable, Sendable {
    public let endpointId: String
    public let spaceId: String
    public let transport: SpaceMcpTransport
    public let endpoint: String
    public let args: [String]
    public let secretRef: String?
    public let enabled: Bool
    public let healthStatus: SpaceMcpHealthStatus
    public let healthMessage: String?
    public let lastConnectedAt: String?
    public let lastErrorAt: String?
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

public struct ToolDenyReason: Codable, Sendable {
    public let code: String
    public let message: String
}

public struct ToolAccessRule: Codable, Sendable {
    public let selectorKind: String
    public let selectorId: String
    public let state: String

    public init(selectorKind: String, selectorId: String, state: String) {
        self.selectorKind = selectorKind
        self.selectorId = selectorId
        self.state = state
    }
}

public struct DangerousCapabilityRule: Codable, Sendable {
    public let capabilityId: String
    public let state: String

    public init(capabilityId: String, state: String) {
        self.capabilityId = capabilityId
        self.state = state
    }
}

public struct ToolAccessPolicy: Codable, Sendable {
    public let scopeType: String
    public let scopeId: String
    public let rules: [ToolAccessRule]
    public let dangerousCapabilities: [DangerousCapabilityRule]
    public let guestAccessPreset: String?
    public let policyVersion: String
    public let updatedBy: String?
    public let updatedAt: String?

    public init(
        scopeType: String,
        scopeId: String,
        rules: [ToolAccessRule],
        dangerousCapabilities: [DangerousCapabilityRule],
        guestAccessPreset: String? = nil,
        policyVersion: String,
        updatedBy: String? = nil,
        updatedAt: String? = nil
    ) {
        self.scopeType = scopeType
        self.scopeId = scopeId
        self.rules = rules
        self.dangerousCapabilities = dangerousCapabilities
        self.guestAccessPreset = guestAccessPreset
        self.policyVersion = policyVersion
        self.updatedBy = updatedBy
        self.updatedAt = updatedAt
    }
}

public struct SafetyProfileDefinition: Codable, Sendable {
    public let profileId: String
    public let displayName: String
    public let description: String
    public let rules: [ToolAccessRule]
    public let dangerousCapabilities: [DangerousCapabilityRule]
    public let updatedAt: String

    public init(
        profileId: String,
        displayName: String,
        description: String,
        rules: [ToolAccessRule],
        dangerousCapabilities: [DangerousCapabilityRule],
        updatedAt: String
    ) {
        self.profileId = profileId
        self.displayName = displayName
        self.description = description
        self.rules = rules
        self.dangerousCapabilities = dangerousCapabilities
        self.updatedAt = updatedAt
    }
}

public struct EffectiveToolOperation: Codable, Sendable {
    public let operationId: String
    public let capability: String
    public let operation: String
    public let providerIds: [String]
    public let allowed: Bool
    public let denyReasons: [ToolDenyReason]
}

public struct EffectiveToolMatrix: Codable, Sendable {
    public let spaceId: String
    public let principalId: String?
    public let deviceId: String?
    public let agentId: String?
    public let policyVersion: String
    public let operations: [EffectiveToolOperation]
    public let generatedAt: String
}

public struct EffectiveToolAccessOperation: Codable, Sendable {
    public let operationId: String
    public let capability: String
    public let operation: String
    public let providerIds: [String]
    public let selectors: [String]
    public let allowed: Bool
    public let denialReasonCode: String?
    public let denialReason: String?
    public let requiredDangerousCapability: String?
    public let escalationAllowed: Bool?
}

public struct EffectiveDangerousCapability: Codable, Sendable {
    public let capabilityId: String
    public let enabled: Bool
    public let source: String
}

public struct EffectiveToolAccess: Codable, Sendable {
    public let spaceId: String
    public let agentId: String?
    public let policyVersion: String
    public let safetyProfileId: String?
    public let operations: [EffectiveToolAccessOperation]
    public let dangerousCapabilities: [EffectiveDangerousCapability]
    public let generatedAt: String
}

public enum SpaceConnectorPolicySourceKind: String, Codable, Sendable {
    case builtinIntegration = "builtin_integration"
    case cliBundle = "cli_bundle"
    case connectorFamily = "connector_family"
    case connectorInstance = "connector_instance"
    case mcpServer = "mcp_server"
}

public enum SpaceConnectorPolicyEntryState: String, Codable, Sendable {
    case enabled
    case disabled
}

public enum SpaceConnectorPolicyMode: String, Codable, Sendable {
    case allEnabled = "all_enabled"
    case custom
}

public struct SpaceConnectorPolicyEntry: Codable, Sendable {
    public let sourceKind: SpaceConnectorPolicySourceKind
    public let sourceId: String
    public let state: SpaceConnectorPolicyEntryState

    public init(
        sourceKind: SpaceConnectorPolicySourceKind,
        sourceId: String,
        state: SpaceConnectorPolicyEntryState
    ) {
        self.sourceKind = sourceKind
        self.sourceId = sourceId
        self.state = state
    }
}

public struct SpaceConnectorPolicy: Codable, Sendable {
    public let spaceId: String
    public let mode: SpaceConnectorPolicyMode
    public let entries: [SpaceConnectorPolicyEntry]
    public let policyVersion: String
    public let updatedBy: String?
    public let updatedAt: String?
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
    public let usage: VoiceUsageWindowSummary

    public var sttSeconds: Double { usage.sttSeconds }
    public var ttsChars: Int { usage.ttsChars }
    public var ttsSeconds: Double { usage.ttsSeconds }
    public var estimatedCostUsd: Double { usage.estimatedCostUsd }

    private enum CodingKeys: String, CodingKey {
        case source
        case usage
        case sttSeconds
        case ttsChars
        case ttsSeconds
        case estimatedCostUsd
    }

    public init(source: String, usage: VoiceUsageWindowSummary) {
        self.source = source
        self.usage = usage
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let usage = try container.decodeIfPresent(VoiceUsageWindowSummary.self, forKey: .usage)
            ?? VoiceUsageWindowSummary(
                sttSeconds: try container.decodeIfPresent(Double.self, forKey: .sttSeconds) ?? 0,
                ttsChars: try container.decodeIfPresent(Int.self, forKey: .ttsChars) ?? 0,
                ttsSeconds: try container.decodeIfPresent(Double.self, forKey: .ttsSeconds) ?? 0,
                estimatedCostUsd: try container.decodeIfPresent(Double.self, forKey: .estimatedCostUsd) ?? 0
            )
        self.init(
            source: try container.decode(String.self, forKey: .source),
            usage: usage
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(source, forKey: .source)
        try container.encode(usage, forKey: .usage)
    }
}

public struct VoiceUsageProviderSummary: Codable, Sendable {
    public let channel: String
    public let source: String
    public let providerId: String
    public let usage: VoiceUsageWindowSummary
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
    public let byProvider: [VoiceUsageProviderSummary]

    private enum CodingKeys: String, CodingKey {
        case windows
        case bySource
        case lock
        case byProvider
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        windows = try container.decode(Windows.self, forKey: .windows)
        bySource = try container.decodeIfPresent([VoiceUsageSourceSummary].self, forKey: .bySource) ?? []
        lock = try container.decodeIfPresent(VoiceUsageLockSummary.self, forKey: .lock)
        byProvider = try container.decodeIfPresent([VoiceUsageProviderSummary].self, forKey: .byProvider) ?? []
    }
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

public struct SpaceDigestResult: Codable, Sendable {
    public let spaceId: String
    public let name: String
    public let summary: String
    public let activeAgents: Int
    public let lastTurnAt: String?
    public let pendingActions: [String]
    public let trace: [String]?
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
    public let conversationTopology: ConversationTopology?
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

public enum SchedulerExecutionTargetMode: String, Codable, Sendable {
    case existingSpace = "existing_space"
    case newSpace = "new_space"
}

public enum SchedulerCalendarSyncStatus: String, Codable, Sendable {
    case pending
    case synced
    case error
}

public enum SchedulerCalendarDriftStatus: String, Codable, Sendable {
    case none
    case drifted
}

public enum SchedulerEvalSummaryMode: String, Codable, Sendable {
    case checkpoints
    case finalSummary = "final_summary"
}

public enum SchedulerEvalRecommendationStatus: String, Codable, Sendable {
    case suggested
    case applied
}

public enum SchedulerEvalRecommendationKind: String, Codable, Sendable {
    case flowVariant = "flow_variant"
    case promptPack = "prompt_pack"
    case summaryMode = "summary_mode"
}

public enum SchedulerEvalScenarioStatus: String, Codable, Sendable {
    case pass
    case fail
    case skip
}

public enum SchedulerEvalCheckpointStatus: String, Codable, Sendable {
    case completed
    case failed
    case observed
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

public struct SchedulerEvalConfig: Codable, Sendable {
    public let evalDefinitionId: String
    public let scenarioIds: [String]?
    public let promptVariantId: String?
    public let promptPackId: String?
    public let flowVariantId: String?
    public let summaryMode: SchedulerEvalSummaryMode?
    public let selfImproveEnabled: Bool?

    public init(
        evalDefinitionId: String,
        scenarioIds: [String]? = nil,
        promptVariantId: String? = nil,
        promptPackId: String? = nil,
        flowVariantId: String? = nil,
        summaryMode: SchedulerEvalSummaryMode? = nil,
        selfImproveEnabled: Bool? = nil
    ) {
        self.evalDefinitionId = evalDefinitionId
        self.scenarioIds = scenarioIds
        self.promptVariantId = promptVariantId
        self.promptPackId = promptPackId
        self.flowVariantId = flowVariantId
        self.summaryMode = summaryMode
        self.selfImproveEnabled = selfImproveEnabled
    }
}

public struct SchedulerEvalSelfImproveState: Codable, Sendable {
    public let enabled: Bool
    public let appliedRevisionIds: [String]
    public let lastAppliedRunId: String?

    public init(
        enabled: Bool,
        appliedRevisionIds: [String],
        lastAppliedRunId: String? = nil
    ) {
        self.enabled = enabled
        self.appliedRevisionIds = appliedRevisionIds
        self.lastAppliedRunId = lastAppliedRunId
    }
}

public struct SchedulerEvalCheckpoint: Codable, Sendable {
    public let checkpointId: String
    public let kind: String
    public let status: SchedulerEvalCheckpointStatus
    public let actorId: String?
    public let createdAt: String
    public let detail: [String: AnyCodable]?

    public init(
        checkpointId: String,
        kind: String,
        status: SchedulerEvalCheckpointStatus,
        actorId: String? = nil,
        createdAt: String,
        detail: [String: AnyCodable]? = nil
    ) {
        self.checkpointId = checkpointId
        self.kind = kind
        self.status = status
        self.actorId = actorId
        self.createdAt = createdAt
        self.detail = detail
    }
}

public struct SchedulerEvalRecommendation: Codable, Sendable {
    public let recommendationId: String
    public let status: SchedulerEvalRecommendationStatus
    public let kind: SchedulerEvalRecommendationKind
    public let title: String
    public let summary: String?
    public let originatingRunId: String?
    public let promptVariantId: String?
    public let promptPackId: String?
    public let flowVariantId: String?
    public let appliedRevisionId: String?
    public let createdAt: String
    public let detail: [String: AnyCodable]?

    public init(
        recommendationId: String,
        status: SchedulerEvalRecommendationStatus,
        kind: SchedulerEvalRecommendationKind,
        title: String,
        summary: String? = nil,
        originatingRunId: String? = nil,
        promptVariantId: String? = nil,
        promptPackId: String? = nil,
        flowVariantId: String? = nil,
        appliedRevisionId: String? = nil,
        createdAt: String,
        detail: [String: AnyCodable]? = nil
    ) {
        self.recommendationId = recommendationId
        self.status = status
        self.kind = kind
        self.title = title
        self.summary = summary
        self.originatingRunId = originatingRunId
        self.promptVariantId = promptVariantId
        self.promptPackId = promptPackId
        self.flowVariantId = flowVariantId
        self.appliedRevisionId = appliedRevisionId
        self.createdAt = createdAt
        self.detail = detail
    }
}

public struct SchedulerEvalScenarioResult: Codable, Sendable {
    public let scenarioId: String
    public let status: SchedulerEvalScenarioStatus
    public let checkpointCount: Int
    public let failureReason: String?

    public init(
        scenarioId: String,
        status: SchedulerEvalScenarioStatus,
        checkpointCount: Int,
        failureReason: String? = nil
    ) {
        self.scenarioId = scenarioId
        self.status = status
        self.checkpointCount = checkpointCount
        self.failureReason = failureReason
    }
}

public struct SchedulerEvalArtifactRef: Codable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case space
        case turn
        case schedulerRun = "scheduler_run"
    }

    public let kind: Kind
    public let id: String
    public let label: String?

    public init(
        kind: Kind,
        id: String,
        label: String? = nil
    ) {
        self.kind = kind
        self.id = id
        self.label = label
    }
}

public struct SchedulerEvalRun: Codable, Sendable {
    public let evalRunId: String
    public let evalDefinitionId: String
    public let scenarioIds: [String]
    public let promptVariantId: String?
    public let promptPackId: String?
    public let flowVariantId: String?
    public let summaryMode: SchedulerEvalSummaryMode
    public let selfImproveEnabled: Bool
    public let spaceId: String?
    public let spaceUid: String?
    public let rootTurnId: String?
    public let finalSummaryText: String?
    public let artifactRefs: [SchedulerEvalArtifactRef]
    public let checkpoints: [SchedulerEvalCheckpoint]
    public let scenarioResults: [SchedulerEvalScenarioResult]
    public let recommendations: [SchedulerEvalRecommendation]

    public init(
        evalRunId: String,
        evalDefinitionId: String,
        scenarioIds: [String],
        promptVariantId: String? = nil,
        promptPackId: String? = nil,
        flowVariantId: String? = nil,
        summaryMode: SchedulerEvalSummaryMode,
        selfImproveEnabled: Bool,
        spaceId: String? = nil,
        spaceUid: String? = nil,
        rootTurnId: String? = nil,
        finalSummaryText: String? = nil,
        artifactRefs: [SchedulerEvalArtifactRef],
        checkpoints: [SchedulerEvalCheckpoint],
        scenarioResults: [SchedulerEvalScenarioResult],
        recommendations: [SchedulerEvalRecommendation]
    ) {
        self.evalRunId = evalRunId
        self.evalDefinitionId = evalDefinitionId
        self.scenarioIds = scenarioIds
        self.promptVariantId = promptVariantId
        self.promptPackId = promptPackId
        self.flowVariantId = flowVariantId
        self.summaryMode = summaryMode
        self.selfImproveEnabled = selfImproveEnabled
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.rootTurnId = rootTurnId
        self.finalSummaryText = finalSummaryText
        self.artifactRefs = artifactRefs
        self.checkpoints = checkpoints
        self.scenarioResults = scenarioResults
        self.recommendations = recommendations
    }
}

public struct SchedulerEvalDomain: Codable, Sendable {
    public let domainId: String
    public let description: String?
    public let scenarioIds: [String]

    public init(
        domainId: String,
        description: String? = nil,
        scenarioIds: [String]
    ) {
        self.domainId = domainId
        self.description = description
        self.scenarioIds = scenarioIds
    }
}

public struct SchedulerEvalDefinition: Codable, Sendable {
    public let evalDefinitionId: String
    public let suiteId: String
    public let description: String?
    public let domainIds: [String]
    public let scenarioIds: [String]
    public let domains: [SchedulerEvalDomain]

    public init(
        evalDefinitionId: String,
        suiteId: String,
        description: String? = nil,
        domainIds: [String],
        scenarioIds: [String],
        domains: [SchedulerEvalDomain]
    ) {
        self.evalDefinitionId = evalDefinitionId
        self.suiteId = suiteId
        self.description = description
        self.domainIds = domainIds
        self.scenarioIds = scenarioIds
        self.domains = domains
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

public struct SchedulerExecutionTarget: Codable, Sendable {
    public let mode: SchedulerExecutionTargetMode

    public init(mode: SchedulerExecutionTargetMode) {
        self.mode = mode
    }
}

public struct SchedulerCalendarBinding: Codable, Sendable {
    public let providerId: String
    public let calendarId: String
    public let eventId: String?
    public let syncStatus: SchedulerCalendarSyncStatus?
    public let driftStatus: SchedulerCalendarDriftStatus?
    public let driftMessage: String?
    public let lastSyncedAt: String?

    public init(
        providerId: String,
        calendarId: String,
        eventId: String? = nil,
        syncStatus: SchedulerCalendarSyncStatus? = nil,
        driftStatus: SchedulerCalendarDriftStatus? = nil,
        driftMessage: String? = nil,
        lastSyncedAt: String? = nil
    ) {
        self.providerId = providerId
        self.calendarId = calendarId
        self.eventId = eventId
        self.syncStatus = syncStatus
        self.driftStatus = driftStatus
        self.driftMessage = driftMessage
        self.lastSyncedAt = lastSyncedAt
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
    public let executionTarget: SchedulerExecutionTarget
    public let calendarBinding: SchedulerCalendarBinding?
    public let evalConfig: SchedulerEvalConfig?
    public let evalSelfImproveState: SchedulerEvalSelfImproveState?
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
    public let evalRun: SchedulerEvalRun?
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

public enum WorkbenchExecutionMode: String, Codable, Sendable {
    case supervised
    case autonomous
}

public enum WorkbenchBatchStatus: String, Codable, Sendable {
    case draft
    case queued
    case running
    case completed
    case cancelled
}

public enum WorkbenchRunStatus: String, Codable, Sendable {
    case queued
    case awaitingReview = "awaiting_review"
    case running
    case completed
    case failed
    case cancelled
}

public enum WorkbenchRunStage: String, Codable, Sendable {
    case intake
    case plan
    case execute
    case verify
    case reviewGate = "review_gate"
    case land
    case report
}

public enum WorkbenchApprovalState: String, Codable, Sendable {
    case pending
    case approved
    case rejected
    case notRequired = "not_required"
}

public enum WorkbenchVerificationMode: String, Codable, Sendable {
    case machineReadable = "machine_readable"
    case reviewOnly = "review_only"
}

public enum WorkbenchVerificationSuiteStatus: String, Codable, Sendable {
    case pending
    case running
    case passed
    case failed
    case skipped
}

public enum WorkbenchVerificationResultStatus: String, Codable, Sendable {
    case pending
    case passed
    case failed
}

public enum WorkbenchLandingStatus: String, Codable, Sendable {
    case notStarted = "not_started"
    case blocked
    case landed
}

public struct WorkbenchExecutionModeEligibility: Codable, Sendable {
    public let supervised: Bool
    public let autonomous: Bool
}

public struct WorkbenchQueueItem: Codable, Sendable {
    public let queueItemId: String
    public let queueIndex: Int
    public let title: String
    public let type: String
    public let status: String
    public let nextAction: String
    public let taskFilePath: String
    public let delegation: String
    public let parallelKeys: [String]
    public let aiShippable: Bool
    public let executionModeEligibility: WorkbenchExecutionModeEligibility
    public let verificationMode: WorkbenchVerificationMode
    public let executionModeBlockers: [String]
    public let products: [String]
    public let verificationCommands: [String]
}

public struct WorkbenchBatch: Codable, Sendable {
    public let batchId: String
    public let name: String
    public let status: WorkbenchBatchStatus
    public let executionMode: WorkbenchExecutionMode
    public let queueItemIds: [String]
    public let createdByPrincipalId: String
    public let createdAt: String
    public let updatedAt: String
}

public struct WorkbenchWorktreeRef: Codable, Sendable {
    public let path: String
    public let branchName: String
    public let baseBranchName: String
    public let createdAt: String
}

public struct WorkbenchRepoTouch: Codable, Sendable {
    public let repoId: String
    public let repoPath: String
    public let kind: String
    public let committed: Bool
}

public struct WorkbenchVerificationSuite: Codable, Sendable {
    public let suiteId: String
    public let name: String
    public let command: String
    public let status: WorkbenchVerificationSuiteStatus
    public let startedAt: String?
    public let completedAt: String?
    public let exitCode: Int?
    public let durationMs: Int?
    public let logArtifactId: String?
    public let summary: String?
}

public struct WorkbenchVerificationResult: Codable, Sendable {
    public let status: WorkbenchVerificationResultStatus
    public let summary: String?
    public let completedAt: String?
}

public struct WorkbenchLandingResult: Codable, Sendable {
    public let status: WorkbenchLandingStatus
    public let merged: Bool?
    public let summary: String?
    public let completedAt: String?
}

public enum WorkbenchExecutionContextStage: String, Codable, Sendable {
    case planning
    case implementation
    case verification
    case completed
    case failed
    case paused
}

public struct WorkbenchExecutionContext: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String?
    public let spaceName: String
    public let planningTurnId: String?
    public let implementationTurnId: String?
    public let stage: WorkbenchExecutionContextStage
}

public struct WorkbenchRun: Codable, Sendable {
    public let runId: String
    public let batchId: String?
    public let queueItemId: String
    public let queueItemPath: String
    public let status: WorkbenchRunStatus
    public let currentStage: WorkbenchRunStage
    public let executionMode: WorkbenchExecutionMode
    public let approvalState: WorkbenchApprovalState
    public let worktree: WorkbenchWorktreeRef?
    public let touchedRepos: [WorkbenchRepoTouch]
    public let verificationMode: WorkbenchVerificationMode
    public let executionModeBlockers: [String]
    public let verificationSuites: [WorkbenchVerificationSuite]
    public let verificationResult: WorkbenchVerificationResult?
    public let landingResult: WorkbenchLandingResult?
    public let executionContext: WorkbenchExecutionContext?
    public let createdByPrincipalId: String
    public let createdAt: String
    public let updatedAt: String
    public let startedAt: String?
    public let finishedAt: String?
    public let lastErrorCode: String?
    public let lastErrorMessage: String?
}

public struct WorkbenchArtifact: Codable, Sendable {
    public let artifactId: String
    public let runId: String
    public let kind: String
    public let title: String
    public let contentType: String
    public let contentText: String
    public let createdAt: String
}

public struct WorkbenchPolicy: Codable, Sendable {
    public let defaultExecutionMode: WorkbenchExecutionMode
    public let autonomousEnabled: Bool
    public let maxParallelRuns: Int
    public let requireExplicitAutonomousOptIn: Bool
    public let requireAiShippableForAutonomous: Bool
    public let updatedAt: String
}

public struct WorkbenchSetModeResult: Codable, Sendable {
    public let run: WorkbenchRun?
    public let batch: WorkbenchBatch?
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

public struct VoiceIntentDecision: Codable, Sendable {
    public let intentType: String
    public let confidence: Double
    public let rationale: String?
    public let clarificationPrompt: String?
    public let capabilityId: String?
}

public struct SpeechEngineMetrics: Codable, Sendable {
    public let vadDetectionMs: Double?
    public let sttTranscriptionMs: Double?
    public let ttsFirstAudioMs: Double?
    public let ttsFullSynthesisMs: Double?
}

public struct SpeechRoutePreferences: Codable, Sendable {
    public let channel: String
    public let preferredSource: String?
    public let preferredProviderId: String?
    public let byokProviderId: String?
    public let localModelProviderId: String?
    public let appleSpeechProviderId: String?
    public let allowByokFallback: Bool?
    public let allowLocalFallback: Bool?
    public let allowAppleSpeechFallback: Bool?
}

public struct VoiceRoute: Codable, Sendable {
    public let channel: String
    public let source: String
    public let providerId: String
}

public struct VoiceProviderConfig: Codable, Sendable {
    public let providerId: String
    public let channel: String
    public let source: String
    public let priority: Int
    public let healthStatus: String
    public let costProfile: String?
}

public struct VoiceLockDecision: Codable, Sendable {
    public let channel: String
    public let source: String
    public let allowed: Bool
    public let reason: String
    public let retryAt: String?
    public let fallbackHint: String?
}

public struct VoiceFallbackEvent: Codable, Sendable {
    public let channel: String
    public let fromRoute: VoiceRoute?
    public let toRoute: VoiceRoute?
    public let reason: String
    public let detail: String?
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
    public let type: String?
    public let message: String?
    public let intent: VoiceIntentDecision?
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
    public let sequenceNo: Int?
    public let reason: String?
    public let emittedAt: String?
    public let sttRoute: VoiceRoute?
    public let ttsRoute: VoiceRoute?
    public let lockDecision: VoiceLockDecision?
    public let fallbackEvent: VoiceFallbackEvent?
    public let providerConfigs: [VoiceProviderConfig]
    public let engineMetrics: SpeechEngineMetrics?
    public let ts: String

    private enum CodingKeys: String, CodingKey {
        case sessionId
        case spaceId
        case spaceUid
        case type
        case message
        case intent
        case state
        case eventType
        case providerSource
        case providerId
        case fallbackReason
        case usage
        case lockReason
        case transcript
        case turnId
        case sequence
        case sequenceNo
        case reason
        case emittedAt
        case sttRoute
        case ttsRoute
        case lockDecision
        case fallbackEvent
        case providerConfigs
        case engineMetrics
        case ts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        spaceId = try container.decode(String.self, forKey: .spaceId)
        spaceUid = try container.decodeIfPresent(String.self, forKey: .spaceUid) ?? spaceId
        type = try container.decodeIfPresent(String.self, forKey: .type)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        intent = try container.decodeIfPresent(VoiceIntentDecision.self, forKey: .intent)
        state = try container.decode(String.self, forKey: .state)
        eventType = try container.decodeIfPresent(String.self, forKey: .eventType) ?? type ?? state
        providerSource = try container.decodeIfPresent(String.self, forKey: .providerSource)
        providerId = try container.decodeIfPresent(String.self, forKey: .providerId)
        fallbackReason = try container.decodeIfPresent(String.self, forKey: .fallbackReason)
        usage = try container.decodeIfPresent(UsageMetrics.self, forKey: .usage)
        lockReason = try container.decodeIfPresent(String.self, forKey: .lockReason)
        transcript = try container.decodeIfPresent(String.self, forKey: .transcript)
        turnId = try container.decodeIfPresent(String.self, forKey: .turnId)
        let decodedSequence = try container.decodeIfPresent(Int.self, forKey: .sequence)
        let decodedSequenceNo = try container.decodeIfPresent(Int.self, forKey: .sequenceNo)
        sequence = decodedSequence ?? decodedSequenceNo
        sequenceNo = decodedSequenceNo ?? decodedSequence
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        let decodedEmittedAt = try container.decodeIfPresent(String.self, forKey: .emittedAt)
        let decodedTs = try container.decodeIfPresent(String.self, forKey: .ts)
        emittedAt = decodedEmittedAt ?? decodedTs
        sttRoute = try container.decodeIfPresent(VoiceRoute.self, forKey: .sttRoute)
        ttsRoute = try container.decodeIfPresent(VoiceRoute.self, forKey: .ttsRoute)
        lockDecision = try container.decodeIfPresent(VoiceLockDecision.self, forKey: .lockDecision)
        fallbackEvent = try container.decodeIfPresent(VoiceFallbackEvent.self, forKey: .fallbackEvent)
        providerConfigs = try container.decodeIfPresent([VoiceProviderConfig].self, forKey: .providerConfigs) ?? []
        engineMetrics = try container.decodeIfPresent(SpeechEngineMetrics.self, forKey: .engineMetrics)
        ts = decodedTs ?? decodedEmittedAt ?? ""
    }
}

public struct ConciergeCallMetrics: Codable, Sendable {
    public let callSetupMs: Double?
    public let sttFirstPartialMs: Double?
    public let llmFirstTokenMs: Double?
    public let ttsFirstAudioMs: Double?
    public let routeChangeCount: Int?
    public let handoffCount: Int?
    public let providerFallbackCount: Int?
    public let interruptCount: Int?
    public let playbackUnderrunCount: Int?
    public let reconnectCount: Int?
}

public struct ConciergeCallHandoffContext: Codable, Sendable {
    public let destinationPlatform: String?
    public let destinationDeviceId: String?
    public let destinationClientId: String?
    public let resumeUrl: String?
}

public struct ConciergeCallHandoffToken: Codable, Sendable {
    public let token: String
    public let callId: String
    public let sourceDeviceId: String?
    public let destinationPlatform: String
    public let destinationDeviceId: String?
    public let destinationClientId: String?
    public let resumeUrl: String?
    public let expiresAt: String
    public let signature: String
}

public struct ConciergeCallEvent: Codable, Sendable {
    public let callId: String
    public let state: String
    public let platform: String
    public let deviceId: String?
    public let displayName: String
    public let ttsMode: String
    public let muted: Bool
    public let targetGatewayId: String?
    public let transcriptDelta: String?
    public let assistantTextDelta: String?
    public let urgency: String?
    public let handoffToken: ConciergeCallHandoffToken?
    public let metrics: ConciergeCallMetrics?
    public let reason: String?
    public let emittedAt: String?
    public let mediaEventType: String?
    public let sequence: Int?
    public let transcriptFinal: Bool?
    public let assistantTextFinal: Bool?
    public let activeTurnId: String?
    public let providerSource: String?
    public let providerId: String?
    public let fallbackReason: String?
    public let assistantAudioBase64: String?
    public let assistantAudioDurationSeconds: Double?
    public let ts: String
}

public struct ConciergeCallHandoffPreparation: Codable, Sendable {
    public let event: ConciergeCallEvent
    public let handoffToken: ConciergeCallHandoffToken
}

public struct ConciergeVoipPushRegistration: Codable, Sendable {
    public let principalId: String?
    public let deviceId: String
    public let platform: String
    public let pushToken: String
    public let voipTopic: String?
    public let proactiveOptIn: Bool
    public let registeredAt: String
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
    public let thinkingCapturePolicy: ThinkingCapturePolicy?

    public init(
        apiVersion: String? = nil,
        spaceId: String = "main-space",
        resourceId: String = "resource:main",
        name: String = "Main Space",
        goal: String = "Default shared space for gateway startup and orchestrator coordination.",
        createIfMissing: Bool = true,
        subscribe: Bool = true,
        initialAgents: [SpaceCreateInitialAgentPayload]? = nil,
        thinkingCapturePolicy: ThinkingCapturePolicy? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.resourceId = resourceId
        self.name = name
        self.goal = goal
        self.createIfMissing = createIfMissing
        self.subscribe = subscribe
        self.initialAgents = initialAgents
        self.thinkingCapturePolicy = thinkingCapturePolicy
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
    public let data: [String: AnyCodable]?
    public let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case notificationId
        case category
        case severity
        case title
        case body
        case spaceId
        case spaceUid
        case agentId
        case data
        case createdAt
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case message
    }

    public init(
        notificationId: String,
        category: String,
        severity: String,
        title: String,
        body: String,
        spaceId: String? = nil,
        spaceUid: String? = nil,
        agentId: String? = nil,
        data: [String: AnyCodable]? = nil,
        createdAt: String
    ) {
        self.notificationId = notificationId
        self.category = category
        self.severity = severity
        self.title = title
        self.body = body
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.agentId = agentId
        self.data = data
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notificationId = try container.decode(String.self, forKey: .notificationId)
        category = try container.decode(String.self, forKey: .category)
        severity = try container.decode(String.self, forKey: .severity)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decodeIfPresent(String.self, forKey: .body)
            ?? {
                let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)
                return try legacyContainer.decode(String.self, forKey: .message)
            }()
        spaceId = try container.decodeIfPresent(String.self, forKey: .spaceId)
        spaceUid = try container.decodeIfPresent(String.self, forKey: .spaceUid)
        agentId = try container.decodeIfPresent(String.self, forKey: .agentId)
        data = try container.decodeIfPresent([String: AnyCodable].self, forKey: .data)
        createdAt = try container.decode(String.self, forKey: .createdAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(notificationId, forKey: .notificationId)
        try container.encode(category, forKey: .category)
        try container.encode(severity, forKey: .severity)
        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)
        try container.encodeIfPresent(spaceId, forKey: .spaceId)
        try container.encodeIfPresent(spaceUid, forKey: .spaceUid)
        try container.encodeIfPresent(agentId, forKey: .agentId)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

public struct AppNavigateEvent: Codable, Sendable {
    public let destination: String
    public let gatewayId: String?
    public let spaceId: String?
    public let jobId: String?
    public let promptText: String?
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
