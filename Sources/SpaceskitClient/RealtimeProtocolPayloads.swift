// Notification, speech, and concierge call protocol payloads for Spaceskit Client SDK.

import Foundation

// MARK: - Realtime Payloads
public struct SubscribeNotificationsPayload: Codable, Sendable {
    public let categories: [String]

    public init(categories: [String]) {
        self.categories = categories
    }
}

public struct UnsubscribeNotificationsPayload: Codable, Sendable {
    public let categories: [String]

    public init(categories: [String]) {
        self.categories = categories
    }
}

public struct NotificationSubscriptionResponsePayload: Codable, Sendable {
    public let categories: [String]
}

public enum ConciergeActionRequestType: String, Codable, Sendable {
    case createSpace = "create_space"
    case openWorkspace = "open_workspace"
    case updateSpace = "update_space"
    case addAgent = "add_agent"
    case removeAgent = "remove_agent"
    case runSpacePrompt = "run_space_prompt"
    case draftSchedulerJob = "draft_scheduler_job"
}

public struct AppConciergeActionRequestPayload: Codable, Sendable {
    public let requestId: String
    public let action: ConciergeActionRequestType
    public let gatewayId: String?
    public let params: [String: AnyCodable]?

    public init(
        requestId: String,
        action: ConciergeActionRequestType,
        gatewayId: String? = nil,
        params: [String: AnyCodable]? = nil
    ) {
        self.requestId = requestId
        self.action = action
        self.gatewayId = gatewayId
        self.params = params
    }
}

public enum ConciergeActionResultStatus: String, Codable, Sendable {
    case ok
    case error
}

public struct ConciergeActionResultPayload: Codable, Sendable {
    public let requestId: String
    public let status: ConciergeActionResultStatus
    public let payload: [String: AnyCodable]?
    public let error: String?

    public init(
        requestId: String,
        status: ConciergeActionResultStatus,
        payload: [String: Any]? = nil,
        error: String? = nil
    ) {
        self.requestId = requestId
        self.status = status
        self.payload = payload?.mapValues { AnyCodable($0) }
        self.error = error
    }
}

public struct ConciergeActionResultAckPayload: Codable, Sendable {
    public let acknowledged: Bool
    public let requestId: String
}

public struct SpeechStartPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let spaceUid: String?
    public let sessionId: String?
    public let locale: String?
    public let sourceDevice: String?
    public let enableTranscription: Bool?
    public let enablePlayback: Bool?
    public let agentId: String?
    public let autoSubmitTurns: Bool?
    public let preferredSource: String?
    public let preferredProviderId: String?
    public let byokProviderId: String?
    public let localModelProviderId: String?
    public let appleSpeechProviderId: String?
    public let allowByokFallback: Bool?
    public let allowLocalFallback: Bool?
    public let allowAppleSpeechFallback: Bool?
    public let sttPreferences: SpeechRoutePreferences?
    public let ttsPreferences: SpeechRoutePreferences?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        spaceUid: String? = nil,
        sessionId: String? = nil,
        locale: String? = nil,
        sourceDevice: String? = nil,
        enableTranscription: Bool? = nil,
        enablePlayback: Bool? = nil,
        agentId: String? = nil,
        autoSubmitTurns: Bool? = nil,
        preferredSource: String? = nil,
        preferredProviderId: String? = nil,
        byokProviderId: String? = nil,
        localModelProviderId: String? = nil,
        appleSpeechProviderId: String? = nil,
        allowByokFallback: Bool? = nil,
        allowLocalFallback: Bool? = nil,
        allowAppleSpeechFallback: Bool? = nil,
        sttPreferences: SpeechRoutePreferences? = nil,
        ttsPreferences: SpeechRoutePreferences? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.sessionId = sessionId
        self.locale = locale
        self.sourceDevice = sourceDevice
        self.enableTranscription = enableTranscription
        self.enablePlayback = enablePlayback
        self.agentId = agentId
        self.autoSubmitTurns = autoSubmitTurns
        self.preferredSource = preferredSource
        self.preferredProviderId = preferredProviderId
        self.byokProviderId = byokProviderId
        self.localModelProviderId = localModelProviderId
        self.appleSpeechProviderId = appleSpeechProviderId
        self.allowByokFallback = allowByokFallback
        self.allowLocalFallback = allowLocalFallback
        self.allowAppleSpeechFallback = allowAppleSpeechFallback
        self.sttPreferences = sttPreferences
        self.ttsPreferences = ttsPreferences
    }
}

public struct SpeechAudioChunkPayload: Codable, Sendable {
    public let apiVersion: String?
    public let sessionId: String
    public let sequence: Int
    public let sequenceNo: Int?
    public let audioBase64: String
    public let sampleRateHz: Int?
    public let channels: Int?
    public let codec: String?
    public let audioDurationSeconds: Double?
    public let ttsChars: Int?
    public let ttsSeconds: Double?
    public let transcriptText: String?
    public let isFinal: Bool?
    public let engineMetrics: SpeechEngineMetrics?

