// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Usage and Gateway Policy

public struct ProviderTelemetryWindow: Codable, Sendable {
    public let scopeId: String
    public let scopeName: String?
    public let window: String
    public let usedPercent: Double?
    public let remainingPercent: Double?
    public let resetsAt: String?
    public let windowDurationMins: Int?
}

public struct ProviderTelemetry: Codable, Sendable {
    public let providerId: String
    public let status: String
    public let source: String
    public let fetchedAt: String
    public let message: String?
    public let accountLabel: String?
    public let windows: [ProviderTelemetryWindow]
    public let usage: ProviderUsageSnapshot?
}

public struct LocalUsageInstallHint: Codable, Sendable {
    public let command: String
    public let docsUrl: String
}

public struct LocalUsageWindow: Codable, Sendable {
    public let window: String
    public let label: String
    public let usedPercent: Double?
    public let remainingPercent: Double?
    public let windowMinutes: Int?
    public let resetsAt: String?
    public let resetDescription: String?
}

public struct CodexBarQuota: Codable, Sendable {
    public let available: Bool
    public let sourceLabel: String?
    public let windows: [LocalUsageWindow]
    public let creditsRemaining: Double?
    public let accountLabel: String?
    public let updatedAt: String?
    public let message: String?
    public let installHint: LocalUsageInstallHint?
}

public struct LocalUsageSession: Codable, Sendable {
    public let sessionId: String
    public let model: String?
    public let startedAt: String?
    public let lastActivityAt: String
    public let inputTokens: Int
    public let cachedInputTokens: Int?
    public let outputTokens: Int
    public let totalTokens: Int
    public let estimatedCostUsd: Double?
    public let tokenAccuracy: String
    public let usageSource: String
}

public struct LocalUsageSummary: Codable, Sendable {
    public let windowDays: Int
    public let sessionCount: Int
    public let inputTokens: Int
    public let cachedInputTokens: Int?
    public let outputTokens: Int
    public let totalTokens: Int
    public let estimatedCostUsd: Double?
    public let tokenAccuracy: String
    public let usageSource: String
}

public struct LocalProviderUsageTelemetry: Codable, Sendable {
    public let providerId: String
    public let status: String
    public let fetchedAt: String
    public let message: String?
    public let quota: CodexBarQuota
    public let summary: LocalUsageSummary
    public let sessions: [LocalUsageSession]
}

public struct UsageWindowSummary: Codable, Sendable {
    public let inputTokens: Int
    public let outputTokens: Int
    public let totalTokens: Int
    public let spentUsd: Double
    public let tokenAccuracy: String
    public let usageSource: String
}

public struct BudgetSummary: Codable, Sendable {
    public let softCapUsd: Double
    public let hardCapUsd: Double
    public let warningThreshold: Double
    public let spentUsd: Double
    public let leftUsd: Double
}

public struct ProviderUsageSnapshot: Codable, Sendable {
    public let providerId: String
    public let status: String
    public let inputTokens: Int
    public let outputTokens: Int
    public let totalTokens: Int
    public let spentUsd: Double
    public let tokenAccuracy: String
    public let usageSource: String
    public let message: String?
}

public struct VoiceUsageWindowSummary: Codable, Sendable {
    public let sttSeconds: Double
    public let ttsChars: Int
    public let ttsSeconds: Double
    public let estimatedCostUsd: Double
}

public struct VoiceUsageSourceSummary: Codable, Sendable {
    public let source: String
    public let usage: VoiceUsageWindowSummary

    public var sttSeconds: Double { usage.sttSeconds }
    public var ttsChars: Int { usage.ttsChars }
    public var ttsSeconds: Double { usage.ttsSeconds }
    public var estimatedCostUsd: Double { usage.estimatedCostUsd }

    private enum CodingKeys: String, CodingKey {
        case source
        case usage
        case sttSeconds
        case ttsChars
        case ttsSeconds
        case estimatedCostUsd
    }

