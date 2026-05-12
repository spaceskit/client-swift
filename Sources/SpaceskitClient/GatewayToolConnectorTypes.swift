// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Gateway Tools and MCP

public enum GatewayToolDangerLevel: String, Codable, Sendable {
    case standard
    case destructive
}

public enum GatewayToolHealthStatus: String, Codable, Sendable {
    case unknown
    case ok
    case degraded
}

public enum GatewayToolApprovalGrantMode: String, Codable, Sendable {
    case once
    case timeWindow = "time_window"
    case durable
}

public struct GatewayToolExample: Codable, Sendable {
    public let name: String
    public let description: String?
    public let arguments: [String: AnyCodable]
    public let expectedOutput: String?

    public init(
        name: String,
        description: String? = nil,
        arguments: [String: Any] = [:],
        expectedOutput: String? = nil
    ) {
        self.name = name
        self.description = description
        self.arguments = arguments.mapValues { AnyCodable($0) }
        self.expectedOutput = expectedOutput
    }
}

public struct GatewayTool: Codable, Sendable {
    public let schemaVersion: Int
    public let id: String
    public let providerId: String
    public let displayName: String
    public let description: String
    public let bundleId: String?
    public let bundleDisplayName: String?
    public let bundleDescription: String?
    public let toolGroupId: String?
    public let toolGroupDisplayName: String?
    public let executable: String
    public let resolvedExecutable: String
    public let argsTemplate: [String]
    public let inputSchema: [String: AnyCodable]
    public let instructions: String?
    public let examples: [GatewayToolExample]
    public let timeoutMs: Int
    public let maxOutputBytes: Int
    public let cwdMode: String
    public let fixedCwd: String?
    public let outputMode: String
    public let dangerLevel: GatewayToolDangerLevel
    public let enabled: Bool
    public let available: Bool
    public let healthStatus: GatewayToolHealthStatus
    public let healthMessage: String?
    public let manifestPath: String
    public let readmePath: String?
    public let readmeContent: String?
    public let requiresApproval: Bool
    public let createdAt: String
    public let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case id
        case providerId
        case displayName
        case description
        case bundleId
        case bundleDisplayName
        case bundleDescription
        case toolGroupId
        case toolGroupDisplayName
        case executable
        case resolvedExecutable
        case argsTemplate
        case inputSchema
        case instructions
        case examples
        case timeoutMs
        case maxOutputBytes
        case cwdMode
        case fixedCwd
        case outputMode
        case dangerLevel
        case enabled
        case available
        case healthStatus
        case healthMessage
        case manifestPath
        case readmePath
        case readmeContent
        case requiresApproval
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        id = try container.decode(String.self, forKey: .id)
        providerId = try container.decode(String.self, forKey: .providerId)
        displayName = try container.decode(String.self, forKey: .displayName)
        description = try container.decode(String.self, forKey: .description)
        bundleId = try container.decodeIfPresent(String.self, forKey: .bundleId)
        bundleDisplayName = try container.decodeIfPresent(String.self, forKey: .bundleDisplayName)
        bundleDescription = try container.decodeIfPresent(String.self, forKey: .bundleDescription)
        toolGroupId = try container.decodeIfPresent(String.self, forKey: .toolGroupId)
        toolGroupDisplayName = try container.decodeIfPresent(String.self, forKey: .toolGroupDisplayName)
        executable = try container.decode(String.self, forKey: .executable)
        resolvedExecutable = try container.decode(String.self, forKey: .resolvedExecutable)
        argsTemplate = try container.decode([String].self, forKey: .argsTemplate)
        inputSchema = try container.decode([String: AnyCodable].self, forKey: .inputSchema)
        instructions = try container.decodeIfPresent(String.self, forKey: .instructions)
        examples = try container.decode([GatewayToolExample].self, forKey: .examples)
        timeoutMs = try container.decode(Int.self, forKey: .timeoutMs)
        maxOutputBytes = try container.decode(Int.self, forKey: .maxOutputBytes)
        cwdMode = try container.decode(String.self, forKey: .cwdMode)
        fixedCwd = try container.decodeIfPresent(String.self, forKey: .fixedCwd)
        outputMode = try container.decode(String.self, forKey: .outputMode)
        dangerLevel = try container.decode(GatewayToolDangerLevel.self, forKey: .dangerLevel)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        available = try container.decode(Bool.self, forKey: .available)
        healthStatus = try container.decode(GatewayToolHealthStatus.self, forKey: .healthStatus)
        healthMessage = try container.decodeIfPresent(String.self, forKey: .healthMessage)
        manifestPath = try container.decode(String.self, forKey: .manifestPath)
        readmePath = try container.decodeIfPresent(String.self, forKey: .readmePath)
        readmeContent = try container.decodeIfPresent(String.self, forKey: .readmeContent)
        requiresApproval = try container.decode(Bool.self, forKey: .requiresApproval)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
}