    public init(
        apiVersion: String? = nil,
        sessionId: String,
        sequence: Int,
        sequenceNo: Int? = nil,
        audioBase64: String,
        sampleRateHz: Int? = nil,
        channels: Int? = nil,
        codec: String? = nil,
        audioDurationSeconds: Double? = nil,
        ttsChars: Int? = nil,
        ttsSeconds: Double? = nil,
        transcriptText: String? = nil,
        isFinal: Bool? = nil,
        engineMetrics: SpeechEngineMetrics? = nil
    ) {
        self.apiVersion = apiVersion
        self.sessionId = sessionId
        self.sequence = sequence
        self.sequenceNo = sequenceNo
        self.audioBase64 = audioBase64
        self.sampleRateHz = sampleRateHz
        self.channels = channels
        self.codec = codec
        self.audioDurationSeconds = audioDurationSeconds
        self.ttsChars = ttsChars
        self.ttsSeconds = ttsSeconds
        self.transcriptText = transcriptText
        self.isFinal = isFinal
        self.engineMetrics = engineMetrics
    }
}

public struct SpeechControlPayload: Codable, Sendable {
    public let apiVersion: String?
    public let sessionId: String
    public let command: String
    public let reason: String?
}

public struct SpeechEventResponsePayload: Codable, Sendable {
    public let event: SpeechSessionEvent
}

public struct SpeechEventsResponsePayload: Codable, Sendable {
    public let events: [SpeechSessionEvent]
}

public struct ConciergeCallStartPayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let deviceId: String?
    public let platform: String
    public let ttsMode: String?
    public let targetGatewayId: String?
    public let displayName: String?
    public let handoffContext: ConciergeCallHandoffContext?
    public let spaceId: String?
    public let spaceUid: String?
    public let targetAgentId: String?

    public init(
        apiVersion: String? = nil,
        callId: String,
        deviceId: String? = nil,
        platform: String,
        ttsMode: String? = nil,
        targetGatewayId: String? = nil,
        displayName: String? = nil,
        handoffContext: ConciergeCallHandoffContext? = nil,
        spaceId: String? = nil,
        spaceUid: String? = nil,
        targetAgentId: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.callId = callId
        self.deviceId = deviceId
        self.platform = platform
        self.ttsMode = ttsMode
        self.targetGatewayId = targetGatewayId
        self.displayName = displayName
        self.handoffContext = handoffContext
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.targetAgentId = targetAgentId
    }
}

public struct ConciergeCallAnswerPayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let deviceId: String?
    public let platform: String?

    public init(
        apiVersion: String? = nil,
        callId: String,
        deviceId: String? = nil,
        platform: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.callId = callId
        self.deviceId = deviceId
        self.platform = platform
    }
}

public struct ConciergeCallEndPayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let reason: String?

    public init(
        apiVersion: String? = nil,
        callId: String,
        reason: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.callId = callId
        self.reason = reason
    }
}

public struct ConciergeCallSetMutedPayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let muted: Bool

    public init(
        apiVersion: String? = nil,
        callId: String,
        muted: Bool
    ) {
        self.apiVersion = apiVersion
        self.callId = callId
        self.muted = muted
    }
}

public struct ConciergeCallAudioChunkPayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let sequence: Int
    public let audioBase64: String
    public let audioDurationSeconds: Double?
    public let sampleRateHz: Int?
    public let channels: Int?
    public let codec: String?
    public let transcriptText: String?
    public let isFinal: Bool?

    public init(
        apiVersion: String? = nil,
        callId: String,
        sequence: Int,
        audioBase64: String,
        audioDurationSeconds: Double? = nil,
        sampleRateHz: Int? = nil,
        channels: Int? = nil,
        codec: String? = nil,
        transcriptText: String? = nil,
        isFinal: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.callId = callId
        self.sequence = sequence
        self.audioBase64 = audioBase64
        self.audioDurationSeconds = audioDurationSeconds
        self.sampleRateHz = sampleRateHz
        self.channels = channels
        self.codec = codec
        self.transcriptText = transcriptText
        self.isFinal = isFinal
    }
}

public struct ConciergeCallControlPayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let command: String
    public let reason: String?

    public init(
        apiVersion: String? = nil,
        callId: String,
        command: String,
        reason: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.callId = callId
        self.command = command
        self.reason = reason
    }
}

public struct ConciergeCallHandoffPreparePayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let sourceDeviceId: String?
    public let destinationPlatform: String
    public let destinationDeviceId: String?
    public let destinationClientId: String?
    public let resumeUrl: String?
}

public struct ConciergeCallHandoffAcceptPayload: Codable, Sendable {
    public let apiVersion: String?
    public let callId: String
    public let handoffToken: String
    public let deviceId: String?
    public let platform: String?
}

public struct ConciergeCallRegisterPushPayload: Codable, Sendable {
    public let apiVersion: String?
    public let deviceId: String?
    public let platform: String
    public let pushToken: String
    public let voipTopic: String?
    public let proactiveOptIn: Bool?
}

public struct ConciergeCallEventResponsePayload: Codable, Sendable {
    public let event: ConciergeCallEvent
}

public struct ConciergeCallEventsResponsePayload: Codable, Sendable {
    public let events: [ConciergeCallEvent]
}

public struct ConciergeCallHandoffPrepareResponsePayload: Codable, Sendable {
    public let event: ConciergeCallEvent
    public let handoffToken: ConciergeCallHandoffToken
}

public struct ConciergeCallRegisterPushResponsePayload: Codable, Sendable {
    public let registration: ConciergeVoipPushRegistration
}
