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
