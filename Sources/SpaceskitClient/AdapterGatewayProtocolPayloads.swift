// Adapter, gateway-to-client, and inter-agent protocol payloads for Spaceskit Client SDK.

import Foundation
// MARK: - Adapter Payloads

public enum AdapterCapabilityProviderSource: String, Codable, Sendable {
    case adapter
}

public struct AdapterCapabilityProvider: Codable, Sendable {
    public let id: String
    public let name: String
    public let source: AdapterCapabilityProviderSource
    public let capabilityType: String
    public let operations: [String]

    public init(
        id: String,
        name: String,
        source: AdapterCapabilityProviderSource = .adapter,
        capabilityType: String,
        operations: [String]
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.capabilityType = capabilityType
        self.operations = operations
    }
}

public struct CapabilitiesRegisterPayload: Codable, Sendable {
    public let providers: [AdapterCapabilityProvider]

    public init(providers: [AdapterCapabilityProvider]) {
        self.providers = providers
    }
}

public struct CapabilitiesDeregisterPayload: Codable, Sendable {
    public let providerIds: [String]

    public init(providerIds: [String]) {
        self.providerIds = providerIds
    }
}

public struct AdapterCapabilityInvokePayload: Codable, Sendable {
    public let invocationId: String
    public let capability: String
    public let operation: String
    public let args: [String: AnyCodable]
    public let targetProvider: String?

    public init(
        invocationId: String,
        capability: String,
        operation: String,
        args: [String: AnyCodable],
        targetProvider: String? = nil
    ) {
        self.invocationId = invocationId
        self.capability = capability
        self.operation = operation
        self.args = args
        self.targetProvider = targetProvider
    }
}

public struct CapabilityResultPayload: Codable, Sendable {
    public let invocationId: String
    public let providerId: String
    public let data: AnyCodable?
    public let durationMs: Double?

    public init(
        invocationId: String,
        providerId: String,
        data: Any? = nil,
        durationMs: Double? = nil
    ) {
        self.invocationId = invocationId
        self.providerId = providerId
        self.data = data.map(AnyCodable.init)
        self.durationMs = durationMs
    }

    public init(
        invocationId: String,
        providerId: String,
        dataCodable: AnyCodable?,
        durationMs: Double? = nil
    ) {
        self.invocationId = invocationId
        self.providerId = providerId
        self.data = dataCodable
        self.durationMs = durationMs
    }
}

public struct CapabilityErrorPayload: Codable, Sendable {
    public let invocationId: String
    public let providerId: String?
    public let code: String?
    public let message: String
    public let details: AnyCodable?

    public init(
        invocationId: String,
        providerId: String? = nil,
        code: String? = nil,
        message: String,
        details: Any? = nil
    ) {
        self.invocationId = invocationId
        self.providerId = providerId
        self.code = code
        self.message = message
        self.details = details.map(AnyCodable.init)
    }
}

// MARK: - Gateway → Client Payloads

public struct AuthChallengePayload: Codable, Sendable {
    public let challenge: String?
    public let success: Bool?
    public let reason: String?
}

public struct AuthResultPayload: Codable, Sendable {
    public let success: Bool
    public let reason: String?
}

public struct AppNavigatePayload: Codable, Sendable {
    public let destination: String
    public let gatewayId: String?
    public let spaceId: String?
    public let jobId: String?
    public let promptText: String?

    public init(
        destination: String,
        gatewayId: String? = nil,
        spaceId: String? = nil,
        jobId: String? = nil,
        promptText: String? = nil
    ) {
        self.destination = destination
        self.gatewayId = gatewayId
        self.spaceId = spaceId
        self.jobId = jobId
        self.promptText = promptText
    }
}

// MARK: - Inter-Agent Messaging Payloads

/// Send a message directly to a specific agent within a space.
public struct AgentMessagePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let fromAgentId: String
    /// Target agent ID. Use "*" for broadcast to all agents in the space.
    public let toAgentId: String
    public let content: String
    public let metadata: [String: AnyCodable]?

    public init(
        spaceId: String,
        spaceUid: String,
        fromAgentId: String,
        toAgentId: String,
        content: String,
        metadata: [String: Any]? = nil
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.fromAgentId = fromAgentId
        self.toAgentId = toAgentId
        self.content = content
        self.metadata = metadata?.mapValues { AnyCodable($0) }
    }
}

/// Notify an idle agent to resume work.
public struct AgentPokePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let targetAgentId: String
    public let reason: String
    public let unblockedByTurnId: String?

    public init(
        spaceId: String,
        spaceUid: String,
        targetAgentId: String,
        reason: String,
        unblockedByTurnId: String? = nil
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.targetAgentId = targetAgentId
        self.reason = reason
        self.unblockedByTurnId = unblockedByTurnId
    }
}

/// Agent idle notification from the gateway.
public struct AgentIdlePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let agentId: String
    public let idleDurationMs: Double
    public let lastTurnId: String?
}

/// Declare a dependency between tasks/turns within a space.
public struct TaskDependencyPayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let blockedTurnId: String
    public let dependsOnTurnId: String

    public init(
        spaceId: String,
        spaceUid: String,
        blockedTurnId: String,
        dependsOnTurnId: String
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.blockedTurnId = blockedTurnId
        self.dependsOnTurnId = dependsOnTurnId
    }
}

/// Gateway notification that a task dependency has been resolved.
public struct TaskDependencyResolvedPayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let unblockedTurnId: String
    public let resolvedByTurnId: String
}
