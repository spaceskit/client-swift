// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Space Workspace and Connectivity

public enum SpaceWorkspaceMetadataStatus: String, Codable, Sendable {
    case unknown
    case ready
    case conflict
}

public struct SpaceWorkspace: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let mode: String
    public let explicitWorkspaceRoot: String?
    public let effectiveWorkspaceRoot: String
    public let metaPath: String
    public let logsPath: String
    public let workPath: String
    public let sharedContextPath: String
    public let scratchpadsPath: String
    public let artifactsPath: String
    public let layoutVersion: Int
    public let gitRepoDetected: Bool
    public let metadataStatus: SpaceWorkspaceMetadataStatus
    public let discoveredProjectFiles: [String]
    public let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case spaceId
        case spaceUid
        case mode
        case explicitWorkspaceRoot
        case effectiveWorkspaceRoot
        case metaPath
        case logsPath
        case workPath
        case sharedContextPath
        case scratchpadsPath
        case artifactsPath
        case layoutVersion
        case gitRepoDetected
        case metadataStatus
        case discoveredProjectFiles
        case updatedAt
    }

    public init(
        spaceId: String,
        spaceUid: String,
        mode: String,
        explicitWorkspaceRoot: String? = nil,
        effectiveWorkspaceRoot: String,
        metaPath: String,
        logsPath: String,
        workPath: String,
        sharedContextPath: String,
        scratchpadsPath: String,
        artifactsPath: String,
        layoutVersion: Int,
        gitRepoDetected: Bool = false,
        metadataStatus: SpaceWorkspaceMetadataStatus = .unknown,
        discoveredProjectFiles: [String] = [],
        updatedAt: String
    ) {
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.mode = mode
        self.explicitWorkspaceRoot = explicitWorkspaceRoot
        self.effectiveWorkspaceRoot = effectiveWorkspaceRoot
        self.metaPath = metaPath
        self.logsPath = logsPath
        self.workPath = workPath
        self.sharedContextPath = sharedContextPath
        self.scratchpadsPath = scratchpadsPath
        self.artifactsPath = artifactsPath
        self.layoutVersion = layoutVersion
        self.gitRepoDetected = gitRepoDetected
        self.metadataStatus = metadataStatus
        self.discoveredProjectFiles = discoveredProjectFiles
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        spaceId = try container.decode(String.self, forKey: .spaceId)
        let decodedSpaceUid = try container.decodeIfPresent(String.self, forKey: .spaceUid)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        spaceUid = (decodedSpaceUid?.isEmpty == false ? decodedSpaceUid : nil) ?? spaceId
        explicitWorkspaceRoot = try container.decodeIfPresent(String.self, forKey: .explicitWorkspaceRoot)
        let decodedEffectiveWorkspaceRoot = try container.decodeIfPresent(
            String.self,
            forKey: .effectiveWorkspaceRoot
        )?.trimmingCharacters(in: .whitespacesAndNewlines)
        let decodedMetaPath = try container.decodeIfPresent(String.self, forKey: .metaPath)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        effectiveWorkspaceRoot = Self.resolveEffectiveWorkspaceRoot(
            decodedEffectiveWorkspaceRoot,
            explicitWorkspaceRoot: explicitWorkspaceRoot,
            metaPath: decodedMetaPath
        )
        let resolvedMetaPath = Self.resolveMetaPath(
            decodedMetaPath,
            effectiveWorkspaceRoot: effectiveWorkspaceRoot
        )
        metaPath = resolvedMetaPath
        logsPath = Self.resolvePath(
            try container.decodeIfPresent(String.self, forKey: .logsPath),
            fallbackBasePath: resolvedMetaPath,
            component: "logs"
        )
        workPath = Self.resolvePath(
            try container.decodeIfPresent(String.self, forKey: .workPath),
            fallbackBasePath: resolvedMetaPath,
            component: "work"
        )
        sharedContextPath = Self.resolvePath(
            try container.decodeIfPresent(String.self, forKey: .sharedContextPath),
            fallbackBasePath: resolvedMetaPath,
            component: "shared-context"
        )
        scratchpadsPath = Self.resolvePath(
            try container.decodeIfPresent(String.self, forKey: .scratchpadsPath),
            fallbackBasePath: resolvedMetaPath,
            component: "scratchpads"
        )
        artifactsPath = Self.resolvePath(
            try container.decodeIfPresent(String.self, forKey: .artifactsPath),
            fallbackBasePath: resolvedMetaPath,
            component: "artifacts"
        )
        layoutVersion = try container.decodeIfPresent(Int.self, forKey: .layoutVersion) ?? 2
        gitRepoDetected = try container.decodeIfPresent(Bool.self, forKey: .gitRepoDetected) ?? false
        metadataStatus = try container.decodeIfPresent(SpaceWorkspaceMetadataStatus.self, forKey: .metadataStatus) ?? .unknown
        discoveredProjectFiles = try container.decodeIfPresent([String].self, forKey: .discoveredProjectFiles) ?? []
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
            ?? ISO8601DateFormatter().string(from: Date())
        mode = try container.decodeIfPresent(String.self, forKey: .mode)
            ?? (explicitWorkspaceRoot == nil ? "managed" : "folder_bound")
    }

    private static func resolveEffectiveWorkspaceRoot(
        _ decodedEffectiveWorkspaceRoot: String?,
        explicitWorkspaceRoot: String?,
        metaPath: String?
    ) -> String {
        if let decodedEffectiveWorkspaceRoot, !decodedEffectiveWorkspaceRoot.isEmpty {
            return decodedEffectiveWorkspaceRoot
        }
        if let explicitWorkspaceRoot, !explicitWorkspaceRoot.isEmpty {
            return explicitWorkspaceRoot
        }
        if let metaPath, !metaPath.isEmpty {
            return (metaPath as NSString).deletingLastPathComponent
        }
        return ""
    }

    private static func resolveMetaPath(
        _ decodedMetaPath: String?,
        effectiveWorkspaceRoot: String
    ) -> String {
        if let decodedMetaPath, !decodedMetaPath.isEmpty {
            return decodedMetaPath
        }
        guard !effectiveWorkspaceRoot.isEmpty else { return ".space" }
        return (effectiveWorkspaceRoot as NSString).appendingPathComponent(".space")
    }

    private static func resolvePath(
        _ decodedPath: String?,
        fallbackBasePath: String,
        component: String
    ) -> String {
        let trimmedPath = decodedPath?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedPath, !trimmedPath.isEmpty {
            return trimmedPath
        }
        return (fallbackBasePath as NSString).appendingPathComponent(component)
    }
}

