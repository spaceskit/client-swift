// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Orchestrator, Sharing, and Sync

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
