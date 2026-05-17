// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Gateway Runtime

public struct DeviceIdentity: Codable, Sendable {
    public let deviceId: String
    public let principalId: String
    public let publicKey: String
    public let platform: String?
    public let keyVersion: String
    public let status: String
    public let createdAt: String
    public let updatedAt: String
    public let lastSeenAt: String?
    public let revokedAt: String?
}

public struct AuthRegisterDeviceResult: Codable, Sendable {
    public let device: DeviceIdentity
    public let created: Bool
}

public struct AuthRotateDeviceKeyResult: Codable, Sendable {
    public let device: DeviceIdentity
}

public struct AuthRevokeDeviceResult: Codable, Sendable {
    public let deviceId: String
    public let revoked: Bool
    public let device: DeviceIdentity?
}

public struct DiscoveredLocalAgent: Codable, Sendable {
    public let id: String
    public let name: String
    public let detected: Bool
    public let executablePath: String?
    public let appPath: String?
    public let version: String?
    public let resolutionSource: GatewayExecutableResolutionSource
    public let manualPathConfigured: Bool
    public let serviceReachable: Bool?
    public let recommendedProviderId: String
    public let recommendedModel: String
    public let requiresApiKey: Bool
    public let availableModels: [String]?
    public let detectionError: String?
    public let notes: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case detected
        case executablePath
        case appPath
        case version
        case resolutionSource
        case manualPathConfigured
        case serviceReachable
        case recommendedProviderId
        case recommendedModel
        case requiresApiKey
        case availableModels
        case detectionError
        case notes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.detected = try container.decode(Bool.self, forKey: .detected)
        self.executablePath = try container.decodeIfPresent(String.self, forKey: .executablePath)
        self.appPath = try container.decodeIfPresent(String.self, forKey: .appPath)
        self.version = try container.decodeIfPresent(String.self, forKey: .version)
        self.resolutionSource = try container.decodeIfPresent(
            GatewayExecutableResolutionSource.self,
            forKey: .resolutionSource
        ) ?? .notFound
        self.manualPathConfigured = try container.decodeIfPresent(Bool.self, forKey: .manualPathConfigured) ?? false
        self.serviceReachable = try container.decodeIfPresent(Bool.self, forKey: .serviceReachable)
        self.recommendedProviderId = try container.decode(String.self, forKey: .recommendedProviderId)
        self.recommendedModel = try container.decode(String.self, forKey: .recommendedModel)
        self.requiresApiKey = try container.decode(Bool.self, forKey: .requiresApiKey)
        self.availableModels = try container.decodeIfPresent([String].self, forKey: .availableModels)
        self.detectionError = try container.decodeIfPresent(String.self, forKey: .detectionError)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}

public enum GatewayExecutableResolutionSource: String, Codable, Sendable {
    case manual
    case cache
    case processPath = "process_path"
    case loginShell = "login_shell"
    case commonPath = "common_path"
    case appBundle = "app_bundle"
    case notFound = "not_found"
}

public enum MainAgentSelectionMode: String, Codable, Sendable {
    case providerModel = "provider_model"
    case agentDefinition = "agent_definition"
}

public enum GatewayMainAgentStatus: String, Codable, Sendable {
    case healthy
    case repaired
    case degraded
    case fallback
}