public struct GatewayWorkspaceDefaults: Codable, Sendable {
    public let spaceHomeRoot: String
    public let updatedAt: String

    public init(spaceHomeRoot: String, updatedAt: String) {
        self.spaceHomeRoot = spaceHomeRoot
        self.updatedAt = updatedAt
    }
}

public struct GatewayExternalConnectivitySettings: Codable, Sendable {
    public let mode: String
    public let funnelEnabled: Bool?
    public let updatedAt: String

    public init(mode: String, funnelEnabled: Bool? = nil, updatedAt: String) {
        self.mode = mode
        self.funnelEnabled = funnelEnabled
        self.updatedAt = updatedAt
    }
}

public struct GatewayExternalConnectivityFunnelStatus: Codable, Sendable {
    public let state: String
    public let funnelConfigured: Bool
    public let funnelUrl: String?
    public let exposedPaths: [String]
    public let summary: String?
    public let remediation: String?

    public init(
        state: String,
        funnelConfigured: Bool,
        funnelUrl: String? = nil,
        exposedPaths: [String],
        summary: String? = nil,
        remediation: String? = nil
    ) {
        self.state = state
        self.funnelConfigured = funnelConfigured
        self.funnelUrl = funnelUrl
        self.exposedPaths = exposedPaths
        self.summary = summary
        self.remediation = remediation
    }
}

public struct GatewayExternalConnectivityAdvertisedEndpoint: Codable, Sendable {
    public let provider: String
    public let label: String
    public let host: String
    public let port: Int
    public let websocketUrl: String
    public let healthUrl: String

    public init(
        provider: String,
        label: String,
        host: String,
        port: Int,
        websocketUrl: String,
        healthUrl: String
    ) {
        self.provider = provider
        self.label = label
        self.host = host
        self.port = port
        self.websocketUrl = websocketUrl
        self.healthUrl = healthUrl
    }
}

