// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Voice and Concierge

public struct VoiceIntentDecision: Codable, Sendable {
    public let intentType: String
    public let confidence: Double
    public let rationale: String?
    public let clarificationPrompt: String?
    public let capabilityId: String?
}

public struct SpeechEngineMetrics: Codable, Sendable {
    public let vadDetectionMs: Double?
    public let sttTranscriptionMs: Double?
    public let ttsFirstAudioMs: Double?
    public let ttsFullSynthesisMs: Double?
}

public struct SpeechRoutePreferences: Codable, Sendable {
    public let channel: String
    public let preferredSource: String?
    public let preferredProviderId: String?
    public let byokProviderId: String?
    public let localModelProviderId: String?
    public let appleSpeechProviderId: String?
    public let allowByokFallback: Bool?
    public let allowLocalFallback: Bool?
    public let allowAppleSpeechFallback: Bool?
}

public struct VoiceRoute: Codable, Sendable {
    public let channel: String
    public let source: String
    public let providerId: String
}

public struct VoiceProviderConfig: Codable, Sendable {
    public let providerId: String
    public let channel: String
    public let source: String
    public let priority: Int
    public let healthStatus: String
    public let costProfile: String?
}

public struct VoiceLockDecision: Codable, Sendable {
    public let channel: String
    public let source: String
    public let allowed: Bool
    public let reason: String
    public let retryAt: String?
    public let fallbackHint: String?
}

public struct VoiceFallbackEvent: Codable, Sendable {
    public let channel: String
    public let fromRoute: VoiceRoute?
    public let toRoute: VoiceRoute?
    public let reason: String
    public let detail: String?
}

public struct SpeechSessionEvent: Codable, Sendable {
    public struct UsageMetrics: Codable, Sendable {
        public let sttSeconds: Double
        public let ttsChars: Int
        public let ttsSeconds: Double
    }

    public let sessionId: String
    public let spaceId: String
    public let spaceUid: String
    public let type: String?
    public let message: String?
    public let intent: VoiceIntentDecision?
    public let state: String
    public let eventType: String
    public let providerSource: String?
    public let providerId: String?
    public let fallbackReason: String?
    public let usage: UsageMetrics?
    public let lockReason: String?
    public let transcript: String?
    public let turnId: String?
    public let sequence: Int?
    public let sequenceNo: Int?
    public let reason: String?
    public let emittedAt: String?
    public let sttRoute: VoiceRoute?
    public let ttsRoute: VoiceRoute?
    public let lockDecision: VoiceLockDecision?
    public let fallbackEvent: VoiceFallbackEvent?
    public let providerConfigs: [VoiceProviderConfig]
    public let engineMetrics: SpeechEngineMetrics?
    public let ts: String

    private enum CodingKeys: String, CodingKey {
        case sessionId
        case spaceId
        case spaceUid
        case type
        case message
        case intent
        case state
        case eventType
        case providerSource
        case providerId
        case fallbackReason
        case usage
        case lockReason
        case transcript
        case turnId
        case sequence
        case sequenceNo
        case reason
        case emittedAt
        case sttRoute
        case ttsRoute
        case lockDecision
        case fallbackEvent
        case providerConfigs
        case engineMetrics
        case ts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        spaceId = try container.decode(String.self, forKey: .spaceId)
        spaceUid = try container.decodeIfPresent(String.self, forKey: .spaceUid) ?? spaceId
        type = try container.decodeIfPresent(String.self, forKey: .type)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        intent = try container.decodeIfPresent(VoiceIntentDecision.self, forKey: .intent)
        state = try container.decode(String.self, forKey: .state)
        eventType = try container.decodeIfPresent(String.self, forKey: .eventType) ?? type ?? state
        providerSource = try container.decodeIfPresent(String.self, forKey: .providerSource)
        providerId = try container.decodeIfPresent(String.self, forKey: .providerId)
        fallbackReason = try container.decodeIfPresent(String.self, forKey: .fallbackReason)
        usage = try container.decodeIfPresent(UsageMetrics.self, forKey: .usage)
        lockReason = try container.decodeIfPresent(String.self, forKey: .lockReason)
        transcript = try container.decodeIfPresent(String.self, forKey: .transcript)
        turnId = try container.decodeIfPresent(String.self, forKey: .turnId)
        let decodedSequence = try container.decodeIfPresent(Int.self, forKey: .sequence)
        let decodedSequenceNo = try container.decodeIfPresent(Int.self, forKey: .sequenceNo)
        sequence = decodedSequence ?? decodedSequenceNo
        sequenceNo = decodedSequenceNo ?? decodedSequence
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        let decodedEmittedAt = try container.decodeIfPresent(String.self, forKey: .emittedAt)
        let decodedTs = try container.decodeIfPresent(String.self, forKey: .ts)
        emittedAt = decodedEmittedAt ?? decodedTs
        sttRoute = try container.decodeIfPresent(VoiceRoute.self, forKey: .sttRoute)
        ttsRoute = try container.decodeIfPresent(VoiceRoute.self, forKey: .ttsRoute)
        lockDecision = try container.decodeIfPresent(VoiceLockDecision.self, forKey: .lockDecision)
        fallbackEvent = try container.decodeIfPresent(VoiceFallbackEvent.self, forKey: .fallbackEvent)
        providerConfigs = try container.decodeIfPresent([VoiceProviderConfig].self, forKey: .providerConfigs) ?? []
        engineMetrics = try container.decodeIfPresent(SpeechEngineMetrics.self, forKey: .engineMetrics)
        ts = decodedTs ?? decodedEmittedAt ?? ""
    }
}