public struct GatewayMainAgentState: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let mainAgentId: String
    public let mainAgentDefinitionId: String?
    public let mainProfileId: String
    public let assignedAgentDefinitionId: String?
    public let assignedProfileId: String?
    public let providerHint: String?
    public let modelConfig: ProfileModelConfig
    public let status: GatewayMainAgentStatus
    public let repaired: Bool
    public let fallbackApplied: Bool
    public let fallbackReason: String?
    public let runtimeIssueReason: String?
    public let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case spaceId
        case spaceUid
        case mainAgentId
        case mainAgentDefinitionId
        case mainProfileId
        case assignedAgentDefinitionId
        case assignedProfileId
        case providerHint
        case modelConfig
        case status
        case repaired
        case fallbackApplied
        case fallbackReason
        case runtimeIssueReason
        case updatedAt
    }

    public init(
        spaceId: String,
        spaceUid: String,
        mainAgentId: String,
        mainAgentDefinitionId: String? = nil,
        mainProfileId: String,
        assignedAgentDefinitionId: String? = nil,
        assignedProfileId: String? = nil,
        providerHint: String? = nil,
        modelConfig: ProfileModelConfig,
        status: GatewayMainAgentStatus,
        repaired: Bool,
        fallbackApplied: Bool,
        fallbackReason: String? = nil,
        runtimeIssueReason: String? = nil,
        updatedAt: String
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.mainAgentId = mainAgentId
        self.mainAgentDefinitionId = mainAgentDefinitionId ?? mainProfileId
        self.mainProfileId = mainProfileId
        self.assignedAgentDefinitionId = assignedAgentDefinitionId ?? assignedProfileId
        self.assignedProfileId = assignedProfileId ?? assignedAgentDefinitionId
        self.providerHint = providerHint
        self.modelConfig = modelConfig
        self.status = status
        self.repaired = repaired
        self.fallbackApplied = fallbackApplied
        self.fallbackReason = fallbackReason
        self.runtimeIssueReason = runtimeIssueReason
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let mainAgentDefinitionId = try container.decodeIfPresent(String.self, forKey: .mainAgentDefinitionId)
        let mainProfileId = try container.decode(String.self, forKey: .mainProfileId)
        let assignedAgentDefinitionId = try container.decodeIfPresent(
            String.self,
            forKey: .assignedAgentDefinitionId
        )
        let assignedProfileId = try container.decodeIfPresent(String.self, forKey: .assignedProfileId)
        let fallbackReason = try container.decodeIfPresent(String.self, forKey: .fallbackReason)
        let runtimeIssueReason = try container.decodeIfPresent(String.self, forKey: .runtimeIssueReason)

        self.init(
            spaceId: try container.decode(String.self, forKey: .spaceId),
            spaceUid: try container.decode(String.self, forKey: .spaceUid),
            mainAgentId: try container.decode(String.self, forKey: .mainAgentId),
            mainAgentDefinitionId: mainAgentDefinitionId ?? mainProfileId,
            mainProfileId: mainProfileId,
            assignedAgentDefinitionId: assignedAgentDefinitionId ?? assignedProfileId,
            assignedProfileId: assignedProfileId ?? assignedAgentDefinitionId,
            providerHint: try container.decodeIfPresent(String.self, forKey: .providerHint),
            modelConfig: try container.decode(ProfileModelConfig.self, forKey: .modelConfig),
            status: try container.decode(GatewayMainAgentStatus.self, forKey: .status),
            repaired: try container.decode(Bool.self, forKey: .repaired),
            fallbackApplied: try container.decode(Bool.self, forKey: .fallbackApplied),
            fallbackReason: fallbackReason,
            runtimeIssueReason: runtimeIssueReason,
            updatedAt: try container.decode(String.self, forKey: .updatedAt)
        )
    }

    public var preferredModelId: String? {
        modelConfig.preferredModels.first
    }
}

