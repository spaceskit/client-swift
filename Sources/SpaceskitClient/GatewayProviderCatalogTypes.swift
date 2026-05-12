// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Gateway Provider Catalog

public struct GatewayProviderRuntimeConfig: Codable, Sendable {
    public let providerId: String
    public let model: String
    public let baseURL: String?
    public let executablePath: String?
    public let hasApiKey: Bool
    public let apiKeySecretRef: String?
    public let authMode: GatewayProviderAuthMode?
    public let allowedModels: [String]
    public let allowCustomModel: Bool
    public let updatedAt: String
    public let source: String

    private enum CodingKeys: String, CodingKey {
        case providerId
        case model
        case baseURL
        case executablePath
        case hasApiKey
        case apiKeySecretRef
        case authMode
        case allowedModels
        case allowCustomModel
        case updatedAt
        case source
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.providerId = try container.decode(String.self, forKey: .providerId)
        self.model = try container.decode(String.self, forKey: .model)
        self.baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL)
        self.executablePath = try container.decodeIfPresent(String.self, forKey: .executablePath)
        self.hasApiKey = try container.decode(Bool.self, forKey: .hasApiKey)
        self.apiKeySecretRef = try container.decodeIfPresent(String.self, forKey: .apiKeySecretRef)
        self.authMode = try container.decodeIfPresent(GatewayProviderAuthMode.self, forKey: .authMode)
        self.allowedModels = try container.decodeIfPresent([String].self, forKey: .allowedModels) ?? []
        self.allowCustomModel = try container.decodeIfPresent(Bool.self, forKey: .allowCustomModel) ?? true
        self.updatedAt = try container.decode(String.self, forKey: .updatedAt)
        self.source = try container.decode(String.self, forKey: .source)
    }
}

public enum GatewayProviderAuthMode: String, Codable, Sendable, Equatable {
    case apiKey = "api_key"
    case hostLogin = "host_login"
}

public enum GatewayProviderAuthStatus: String, Codable, Sendable, Equatable {
    case authenticated
    case needsKey = "needs_key"
    case needsAuth = "needs_auth"
    case error
    case unsupported
}

public struct GatewayProviderAuthAccount: Codable, Sendable, Equatable {
    public let email: String?
    public let organization: String?
    public let subscriptionType: String?
    public let apiProvider: String?
    public let tokenSource: String?
}

public enum GatewayModelDetectionStatus: String, Codable, Sendable {
    case available
    case unavailable
    case error
}

public enum GatewayModelCatalogSource: String, Codable, Sendable {
    case detected
    case configured
    case fallback
    case allowlist
}

public enum GatewayProviderCatalogGroup: String, Codable, Sendable {
    case cloud
    case executor
    case localRuntime = "local_runtime"
}

public enum GatewayIntegrationClass: String, Codable, Sendable {
    case cloud
    case executor
    case localRuntime = "local_runtime"
}

public enum GatewayIntegrationStatus: String, Codable, Sendable {
    case installed
    case missing
    case needsKey = "needs_key"
    case needsAuth = "needs_auth"
    case reachable
    case noModelsLoaded = "no_models_loaded"
    case policyBlocked = "policy_blocked"
    case unsupported
    case error
}

public enum GatewayModelTier: String, Codable, Sendable {
    case fast
    case balanced
    case smartest
    case local
}

public struct GatewayModelCatalogEntry: Codable, Sendable {
    public let id: String
    public let displayName: String
    public let source: GatewayModelCatalogSource
    public let available: Bool
    public let contextWindow: Int?
    public let tier: GatewayModelTier?

    public init(
        id: String,
        displayName: String,
        source: GatewayModelCatalogSource,
        available: Bool,
        contextWindow: Int? = nil,
        tier: GatewayModelTier? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.source = source
        self.available = available
        self.contextWindow = contextWindow
        self.tier = tier
    }
}

public struct GatewayModelProviderCatalog: Codable, Sendable {
    public let providerId: String
    public let displayName: String
    public let group: GatewayProviderCatalogGroup
    public let integrationClass: GatewayIntegrationClass?
    public let status: GatewayIntegrationStatus?
    public let hasApiKey: Bool
    public let requiresApiKey: Bool
    public let supportedAuthModes: [GatewayProviderAuthMode]
    public let authMode: GatewayProviderAuthMode?
    public let authStatus: GatewayProviderAuthStatus?
    public let authAccount: GatewayProviderAuthAccount?
    public let baseURL: String?
    public let detectionStatus: GatewayModelDetectionStatus
    public let detectionError: String?
    public let models: [GatewayModelCatalogEntry]
    public let installHint: String?
    public let recommended: Bool
    public let supportsHostedBilling: Bool
    public let configAllowed: Bool