public struct ConciergeCallMetrics: Codable, Sendable {
    public let callSetupMs: Double?
    public let sttFirstPartialMs: Double?
    public let llmFirstTokenMs: Double?
    public let ttsFirstAudioMs: Double?
    public let routeChangeCount: Int?
    public let handoffCount: Int?
    public let providerFallbackCount: Int?
    public let interruptCount: Int?
    public let playbackUnderrunCount: Int?
    public let reconnectCount: Int?
}

public struct ConciergeCallHandoffContext: Codable, Sendable {
    public let destinationPlatform: String?
    public let destinationDeviceId: String?
    public let destinationClientId: String?
    public let resumeUrl: String?
}

public struct ConciergeCallHandoffToken: Codable, Sendable {
    public let token: String
    public let callId: String
    public let sourceDeviceId: String?
    public let destinationPlatform: String
    public let destinationDeviceId: String?
    public let destinationClientId: String?
    public let resumeUrl: String?
    public let expiresAt: String
    public let signature: String
}

public struct ConciergeCallEvent: Codable, Sendable {
    public let callId: String
    public let state: String
    public let platform: String
    public let deviceId: String?
    public let displayName: String
    public let ttsMode: String
    public let muted: Bool
    public let targetGatewayId: String?
    public let transcriptDelta: String?
    public let assistantTextDelta: String?
    public let urgency: String?
    public let handoffToken: ConciergeCallHandoffToken?
    public let metrics: ConciergeCallMetrics?
    public let reason: String?
    public let emittedAt: String?
    public let mediaEventType: String?
    public let sequence: Int?
    public let transcriptFinal: Bool?
    public let assistantTextFinal: Bool?
    public let activeTurnId: String?
    public let providerSource: String?
    public let providerId: String?
    public let fallbackReason: String?
    public let assistantAudioBase64: String?
    public let assistantAudioDurationSeconds: Double?
    public let ts: String
}

public struct ConciergeCallHandoffPreparation: Codable, Sendable {
    public let event: ConciergeCallEvent
    public let handoffToken: ConciergeCallHandoffToken
}

public struct ConciergeVoipPushRegistration: Codable, Sendable {
    public let principalId: String?
    public let deviceId: String
    public let platform: String
    public let pushToken: String
    public let voipTopic: String?
    public let proactiveOptIn: Bool
    public let registeredAt: String
    public let ts: String
}

public struct MainSpaceBootstrapOptions: Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let resourceId: String
    public let name: String
    public let goal: String
    public let createIfMissing: Bool
    public let subscribe: Bool
    public let initialAgents: [SpaceCreateInitialAgentPayload]?
    public let thinkingCapturePolicy: ThinkingCapturePolicy?

    public init(
        apiVersion: String? = nil,
        spaceId: String = "main-space",
        resourceId: String = "resource:main",
        name: String = "Main Space",
        goal: String = "Default shared space for gateway startup and orchestrator coordination.",
        createIfMissing: Bool = true,
        subscribe: Bool = true,
        initialAgents: [SpaceCreateInitialAgentPayload]? = nil,
        thinkingCapturePolicy: ThinkingCapturePolicy? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.resourceId = resourceId
        self.name = name
        self.goal = goal
        self.createIfMissing = createIfMissing
        self.subscribe = subscribe
        self.initialAgents = initialAgents
        self.thinkingCapturePolicy = thinkingCapturePolicy
    }
}

public struct MainSpaceBootstrapResult: Sendable {
    public let space: SpaceConfig
    public let created: Bool
    public let subscribed: Bool
}

public struct ConnectAndBootstrapResult: Sendable {
    public let space: SpaceConfig
    public let created: Bool
    public let subscribed: Bool
    public let connected: Bool
}

/// Notification from the gateway.