public struct GatewayExternalConnectivityTailscaleStatus: Codable, Sendable {
    public let cliAvailable: Bool
    public let version: String?
    public let backendState: String?
    public let health: [String]
    public let hostName: String?
    public let dnsName: String?
    public let magicDnsSuffix: String?
    public let tailscaleIps: [String]
    public let serveConfigured: Bool
    public let serveTarget: String?
    public let servePort: Int?

    public init(
        cliAvailable: Bool,
        version: String? = nil,
        backendState: String? = nil,
        health: [String],
        hostName: String? = nil,
        dnsName: String? = nil,
        magicDnsSuffix: String? = nil,
        tailscaleIps: [String],
        serveConfigured: Bool,
        serveTarget: String? = nil,
        servePort: Int? = nil
    ) {
        self.cliAvailable = cliAvailable
        self.version = version
        self.backendState = backendState
        self.health = health
        self.hostName = hostName
        self.dnsName = dnsName
        self.magicDnsSuffix = magicDnsSuffix
        self.tailscaleIps = tailscaleIps
        self.serveConfigured = serveConfigured
        self.serveTarget = serveTarget
        self.servePort = servePort
    }
}

public struct GatewayExternalConnectivityStatus: Codable, Sendable {
    public let state: String
    public let summary: String
    public let remediation: String?
    public let advertisedEndpoints: [GatewayExternalConnectivityAdvertisedEndpoint]
    public let tailscaleStatus: GatewayExternalConnectivityTailscaleStatus?
    public let funnelStatus: GatewayExternalConnectivityFunnelStatus?

    public init(
        state: String,
        summary: String,
        remediation: String? = nil,
        advertisedEndpoints: [GatewayExternalConnectivityAdvertisedEndpoint],
        tailscaleStatus: GatewayExternalConnectivityTailscaleStatus? = nil,
        funnelStatus: GatewayExternalConnectivityFunnelStatus? = nil
    ) {
        self.state = state
        self.summary = summary
        self.remediation = remediation
        self.advertisedEndpoints = advertisedEndpoints
        self.tailscaleStatus = tailscaleStatus
        self.funnelStatus = funnelStatus
    }
}

public enum SpaceOpenWorkspaceStatus: String, Codable, Sendable {
    case openedExisting = "opened_existing"
    case createdNew = "created_new"
    case unbound
    case conflict
}

public struct SpaceOpenWorkspaceConflict: Codable, Sendable {
    public let reason: String
    public let message: String
    public let workspaceRoot: String
    public let metadataPath: String?
    public let existingSpaceId: String?
    public let existingSpaceUid: String?
    public let existingWorkspaceRoot: String?
    public let requestedSpaceId: String?
    public let requestedSpaceUid: String?

    public init(
        reason: String,
        message: String,
        workspaceRoot: String,
        metadataPath: String? = nil,
        existingSpaceId: String? = nil,
        existingSpaceUid: String? = nil,
        existingWorkspaceRoot: String? = nil,
        requestedSpaceId: String? = nil,
        requestedSpaceUid: String? = nil
    ) {
        self.reason = reason
        self.message = message
        self.workspaceRoot = workspaceRoot
        self.metadataPath = metadataPath
        self.existingSpaceId = existingSpaceId
        self.existingSpaceUid = existingSpaceUid
        self.existingWorkspaceRoot = existingWorkspaceRoot
        self.requestedSpaceId = requestedSpaceId
        self.requestedSpaceUid = requestedSpaceUid
    }
}

public struct SpaceOpenWorkspaceResult: Codable, Sendable {
    public let status: SpaceOpenWorkspaceStatus
    public let workspaceRoot: String
    public let gitRepoDetected: Bool
    public let hasSpaceMetadata: Bool
    public let space: SpaceConfig?
    public let workspace: SpaceWorkspace?
    public let conflict: SpaceOpenWorkspaceConflict?

    public init(
        status: SpaceOpenWorkspaceStatus,
        workspaceRoot: String,
        gitRepoDetected: Bool,
        hasSpaceMetadata: Bool,
        space: SpaceConfig? = nil,
        workspace: SpaceWorkspace? = nil,
        conflict: SpaceOpenWorkspaceConflict? = nil
    ) {
        self.status = status
        self.workspaceRoot = workspaceRoot
        self.gitRepoDetected = gitRepoDetected
        self.hasSpaceMetadata = hasSpaceMetadata
        self.space = space
        self.workspace = workspace
        self.conflict = conflict
    }
}
