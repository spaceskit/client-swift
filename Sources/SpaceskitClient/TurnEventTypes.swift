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
    public let agentId: String?
    public let seq: Int?
    public let typedPayload: TypedTurnEventPayload
    public let timestamp: String?

    public init(
        spaceId: String,
        spaceUid: String,
        turnId: String,
        rootTurnId: String? = nil,
        conversationTopology: ConversationTopology? = nil,
        transcriptVisibility: TranscriptVisibility? = nil,
        summaryTurnId: String? = nil,
        agentId: String? = nil,
        seq: Int? = nil,
        typedPayload: TypedTurnEventPayload,
        timestamp: String? = nil
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.turnId = turnId
        self.rootTurnId = rootTurnId
        self.conversationTopology = conversationTopology
        self.transcriptVisibility = transcriptVisibility
        self.summaryTurnId = summaryTurnId
        self.agentId = agentId
        self.seq = seq
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
        case agentId
        case seq
        case typedPayload
        case timestamp
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let spaceId = try container.decode(String.self, forKey: .spaceId)
        let spaceUid = try container.decode(String.self, forKey: .spaceUid)
        let turnId = try container.decode(String.self, forKey: .turnId)
        let rootTurnId = try? container.decodeIfPresent(String.self, forKey: .rootTurnId)
        let conversationTopology = try? container.decodeIfPresent(ConversationTopology.self, forKey: .conversationTopology)
        let transcriptVisibility = try? container.decodeIfPresent(TranscriptVisibility.self, forKey: .transcriptVisibility)
        let summaryTurnId = try? container.decodeIfPresent(String.self, forKey: .summaryTurnId)
        let agentId = try? container.decodeIfPresent(String.self, forKey: .agentId)
        let seq = try? container.decodeIfPresent(Int.self, forKey: .seq)
        let timestamp = try? container.decodeIfPresent(String.self, forKey: .timestamp)
        let typedPayload = try container.decode(TypedTurnEventPayload.self, forKey: .typedPayload)

        self.init(
            spaceId: spaceId,
            spaceUid: spaceUid,
            turnId: turnId,
            rootTurnId: rootTurnId,
            conversationTopology: conversationTopology,
            transcriptVisibility: transcriptVisibility,
            summaryTurnId: summaryTurnId,
            agentId: agentId,
            seq: seq,
            typedPayload: typedPayload,
            timestamp: timestamp
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
        try container.encodeIfPresent(agentId, forKey: .agentId)
        try container.encodeIfPresent(seq, forKey: .seq)
        try container.encode(typedPayload, forKey: .typedPayload)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
    }

    // MARK: - Convenience Accessors

    public var resolvedAgentActivityState: AgentActivityState? {
        if case .stateChanged(let payload) = typedPayload {
            return payload.state
        }
        return nil
    }

    /// The resolved agent state from the typed payload.
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
        return nil
    }

    /// Tool name from typedPayload.
    public var resolvedToolName: String? {
        switch typedPayload {
        case .toolStarted(let p): return p.toolName
        case .toolCompleted(let p): return p.toolName
        default: break
        }
        return nil
    }

    /// Error message from typedPayload.
    public var resolvedErrorMessage: String? {
        if case .turnFailed(let p) = typedPayload { return p.errorMessage }
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

    public var kind: String {
        typedPayload.kind
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
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let spaceId = try container.decode(String.self, forKey: .spaceId)
        let spaceUid = try container.decode(String.self, forKey: .spaceUid)
        let turnId = try container.decode(String.self, forKey: .turnId)
        let rootTurnId = try? container.decodeIfPresent(String.self, forKey: .rootTurnId)
        let conversationTopology = try? container.decodeIfPresent(ConversationTopology.self, forKey: .conversationTopology)
        let transcriptVisibility = try? container.decodeIfPresent(TranscriptVisibility.self, forKey: .transcriptVisibility)
        let summaryTurnId = try? container.decodeIfPresent(String.self, forKey: .summaryTurnId)
        let streamKind = try? container.decodeIfPresent(TurnStreamKind.self, forKey: .streamKind)
        let timestamp = try? container.decodeIfPresent(String.self, forKey: .timestamp)
        let delta = try container.decode(String.self, forKey: .delta)
        let agentId = try container.decode(String.self, forKey: .agentId)
        let seq = try container.decode(Int.self, forKey: .seq)
        let done = try container.decode(Bool.self, forKey: .done)

        self.init(
            spaceId: spaceId,
            spaceUid: spaceUid,
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
