// Protocol payload types for Spaceskit Client SDK.

import Foundation

// MARK: - Auth, Runtime, and Tool Requests

public struct AuthRegisterDevicePayload: Codable, Sendable {
    public let apiVersion: String?
    public let deviceId: String
    public let publicKey: String
    public let platform: String?

    public init(
        apiVersion: String? = nil,
        deviceId: String,
        publicKey: String,
        platform: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.deviceId = deviceId
        self.publicKey = publicKey
        self.platform = platform
    }
}

public struct AuthRotateDeviceKeyPayload: Codable, Sendable {
    public let apiVersion: String?
    public let deviceId: String
    public let nextPublicKey: String
    public let platform: String?

    public init(
        apiVersion: String? = nil,
        deviceId: String,
        nextPublicKey: String,
        platform: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.deviceId = deviceId
        self.nextPublicKey = nextPublicKey
        self.platform = platform
    }
}

public struct AuthRevokeDevicePayload: Codable, Sendable {
    public let apiVersion: String?
    public let deviceId: String

    public init(apiVersion: String? = nil, deviceId: String) {
        self.apiVersion = apiVersion
        self.deviceId = deviceId
    }
}

public struct AuthListDevicesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let includeRevoked: Bool?

    public init(apiVersion: String? = nil, includeRevoked: Bool? = nil) {
        self.apiVersion = apiVersion
        self.includeRevoked = includeRevoked
    }
}

public struct AuthIssueHttpPrincipalTokenPayload: Codable, Sendable {
    public let apiVersion: String?
    public let ttlSeconds: Int?

    public init(apiVersion: String? = nil, ttlSeconds: Int? = nil) {
        self.apiVersion = apiVersion
        self.ttlSeconds = ttlSeconds
    }
}

public struct GatewayDiscoverLocalAgentsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewayListProviderConfigsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewayGetRuntimeDefaultsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewaySetRuntimeDefaultsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let main: GatewayRuntimeDefaultSelection?
    public let concierge: GatewayRuntimeDefaultSelection?

    public init(
        apiVersion: String? = nil,
        main: GatewayRuntimeDefaultSelection? = nil,
        concierge: GatewayRuntimeDefaultSelection? = nil
    ) {
        self.apiVersion = apiVersion
        self.main = main
        self.concierge = concierge
    }
}

public struct GatewayGetMainAgentPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String?
    public let repairIfMissing: Bool?

    public init(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        repairIfMissing: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.repairIfMissing = repairIfMissing
    }
}

public struct GatewaySetMainAgentPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String?
    public let selectionMode: MainAgentSelectionMode
    public let providerId: String?
    public let modelId: String?
    public let sourceAgentDefinitionId: String?
    public let applyPersonaInstructions: Bool?

    public init(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        selectionMode: MainAgentSelectionMode,
        providerId: String? = nil,
        modelId: String? = nil,
        sourceAgentDefinitionId: String? = nil,
        applyPersonaInstructions: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.selectionMode = selectionMode
        self.providerId = providerId
        self.modelId = modelId
        self.sourceAgentDefinitionId = sourceAgentDefinitionId
        self.applyPersonaInstructions = applyPersonaInstructions
    }
}

public struct GatewayGetConciergeAgentPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String?
    public let repairIfMissing: Bool?

    public init(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        repairIfMissing: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.repairIfMissing = repairIfMissing
    }
}

public struct GatewaySetConciergeAgentPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String?
    public let selectionMode: ConciergeAgentSelectionMode
    public let providerId: String?
    public let modelId: String?
    public let sourceAgentDefinitionId: String?
    public let applyPersonaInstructions: Bool?

    public init(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        selectionMode: ConciergeAgentSelectionMode,
        providerId: String? = nil,
        modelId: String? = nil,
        sourceAgentDefinitionId: String? = nil,
        applyPersonaInstructions: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.selectionMode = selectionMode
        self.providerId = providerId
        self.modelId = modelId
        self.sourceAgentDefinitionId = sourceAgentDefinitionId
        self.applyPersonaInstructions = applyPersonaInstructions
    }
}

public struct GatewayListAvailableModelsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String?
    public let refresh: Bool?

    public init(apiVersion: String? = nil, providerId: String? = nil, refresh: Bool? = nil) {
        self.apiVersion = apiVersion
        self.providerId = providerId
        self.refresh = refresh
    }
}

public struct GatewayListProviderCatalogsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let providerId: String?
    public let refresh: Bool?

    public init(apiVersion: String? = nil, providerId: String? = nil, refresh: Bool? = nil) {
        self.apiVersion = apiVersion
        self.providerId = providerId
        self.refresh = refresh
    }
}

public struct GatewayListToolsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewayGetToolPayload: Codable, Sendable {
    public let apiVersion: String?
    public let toolId: String

    public init(apiVersion: String? = nil, toolId: String) {
        self.apiVersion = apiVersion
        self.toolId = toolId
    }
}

