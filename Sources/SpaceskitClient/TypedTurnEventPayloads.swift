// Typed turn event payloads for Spaceskit Client SDK.

import Foundation
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

    public var kind: String {
        switch self {
        case .turnStarted: return "turn.started"
        case .turnCompleted: return "turn.completed"
        case .turnCancelled: return "turn.cancelled"
        case .turnFailed: return "turn.failed"
        case .reasoningDelta: return "reasoning.delta"
        case .toolStarted: return "tool.started"
        case .toolCompleted: return "tool.completed"
        case .stateChanged: return "state.changed"
        case .approvalRequested: return "approval.requested"
        case .approvalResolved: return "approval.resolved"
        case .rateLimited: return "rate_limited"
        }
    }
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
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)

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
