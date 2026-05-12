// Orchestrator and sharing protocol payloads for Spaceskit Client SDK.

import Foundation

// MARK: - Orchestrator and Sharing Payloads
public struct OrchestratorCommandPayload: Codable, Sendable {
    public let apiVersion: String?
    public let correlationId: String?
    public let idempotencyKey: String?
    public let commandType: String
    public let targetSpaceId: String?
    public let targetAgentId: String?
    public let payload: [String: AnyCodable]?

    public init(
        apiVersion: String? = nil,
        correlationId: String? = nil,
        idempotencyKey: String? = nil,
        commandType: String,
        targetSpaceId: String? = nil,
        targetAgentId: String? = nil,
        payload: [String: Any]? = nil
    ) {
        self.apiVersion = apiVersion
        self.correlationId = correlationId
        self.idempotencyKey = idempotencyKey
        self.commandType = commandType
        self.targetSpaceId = targetSpaceId
        self.targetAgentId = targetAgentId
        self.payload = payload?.mapValues { AnyCodable($0) }
    }
}

public struct OrchestratorGetCommandPayload: Codable, Sendable {
    public let apiVersion: String?
    public let commandId: String

    public init(apiVersion: String? = nil, commandId: String) {
        self.apiVersion = apiVersion
        self.commandId = commandId
    }
}

public struct OrchestratorCommandResponsePayload: Codable, Sendable {
    public let command: OrchestratorCommandResult
}

public struct SpaceLinkPayload: Codable, Sendable {
    public let apiVersion: String?
    public let sourceSpaceId: String
    public let targetSpaceId: String
    public let mode: String?

    public init(apiVersion: String? = nil, sourceSpaceId: String, targetSpaceId: String, mode: String? = nil) {
        self.apiVersion = apiVersion
        self.sourceSpaceId = sourceSpaceId
        self.targetSpaceId = targetSpaceId
        self.mode = mode
    }
}

public struct SpaceLinkResponsePayload: Codable, Sendable {
    public let link: SpaceLinkResult
}

public struct SpaceUnlinkPayload: Codable, Sendable {
    public let apiVersion: String?
    public let sourceSpaceId: String
    public let targetSpaceId: String

    public init(apiVersion: String? = nil, sourceSpaceId: String, targetSpaceId: String) {
        self.apiVersion = apiVersion
        self.sourceSpaceId = sourceSpaceId
        self.targetSpaceId = targetSpaceId
    }
}

public struct SpaceUnlinkResponsePayload: Codable, Sendable {
    public let removed: Bool
    public let sourceSpaceId: String
    public let targetSpaceId: String
}

public struct SpaceShareContextPayload: Codable, Sendable {
    public let apiVersion: String?
    public let sourceSpaceId: String
    public let targetSpaceId: String
    public let artifactId: String

    public init(apiVersion: String? = nil, sourceSpaceId: String, targetSpaceId: String, artifactId: String) {
        self.apiVersion = apiVersion
        self.sourceSpaceId = sourceSpaceId
        self.targetSpaceId = targetSpaceId
        self.artifactId = artifactId
    }
}

public struct SpaceShareContextResponsePayload: Codable, Sendable {
    public let transfer: SharedContextRef
}

public struct SpaceShareCreateInvitePayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let mode: SpaceShareAccessMode
    public let expiresInSeconds: Int?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        mode: SpaceShareAccessMode,
        expiresInSeconds: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.mode = mode
        self.expiresInSeconds = expiresInSeconds
    }
}

public struct SpaceShareCreateInviteResponsePayload: Codable, Sendable {
    public let invite: SpaceShareInvite
}

public enum SpaceShareJoinRoute: String, Codable, Sendable {
    case direct
    case relayProxy = "relay_proxy"
}

public enum SpaceShareIdentityModeHint: String, Codable, Sendable {
    case deviceKey = "device_key"
    case strictAppleId = "strict_apple_id"
}

public struct SpaceShareJoinPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let inviteToken: String
    public let deviceId: String?
    public let devicePublicKey: String?
    public let identityModeHint: SpaceShareIdentityModeHint?
    public let appleIdAssertion: String?
    public let joinRoute: SpaceShareJoinRoute?
    public let relaySessionToken: String?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        inviteToken: String,
        deviceId: String? = nil,
        devicePublicKey: String? = nil,
        identityModeHint: SpaceShareIdentityModeHint? = nil,
        appleIdAssertion: String? = nil,
        joinRoute: SpaceShareJoinRoute? = nil,
        relaySessionToken: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.inviteToken = inviteToken
        self.deviceId = deviceId
        self.devicePublicKey = devicePublicKey
        self.identityModeHint = identityModeHint
        self.appleIdAssertion = appleIdAssertion
        self.joinRoute = joinRoute
        self.relaySessionToken = relaySessionToken
    }
}

public struct SpaceShareJoinResponsePayload: Codable, Sendable {
    public let participant: SpaceParticipant
}

public struct SpaceShareRevokePayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let inviteId: String?
    public let participantId: String?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        inviteId: String? = nil,
        participantId: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.inviteId = inviteId
        self.participantId = participantId
    }
}

public struct SpaceShareRevokeResponsePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let inviteId: String?
    public let participantId: String?
    public let revokedInvite: Bool
    public let revokedParticipant: Bool
}

public struct SpaceShareListParticipantsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceShareListParticipantsResponsePayload: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let participants: [SpaceParticipant]
}

public struct SpacePullSharedContextPayload: Codable, Sendable {
    public let apiVersion: String?
    public let sourceSpaceId: String
    public let targetSpaceId: String
    public let limit: Int?

    public init(apiVersion: String? = nil, sourceSpaceId: String, targetSpaceId: String, limit: Int? = nil) {
        self.apiVersion = apiVersion
        self.sourceSpaceId = sourceSpaceId
        self.targetSpaceId = targetSpaceId
        self.limit = limit
    }
}

public struct SyncAnnouncePayload: Codable, Sendable {
    public let apiVersion: String?
    public let peerId: String
    public let resourceId: String
    public let gatewayVersion: String
    public let endpointUrl: String?
    public let authSecretHash: String?
    public let skillCount: Int?
    public let actionCount: Int?
    public let experienceCount: Int?
    public let profileCount: Int?
}

public struct SyncQueryResourcesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let peerId: String
    public let resourceId: String?
    public let types: [String]?
    public let tags: [String]?
    public let updatedAfter: String?
    public let cursor: String?
    public let limit: Int?
}

public struct SyncQueryResourcesResponsePayload: Codable, Sendable {
    public let resources: [SyncResourceRef]
    public let nextCursor: String?
}

public struct SyncPullResourcesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let peerId: String
    public let idempotencyKey: String
    public let refs: [SyncResourceRef]
}

public struct SyncPullResourcesResponsePayload: Codable, Sendable {
    public let resources: [SyncResource]
    public let denied: [SyncResourceDenied]
    public let appliedCount: Int
    public let skippedCount: Int
}