    private enum CodingKeys: String, CodingKey {
        case providerId
        case displayName
        case group
        case integrationClass
        case status
        case hasApiKey
        case requiresApiKey
        case supportedAuthModes
        case authMode
        case authStatus
        case authAccount
        case baseURL
        case detectionStatus
        case detectionError
        case models
        case installHint
        case recommended
        case supportsHostedBilling
        case configAllowed
    }

    public init(
        providerId: String,
        displayName: String,
        group: GatewayProviderCatalogGroup,
        integrationClass: GatewayIntegrationClass? = nil,
        status: GatewayIntegrationStatus? = nil,
        hasApiKey: Bool,
        requiresApiKey: Bool,
        supportedAuthModes: [GatewayProviderAuthMode] = [],
        authMode: GatewayProviderAuthMode? = nil,
        authStatus: GatewayProviderAuthStatus? = nil,
        authAccount: GatewayProviderAuthAccount? = nil,
        baseURL: String? = nil,
        detectionStatus: GatewayModelDetectionStatus,
        detectionError: String? = nil,
        models: [GatewayModelCatalogEntry],
        installHint: String? = nil,
        recommended: Bool,
        supportsHostedBilling: Bool,
        configAllowed: Bool
    ) {
        self.providerId = providerId
        self.displayName = displayName
        self.group = group
        self.integrationClass = integrationClass
        self.status = status
        self.hasApiKey = hasApiKey
        self.requiresApiKey = requiresApiKey
        self.supportedAuthModes = supportedAuthModes
        self.authMode = authMode
        self.authStatus = authStatus
        self.authAccount = authAccount
        self.baseURL = baseURL
        self.detectionStatus = detectionStatus
        self.detectionError = detectionError
        self.models = models
        self.installHint = installHint
        self.recommended = recommended
        self.supportsHostedBilling = supportsHostedBilling
        self.configAllowed = configAllowed
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.providerId = try container.decode(String.self, forKey: .providerId)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? providerId
        self.group = (try? container.decode(GatewayProviderCatalogGroup.self, forKey: .group))
            ?? (try? container.decode(GatewayIntegrationClass.self, forKey: .integrationClass)).map {
                switch $0 {
                case .cloud:
                    return .cloud
                case .executor:
                    return .executor
                case .localRuntime:
                    return .localRuntime
                }
            }
            ?? .cloud
        self.integrationClass = try container.decodeIfPresent(GatewayIntegrationClass.self, forKey: .integrationClass)
        self.status = try container.decodeIfPresent(GatewayIntegrationStatus.self, forKey: .status)
        self.hasApiKey = try container.decode(Bool.self, forKey: .hasApiKey)
        self.requiresApiKey = try container.decode(Bool.self, forKey: .requiresApiKey)
        self.supportedAuthModes = try container.decodeIfPresent([GatewayProviderAuthMode].self, forKey: .supportedAuthModes) ?? []
        self.authMode = try container.decodeIfPresent(GatewayProviderAuthMode.self, forKey: .authMode)
        self.authStatus = try container.decodeIfPresent(GatewayProviderAuthStatus.self, forKey: .authStatus)
        self.authAccount = try container.decodeIfPresent(GatewayProviderAuthAccount.self, forKey: .authAccount)
        self.baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL)
        self.detectionStatus = try container.decode(GatewayModelDetectionStatus.self, forKey: .detectionStatus)
        self.detectionError = try container.decodeIfPresent(String.self, forKey: .detectionError)
        self.models = try container.decode([GatewayModelCatalogEntry].self, forKey: .models)
        self.installHint = try container.decodeIfPresent(String.self, forKey: .installHint)
        self.recommended = try container.decodeIfPresent(Bool.self, forKey: .recommended) ?? false
        self.supportsHostedBilling = try container.decodeIfPresent(Bool.self, forKey: .supportsHostedBilling) ?? false
        self.configAllowed = try container.decodeIfPresent(Bool.self, forKey: .configAllowed) ?? true
    }
}