public struct GatewayToolApprovalGrant: Codable, Sendable {
    public let principalId: String
    public let deviceId: String
    public let spaceId: String
    public let toolId: String
    public let mode: GatewayToolApprovalGrantMode
    public let source: String
    public let reason: String
    public let grantedBy: String
    public let grantedAt: String
    public let expiresAt: String?
    public let revokedAt: String?
    public let updatedAt: String
}

public struct GatewayScaffoldedToolBundle: Codable, Sendable {
    public let manifest: GatewayRegisterToolPayload
    public let readme: String
}

public struct GatewayJiraCliRescanResult: Codable, Sendable {
    public let detected: Bool
    public let toolCount: Int
    public let toolIds: [String]
    public let removedToolIds: [String]
    public let healthStatus: GatewayToolHealthStatus
    public let healthMessage: String?
    public let executablePath: String?
}

public struct GatewayRevokeToolApprovalGrantResult: Codable, Sendable {
    public let revoked: Bool
    public let toolId: String
    public let spaceId: String
    public let grant: GatewayToolApprovalGrant?
}

public enum SpaceMcpTransport: String, Codable, Sendable {
    case sse
    case stdio
}

public enum SpaceMcpHealthStatus: String, Codable, Sendable {
    case unknown
    case ok
    case degraded
    case error
}

public struct SpaceMcpEndpoint: Codable, Sendable {
    public let endpointId: String
    public let spaceId: String
    public let transport: SpaceMcpTransport
    public let endpoint: String
    public let args: [String]
    public let secretRef: String?
    public let enabled: Bool
    public let healthStatus: SpaceMcpHealthStatus
    public let healthMessage: String?
    public let lastConnectedAt: String?
    public let lastErrorAt: String?
    public let createdAt: String
    public let updatedAt: String
}

public struct GatewaySecretRef: Codable, Sendable {
    public let secretRef: String
    public let providerId: String
    public let label: String
    public let backend: String
    public let createdAt: String
    public let updatedAt: String
    public let lastUsedAt: String?
}

public struct GatewayPutSecretRefResult: Codable, Sendable {
    public let secretRef: GatewaySecretRef
    public let created: Bool
}

public struct GatewayDeleteSecretRefResult: Codable, Sendable {
    public let secretRef: String
    public let deleted: Bool
}

public struct GatewayProvisionLocalProfileResult: Codable, Sendable {
    public let profileId: String
    public let profileName: String
    public let created: Bool
    public let providerId: String
    public let model: String
    public let agentId: String?
    public let assignmentCreated: Bool?
}

public struct GatewayFactoryResetResult: Codable, Sendable {
    public let gatewayId: String
    public let gatewayUuid: String?
    public let resetAt: String
    public let tablesCleared: Int
    public let rowsDeleted: UInt64
}

public struct SpaceResetPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceResetResult: Codable, Sendable {
    public let spaceId: String
    public let resetAt: String
    public let tablesCleared: Int
    public let rowsDeleted: UInt64
}
