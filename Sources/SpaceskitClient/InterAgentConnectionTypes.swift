// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

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