    public init(source: String, usage: VoiceUsageWindowSummary) {
        self.source = source
        self.usage = usage
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let usage = try container.decodeIfPresent(VoiceUsageWindowSummary.self, forKey: .usage)
            ?? VoiceUsageWindowSummary(
                sttSeconds: try container.decodeIfPresent(Double.self, forKey: .sttSeconds) ?? 0,
                ttsChars: try container.decodeIfPresent(Int.self, forKey: .ttsChars) ?? 0,
                ttsSeconds: try container.decodeIfPresent(Double.self, forKey: .ttsSeconds) ?? 0,
                estimatedCostUsd: try container.decodeIfPresent(Double.self, forKey: .estimatedCostUsd) ?? 0
            )
        self.init(
            source: try container.decode(String.self, forKey: .source),
            usage: usage
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(source, forKey: .source)
        try container.encode(usage, forKey: .usage)
    }
}

public struct VoiceUsageProviderSummary: Codable, Sendable {
    public let channel: String
    public let source: String
    public let providerId: String
    public let usage: VoiceUsageWindowSummary
}

public struct VoiceUsageLockSummary: Codable, Sendable {
    public let enabled: Bool
    public let managedSttSecondsMonthlyLimit: Double?
    public let managedTtsCharsMonthlyLimit: Double?
    public let managedTtsSecondsMonthlyLimit: Double?
    public let managedCurrentMonthSttSeconds: Double?
    public let managedCurrentMonthTtsChars: Double?
    public let managedCurrentMonthTtsSeconds: Double?
}

public struct VoiceUsageSnapshot: Codable, Sendable {
    public struct Windows: Codable, Sendable {
        public let last5h: VoiceUsageWindowSummary
        public let last7d: VoiceUsageWindowSummary
        public let last30d: VoiceUsageWindowSummary
        public let lifetime: VoiceUsageWindowSummary
    }

    public let windows: Windows
    public let bySource: [VoiceUsageSourceSummary]
    public let lock: VoiceUsageLockSummary?
    public let byProvider: [VoiceUsageProviderSummary]

    private enum CodingKeys: String, CodingKey {
        case windows
        case bySource
        case lock
        case byProvider
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        windows = try container.decode(Windows.self, forKey: .windows)
        bySource = try container.decodeIfPresent([VoiceUsageSourceSummary].self, forKey: .bySource) ?? []
        lock = try container.decodeIfPresent(VoiceUsageLockSummary.self, forKey: .lock)
        byProvider = try container.decodeIfPresent([VoiceUsageProviderSummary].self, forKey: .byProvider) ?? []
    }
}

public struct UsageSnapshot: Codable, Sendable {
    public struct Windows: Codable, Sendable {
        public let last5h: UsageWindowSummary
        public let last7d: UsageWindowSummary
        public let last30d: UsageWindowSummary
        public let lifetime: UsageWindowSummary
    }

    public let computedAt: String
    public let currency: String
    public let windows: Windows
    public let budget: BudgetSummary
    public let providerUsage: [ProviderUsageSnapshot]
    public let voice: VoiceUsageSnapshot?
}

public struct GatewayPolicy: Codable, Sendable {
    public let allowedCapabilityTypes: [String]
    public let deniedCapabilityTypes: [String]
    public let allowedSkillIds: [String]
    public let deniedSkillIds: [String]
    public let globalFlags: [String: AnyCodable]
    public let updatedAt: String
}

public struct GatewayPolicyUpdate: Sendable {
    public let apiVersion: String?
    public let allowedCapabilityTypes: [String]?
    public let deniedCapabilityTypes: [String]?
    public let allowedSkillIds: [String]?
    public let deniedSkillIds: [String]?
    public let globalFlags: [String: AnyCodable]?

    public init(
        apiVersion: String? = nil,
        allowedCapabilityTypes: [String]? = nil,
        deniedCapabilityTypes: [String]? = nil,
        allowedSkillIds: [String]? = nil,
        deniedSkillIds: [String]? = nil,
        globalFlags: [String: Any]? = nil
    ) {
        self.apiVersion = apiVersion
        self.allowedCapabilityTypes = allowedCapabilityTypes
        self.deniedCapabilityTypes = deniedCapabilityTypes
        self.allowedSkillIds = allowedSkillIds
        self.deniedSkillIds = deniedSkillIds
        self.globalFlags = globalFlags?.mapValues { AnyCodable($0) }
    }
}
