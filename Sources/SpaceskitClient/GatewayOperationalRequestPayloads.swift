// Protocol payload types for Spaceskit Client SDK.

import Foundation

// MARK: - Gateway Operational Requests

public struct GatewayGetProviderTelemetryPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String?

    public init(apiVersion: String? = nil, providerId: String? = nil) {
        self.apiVersion = apiVersion
        self.providerId = providerId
    }
}

public struct GatewayGetLocalUsageTelemetryPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String?
    public let providerIds: [String]?

    public init(apiVersion: String? = nil, providerId: String? = nil, providerIds: [String]? = nil) {
        self.apiVersion = apiVersion
        self.providerId = providerId
        self.providerIds = providerIds
    }
}

public struct GatewayGetWorkspaceDefaultsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewaySetWorkspaceDefaultsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceHomeRoot: String?

    public init(apiVersion: String? = nil, spaceHomeRoot: String? = nil) {
        self.apiVersion = apiVersion
        self.spaceHomeRoot = spaceHomeRoot
    }
}

public struct GatewayGetMemoryDefaultsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewaySetMemoryDefaultsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let defaultExperienceCapture: SpaceExperienceCaptureMode
    public let defaultSpacePrivacyMode: SpacePrivacyMode?

    public init(
        apiVersion: String? = nil,
        defaultExperienceCapture: SpaceExperienceCaptureMode,
        defaultSpacePrivacyMode: SpacePrivacyMode? = .standard
    ) {
        self.apiVersion = apiVersion
        self.defaultExperienceCapture = defaultExperienceCapture
        self.defaultSpacePrivacyMode = defaultSpacePrivacyMode
    }
}

public struct GatewayGetExternalConnectivityPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewaySetExternalConnectivityPayload: Codable, Sendable {
    public let apiVersion: String?
    public let mode: String
    public let funnelEnabled: Bool?

    public init(apiVersion: String? = nil, mode: String, funnelEnabled: Bool? = nil) {
        self.apiVersion = apiVersion
        self.mode = mode
        self.funnelEnabled = funnelEnabled
    }
}

public struct GatewayGetProviderSettingsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String

    public init(apiVersion: String? = nil, providerId: String) {
        self.apiVersion = apiVersion
        self.providerId = providerId
    }
}

public struct GatewaySetProviderConfigPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String
    public let model: String?
    public let apiKey: String?
    public let apiKeySecretRef: String?
    public let authMode: GatewayProviderAuthMode?
    public let baseURL: String?
    public let executablePath: String?
    public let allowedModels: [String]?
    public let allowCustomModel: Bool?

    public init(
        apiVersion: String? = nil,
        providerId: String,
        model: String? = nil,
        apiKey: String? = nil,
        apiKeySecretRef: String? = nil,
        authMode: GatewayProviderAuthMode? = nil,
        baseURL: String? = nil,
        executablePath: String? = nil,
        allowedModels: [String]? = nil,
        allowCustomModel: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.providerId = providerId
        self.model = model
        self.apiKey = apiKey
        self.apiKeySecretRef = apiKeySecretRef
        self.authMode = authMode
        self.baseURL = baseURL
        self.executablePath = executablePath
        self.allowedModels = allowedModels
        self.allowCustomModel = allowCustomModel
    }
}

public struct GatewayUpdateProviderSettingsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String
    public let model: String?
    public let apiKey: String?
    public let apiKeySecretRef: String?
    public let authMode: GatewayProviderAuthMode?
    public let baseURL: String?
    public let executablePath: String?
    public let allowedModels: [String]?
    public let allowCustomModel: Bool?

    public init(
        apiVersion: String? = nil,
        providerId: String,
        model: String? = nil,
        apiKey: String? = nil,
        apiKeySecretRef: String? = nil,
        authMode: GatewayProviderAuthMode? = nil,
        baseURL: String? = nil,
        executablePath: String? = nil,
        allowedModels: [String]? = nil,
        allowCustomModel: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.providerId = providerId
        self.model = model
        self.apiKey = apiKey
        self.apiKeySecretRef = apiKeySecretRef
        self.authMode = authMode
        self.baseURL = baseURL
        self.executablePath = executablePath
        self.allowedModels = allowedModels
        self.allowCustomModel = allowCustomModel
    }
}

public struct GatewayRemoveProviderConfigPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String

    public init(apiVersion: String? = nil, providerId: String) {
        self.apiVersion = apiVersion
        self.providerId = providerId
    }
}

public struct GatewayFactoryResetPayload: Codable, Sendable {
    public let apiVersion: String?
    public let confirmation: String

    public init(apiVersion: String? = nil, confirmation: String) {
        self.apiVersion = apiVersion
        self.confirmation = confirmation
    }
}

public struct GatewayProvisionLocalProfilePayload: Codable, Sendable {
    public let apiVersion: String?
    public let localClientId: String
    public let profileId: String?
    public let profileName: String?
    public let agentId: String?
    public let spaceId: String?

    public init(
        apiVersion: String? = nil,
        localClientId: String,
        profileId: String? = nil,
        profileName: String? = nil,
        agentId: String? = nil,
        spaceId: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.localClientId = localClientId
        self.profileId = profileId
        self.profileName = profileName
        self.agentId = agentId
        self.spaceId = spaceId
    }
}

public struct GatewayPutSecretRefPayload: Codable, Sendable {
    public let apiVersion: String?
    public let secretRef: String?
    public let providerId: String
    public let label: String?
    public let secret: String
    public let backend: String?

    public init(
        apiVersion: String? = nil,
        secretRef: String? = nil,
        providerId: String,
        label: String? = nil,
        secret: String,
        backend: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.secretRef = secretRef
        self.providerId = providerId
        self.label = label
        self.secret = secret
        self.backend = backend
    }
}

public struct GatewayListSecretRefsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String?

    public init(apiVersion: String? = nil, providerId: String? = nil) {
        self.apiVersion = apiVersion
        self.providerId = providerId
    }
}

public struct GatewayDeleteSecretRefPayload: Codable, Sendable {
    public let apiVersion: String?
    public let secretRef: String

    public init(apiVersion: String? = nil, secretRef: String) {
        self.apiVersion = apiVersion
        self.secretRef = secretRef
    }
}

public struct GatewayListInterconnectorsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewayRescanInterconnectorsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewayGetIntegrationsSnapshotPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}
