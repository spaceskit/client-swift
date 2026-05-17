// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Space Policy and State

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
        try container.encodeIfPresent(spawnContext, forKey: .spawnContext)
        try container.encodeIfPresent(contextOverrides, forKey: .contextOverrides)
        try container.encode(role, forKey: .role)
        try container.encode(turnOrder, forKey: .turnOrder)
        try container.encode(isPrimary, forKey: .isPrimary)
        try container.encode(assignedAt, forKey: .assignedAt)
    }
}
