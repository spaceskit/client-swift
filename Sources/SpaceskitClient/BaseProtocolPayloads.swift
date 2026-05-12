// BaseProtocolPayloads.swift - Authentication, turn, subscription, and capability payloads.

import Foundation

public struct AuthenticatePayload: Codable, Sendable {
    public let publicKey: String
    public let signature: String
    public let clientType: String
    public let clientVersion: String
    public let deviceId: String?
    public let devicePublicKey: String?
    public let deviceProofSignature: String?
}

public struct ExecuteTurnPayload: Codable, Sendable {
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

    public init(_ options: ExecuteTurnOptions) {
        self.init(
            spaceUid: options.spaceUid,
            input: options.input,
            targetAgentId: options.targetAgentId,
            targetAgentIds: options.targetAgentIds,
            replyToTurnId: options.replyToTurnId,
            conversationTopology: options.conversationTopology,
            mode: options.mode,
            effort: options.effort,
            accessMode: options.accessMode
        )
    }
}

public struct ResumeFeedbackPayload: Codable, Sendable {
    public let spaceUid: String
    public let turnId: String
    public let response: String
    public let revision: String?
    public let approvalGrant: ApprovalGrantPayload?

    public init(
        spaceUid: String,
        turnId: String,
        response: FeedbackResponse,
        revision: String? = nil,
        approvalGrant: ApprovalGrantPayload? = nil
    ) {
        self.spaceUid = spaceUid
        self.turnId = turnId
        self.response = response.rawValue
        self.revision = revision
        self.approvalGrant = approvalGrant
    }
}

public struct ApprovalGrantPayload: Codable, Sendable {
    public let mode: GatewayToolApprovalGrantMode
    public let ttlSeconds: Int?

    public init(
        mode: GatewayToolApprovalGrantMode,
        ttlSeconds: Int? = nil
    ) {
        self.mode = mode
        self.ttlSeconds = ttlSeconds
    }
}

public struct SubscribePayload: Codable, Sendable {
    public let spaceUids: [String]

    public init(spaceUids: [String]) {
        self.spaceUids = spaceUids
    }
}

public struct SubscribeDeniedSpace: Codable, Sendable {
    public let spaceUid: String
    public let reason: String

    public init(spaceUid: String, reason: String) {
        self.spaceUid = spaceUid
        self.reason = reason
    }
}

public struct SubscribeResponsePayload: Codable, Sendable {
    public let subscribedSpaceUids: [String]
    public let denied: [SubscribeDeniedSpace]

    public init(subscribedSpaceUids: [String], denied: [SubscribeDeniedSpace]) {
        self.subscribedSpaceUids = subscribedSpaceUids
        self.denied = denied
    }
}

public struct CapabilityInvokePayload: Codable, Sendable {
    public let capability: String
    public let method: String
    public let params: [String: AnyCodable]
    public let targetProvider: String?

    public init(capability: String, method: String, params: [String: Any], targetProvider: String? = nil) {
        self.capability = capability
        self.method = method
        self.params = params.mapValues { AnyCodable($0) }
        self.targetProvider = targetProvider
    }
}