public struct GatewayScaffoldToolPayload: Codable, Sendable {
    public let apiVersion: String?
    public let id: String
    public let displayName: String
    public let description: String
    public let outputMode: String

    public init(
        apiVersion: String? = nil,
        id: String,
        displayName: String,
        description: String,
        outputMode: String
    ) {
        self.apiVersion = apiVersion
        self.id = id
        self.displayName = displayName
        self.description = description
        self.outputMode = outputMode
    }
}

public struct GatewayRegisterToolPayload: Codable, Sendable {
    public let apiVersion: String?
    public let schemaVersion: Int?
    public let id: String
    public let displayName: String
    public let description: String
    public let bundleId: String?
    public let bundleDisplayName: String?
    public let bundleDescription: String?
    public let toolGroupId: String?
    public let toolGroupDisplayName: String?
    public let executable: String
    public let argsTemplate: [String]
    public let inputSchema: [String: AnyCodable]
    public let instructions: String?
    public let examples: [GatewayToolExample]?
    public let timeoutMs: Int?
    public let maxOutputBytes: Int?
    public let cwdMode: String
    public let fixedCwd: String?
    public let outputMode: String
    public let dangerLevel: GatewayToolDangerLevel?
    public let readme: String?
    public let enabled: Bool?

    public init(
        apiVersion: String? = nil,
        schemaVersion: Int? = nil,
        id: String,
        displayName: String,
        description: String,
        bundleId: String? = nil,
        bundleDisplayName: String? = nil,
        bundleDescription: String? = nil,
        toolGroupId: String? = nil,
        toolGroupDisplayName: String? = nil,
        executable: String,
        argsTemplate: [String],
        inputSchema: [String: Any] = [:],
        instructions: String? = nil,
        examples: [GatewayToolExample]? = nil,
        timeoutMs: Int? = nil,
        maxOutputBytes: Int? = nil,
        cwdMode: String,
        fixedCwd: String? = nil,
        outputMode: String,
        dangerLevel: GatewayToolDangerLevel? = nil,
        readme: String? = nil,
        enabled: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.schemaVersion = schemaVersion
        self.id = id
        self.displayName = displayName
        self.description = description
        self.bundleId = bundleId
        self.bundleDisplayName = bundleDisplayName
        self.bundleDescription = bundleDescription
        self.toolGroupId = toolGroupId
        self.toolGroupDisplayName = toolGroupDisplayName
        self.executable = executable
        self.argsTemplate = argsTemplate
        self.inputSchema = inputSchema.mapValues { AnyCodable($0) }
        self.instructions = instructions
        self.examples = examples
        self.timeoutMs = timeoutMs
        self.maxOutputBytes = maxOutputBytes
        self.cwdMode = cwdMode
        self.fixedCwd = fixedCwd
        self.outputMode = outputMode
        self.dangerLevel = dangerLevel
        self.readme = readme
        self.enabled = enabled
    }
}

public struct GatewayRemoveToolPayload: Codable, Sendable {
    public let apiVersion: String?
    public let toolId: String

    public init(apiVersion: String? = nil, toolId: String) {
        self.apiVersion = apiVersion
        self.toolId = toolId
    }
}

public struct GatewaySetToolEnabledPayload: Codable, Sendable {
    public let apiVersion: String?
    public let toolId: String
    public let enabled: Bool

    public init(
        apiVersion: String? = nil,
        toolId: String,
        enabled: Bool
    ) {
        self.apiVersion = apiVersion
        self.toolId = toolId
        self.enabled = enabled
    }
}

public struct GatewayRescanJiraCliToolsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct GatewayListToolApprovalGrantsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let principalId: String?
    public let deviceId: String?
    public let spaceId: String?
    public let toolId: String?
    public let includeRevoked: Bool?
    public let includeExpired: Bool?

    public init(
        apiVersion: String? = nil,
        principalId: String? = nil,
        deviceId: String? = nil,
        spaceId: String? = nil,
        toolId: String? = nil,
        includeRevoked: Bool? = nil,
        includeExpired: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.principalId = principalId
        self.deviceId = deviceId
        self.spaceId = spaceId
        self.toolId = toolId
        self.includeRevoked = includeRevoked
        self.includeExpired = includeExpired
    }
}

public struct GatewayRevokeToolApprovalGrantPayload: Codable, Sendable {
    public let apiVersion: String?
    public let principalId: String?
    public let deviceId: String?
    public let spaceId: String
    public let toolId: String
    public let reason: String?

    public init(
        apiVersion: String? = nil,
        principalId: String? = nil,
        deviceId: String? = nil,
        spaceId: String,
        toolId: String,
        reason: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.principalId = principalId
        self.deviceId = deviceId
        self.spaceId = spaceId
        self.toolId = toolId
        self.reason = reason
    }
}