public struct GatewayConciergeAgentState: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let conciergeAgentId: String
    public let conciergeAgentDefinitionId: String?
    public let conciergeProfileId: String
    public let assignedAgentDefinitionId: String?
    public let assignedProfileId: String?
    public let providerHint: String?
    public let modelConfig: ProfileModelConfig
    public let status: GatewayMainAgentStatus
    public let repaired: Bool
    public let fallbackApplied: Bool
    public let fallbackReason: String?
    public let runtimeIssueReason: String?
    public let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case spaceId
        case spaceUid
        case conciergeAgentId
        case conciergeAgentDefinitionId
        case conciergeProfileId
        case assignedAgentDefinitionId
        case assignedProfileId
        case providerHint
        case modelConfig
        case status
        case repaired
        case fallbackApplied
        case fallbackReason
        case runtimeIssueReason
        case updatedAt
    }

    public init(
        spaceId: String,
        spaceUid: String,
        conciergeAgentId: String,
        conciergeAgentDefinitionId: String? = nil,
        conciergeProfileId: String,
        assignedAgentDefinitionId: String? = nil,
        assignedProfileId: String? = nil,
        providerHint: String? = nil,
        modelConfig: ProfileModelConfig,
        status: GatewayMainAgentStatus,
        repaired: Bool,
        fallbackApplied: Bool,
        fallbackReason: String? = nil,
        runtimeIssueReason: String? = nil,
        updatedAt: String
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.conciergeAgentId = conciergeAgentId
        self.conciergeAgentDefinitionId = conciergeAgentDefinitionId ?? conciergeProfileId
        self.conciergeProfileId = conciergeProfileId
        self.assignedAgentDefinitionId = assignedAgentDefinitionId ?? assignedProfileId
        self.assignedProfileId = assignedProfileId ?? assignedAgentDefinitionId
        self.providerHint = providerHint
        self.modelConfig = modelConfig
        self.status = status
        self.repaired = repaired
        self.fallbackApplied = fallbackApplied
        self.fallbackReason = fallbackReason
        self.runtimeIssueReason = runtimeIssueReason
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let conciergeAgentDefinitionId = try container.decodeIfPresent(
            String.self,
            forKey: .conciergeAgentDefinitionId
        )
        let conciergeProfileId = try container.decode(String.self, forKey: .conciergeProfileId)
        let assignedAgentDefinitionId = try container.decodeIfPresent(
            String.self,
            forKey: .assignedAgentDefinitionId
        )
        let assignedProfileId = try container.decodeIfPresent(String.self, forKey: .assignedProfileId)
        let fallbackReason = try container.decodeIfPresent(String.self, forKey: .fallbackReason)
        let runtimeIssueReason = try container.decodeIfPresent(String.self, forKey: .runtimeIssueReason)

        self.init(
            spaceId: try container.decode(String.self, forKey: .spaceId),
            spaceUid: try container.decode(String.self, forKey: .spaceUid),
            conciergeAgentId: try container.decode(String.self, forKey: .conciergeAgentId),
            conciergeAgentDefinitionId: conciergeAgentDefinitionId ?? conciergeProfileId,
            conciergeProfileId: conciergeProfileId,
            assignedAgentDefinitionId: assignedAgentDefinitionId ?? assignedProfileId,
            assignedProfileId: assignedProfileId ?? assignedAgentDefinitionId,
            providerHint: try container.decodeIfPresent(String.self, forKey: .providerHint),
            modelConfig: try container.decode(ProfileModelConfig.self, forKey: .modelConfig),
            status: try container.decode(GatewayMainAgentStatus.self, forKey: .status),
            repaired: try container.decode(Bool.self, forKey: .repaired),
            fallbackApplied: try container.decode(Bool.self, forKey: .fallbackApplied),
            fallbackReason: fallbackReason,
            runtimeIssueReason: runtimeIssueReason,
            updatedAt: try container.decode(String.self, forKey: .updatedAt)
        )
    }

    public var preferredModelId: String? {
        modelConfig.preferredModels.first
    }
}

public struct GatewayRuntimeDefaultSelection: Codable, Sendable, Equatable {
    public let providerId: String
    public let modelId: String

    public init(providerId: String, modelId: String) {
        self.providerId = providerId
        self.modelId = modelId
    }
}

public struct GatewayRuntimeDefaults: Codable, Sendable, Equatable {
    public let main: GatewayRuntimeDefaultSelection
    public let concierge: GatewayRuntimeDefaultSelection
    public let updatedAt: String

    public init(
        main: GatewayRuntimeDefaultSelection,
        concierge: GatewayRuntimeDefaultSelection,
        updatedAt: String
    ) {
        self.main = main
        self.concierge = concierge
        self.updatedAt = updatedAt
    }
}

public struct GatewaySetRuntimeDefaultsResult: Codable, Sendable {
    public let defaults: GatewayRuntimeDefaults
    public let mainAgentState: GatewayMainAgentState
    public let conciergeAgentState: GatewayConciergeAgentState

    public init(
        defaults: GatewayRuntimeDefaults,
        mainAgentState: GatewayMainAgentState,
        conciergeAgentState: GatewayConciergeAgentState
    ) {
        self.defaults = defaults
        self.mainAgentState = mainAgentState
        self.conciergeAgentState = conciergeAgentState
    }
}
