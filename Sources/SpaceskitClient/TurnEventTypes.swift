// Shared turn event and stream types for Spaceskit Client SDK.

import Foundation
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
