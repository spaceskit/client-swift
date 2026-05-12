// Speech and concierge-call GatewayClient APIs.

import Foundation

extension GatewayClient {
    /// Start speech session without constructing payloads in callers.
    public func startSpeechSession(
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
    ) async throws -> SpeechSessionEvent {
        let payload = SpeechStartPayload(
            apiVersion: apiVersion,
            spaceId: spaceId,
            spaceUid: spaceUid,
            sessionId: sessionId,
            locale: locale,
            sourceDevice: sourceDevice,
            enableTranscription: enableTranscription,
            enablePlayback: enablePlayback,
            agentId: agentId,
            autoSubmitTurns: autoSubmitTurns,
            preferredSource: preferredSource,
            preferredProviderId: preferredProviderId,
            byokProviderId: byokProviderId,
            localModelProviderId: localModelProviderId,
            appleSpeechProviderId: appleSpeechProviderId,
            allowByokFallback: allowByokFallback,
            allowLocalFallback: allowLocalFallback,
            allowAppleSpeechFallback: allowAppleSpeechFallback,
            sttPreferences: sttPreferences,
            ttsPreferences: ttsPreferences
        )
        return try await startSpeechSession(payload)
    }

    public func startSpeechSession(_ payload: SpeechStartPayload) async throws -> SpeechSessionEvent {
        let data = try await sendAndWait(type: MessageType.speechStart, payload: payload)
        let response = try decoder.decode(SpeechEventResponsePayload.self, from: data)
        return response.event
    }

    public func sendSpeechAudioChunk(_ payload: SpeechAudioChunkPayload) async throws -> [SpeechSessionEvent] {
        let data = try await sendAndWait(type: MessageType.speechAudioChunk, payload: payload)
        let response = try decoder.decode(SpeechEventsResponsePayload.self, from: data)
        return response.events
    }

    /// Control speech session without constructing payloads in callers.
    public func controlSpeechSession(
        sessionId: String,
        command: String,
        reason: String? = nil,
        apiVersion: String? = nil
    ) async throws -> SpeechSessionEvent {
        let payload = SpeechControlPayload(
            apiVersion: apiVersion,
            sessionId: sessionId,
            command: command,
            reason: reason
        )
        return try await controlSpeechSession(payload)
    }

    public func controlSpeechSession(_ payload: SpeechControlPayload) async throws -> SpeechSessionEvent {
        let data = try await sendAndWait(type: MessageType.speechControl, payload: payload)
        let response = try decoder.decode(SpeechEventResponsePayload.self, from: data)
        return response.event
    }

    public func startConciergeCall(
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
    ) async throws -> ConciergeCallEvent {
        let payload = ConciergeCallStartPayload(
            apiVersion: apiVersion,
            callId: callId,
            deviceId: deviceId,
            platform: platform,
            ttsMode: ttsMode,
            targetGatewayId: targetGatewayId,
            displayName: displayName,
            handoffContext: handoffContext,
            spaceId: spaceId,
            spaceUid: spaceUid,
            targetAgentId: targetAgentId
        )
        return try await startConciergeCall(payload)
    }

    public func startConciergeCall(_ payload: ConciergeCallStartPayload) async throws -> ConciergeCallEvent {
        let data = try await sendAndWait(type: MessageType.conciergeCallStart, payload: payload)
        let response = try decoder.decode(ConciergeCallEventResponsePayload.self, from: data)
        return response.event
    }

    public func answerConciergeCall(
        callId: String,
        deviceId: String? = nil,
        platform: String? = nil,
        apiVersion: String? = nil
    ) async throws -> ConciergeCallEvent {
        let payload = ConciergeCallAnswerPayload(
            apiVersion: apiVersion,
            callId: callId,
            deviceId: deviceId,
            platform: platform
        )
        return try await answerConciergeCall(payload)
    }

    public func answerConciergeCall(_ payload: ConciergeCallAnswerPayload) async throws -> ConciergeCallEvent {
        let data = try await sendAndWait(type: MessageType.conciergeCallAnswer, payload: payload)
        let response = try decoder.decode(ConciergeCallEventResponsePayload.self, from: data)
        return response.event
    }

    public func endConciergeCall(
        callId: String,
        reason: String? = nil,
        apiVersion: String? = nil
    ) async throws -> ConciergeCallEvent {
        let payload = ConciergeCallEndPayload(
            apiVersion: apiVersion,
            callId: callId,
            reason: reason
        )
        return try await endConciergeCall(payload)
    }

    public func endConciergeCall(_ payload: ConciergeCallEndPayload) async throws -> ConciergeCallEvent {
        let data = try await sendAndWait(type: MessageType.conciergeCallEnd, payload: payload)
        let response = try decoder.decode(ConciergeCallEventResponsePayload.self, from: data)
        return response.event
    }

    public func setConciergeCallMuted(
        callId: String,
        muted: Bool,
        apiVersion: String? = nil
    ) async throws -> ConciergeCallEvent {
        let payload = ConciergeCallSetMutedPayload(
            apiVersion: apiVersion,
            callId: callId,
            muted: muted
        )
        return try await setConciergeCallMuted(payload)
    }

    public func setConciergeCallMuted(_ payload: ConciergeCallSetMutedPayload) async throws -> ConciergeCallEvent {
        let data = try await sendAndWait(type: MessageType.conciergeCallSetMuted, payload: payload)
        let response = try decoder.decode(ConciergeCallEventResponsePayload.self, from: data)
        return response.event
    }

    public func appendConciergeCallAudio(
        callId: String,
        sequence: Int,
        audioBase64: String,
        audioDurationSeconds: Double? = nil,
        sampleRateHz: Int? = nil,
        channels: Int? = nil,
        codec: String? = nil,
        transcriptText: String? = nil,
        isFinal: Bool? = nil,
        apiVersion: String? = nil
    ) async throws -> [ConciergeCallEvent] {
        let payload = ConciergeCallAudioChunkPayload(
            apiVersion: apiVersion,
            callId: callId,
            sequence: sequence,
            audioBase64: audioBase64,
            audioDurationSeconds: audioDurationSeconds,
            sampleRateHz: sampleRateHz,
            channels: channels,
            codec: codec,
            transcriptText: transcriptText,
            isFinal: isFinal
        )
        return try await appendConciergeCallAudio(payload)
    }

    public func appendConciergeCallAudio(_ payload: ConciergeCallAudioChunkPayload) async throws -> [ConciergeCallEvent] {
        let data = try await sendAndWait(type: MessageType.conciergeCallAudioChunk, payload: payload)
        let response = try decoder.decode(ConciergeCallEventsResponsePayload.self, from: data)
        return response.events
    }

    public func controlConciergeCall(
        callId: String,
        command: String,
        reason: String? = nil,
        apiVersion: String? = nil
    ) async throws -> ConciergeCallEvent {
        let payload = ConciergeCallControlPayload(
            apiVersion: apiVersion,
            callId: callId,
            command: command,
            reason: reason
        )
        return try await controlConciergeCall(payload)
    }

    public func controlConciergeCall(_ payload: ConciergeCallControlPayload) async throws -> ConciergeCallEvent {
        let data = try await sendAndWait(type: MessageType.conciergeCallControl, payload: payload)
        let response = try decoder.decode(ConciergeCallEventResponsePayload.self, from: data)
        return response.event
    }

    public func prepareConciergeCallHandoff(
        callId: String,
        sourceDeviceId: String? = nil,
        destinationPlatform: String,
        destinationDeviceId: String? = nil,
        destinationClientId: String? = nil,
        resumeUrl: String? = nil,
        apiVersion: String? = nil
    ) async throws -> ConciergeCallHandoffPreparation {
        let payload = ConciergeCallHandoffPreparePayload(
            apiVersion: apiVersion,
            callId: callId,
            sourceDeviceId: sourceDeviceId,
            destinationPlatform: destinationPlatform,
            destinationDeviceId: destinationDeviceId,
            destinationClientId: destinationClientId,
            resumeUrl: resumeUrl
        )
        return try await prepareConciergeCallHandoff(payload)
    }

    public func prepareConciergeCallHandoff(_ payload: ConciergeCallHandoffPreparePayload) async throws -> ConciergeCallHandoffPreparation {
        let data = try await sendAndWait(type: MessageType.conciergeCallHandoffPrepare, payload: payload)
        return try decoder.decode(ConciergeCallHandoffPreparation.self, from: data)
    }

    public func acceptConciergeCallHandoff(
        callId: String,
        handoffToken: String,
        deviceId: String? = nil,
        platform: String? = nil,
        apiVersion: String? = nil
    ) async throws -> ConciergeCallEvent {
        let payload = ConciergeCallHandoffAcceptPayload(
            apiVersion: apiVersion,
            callId: callId,
            handoffToken: handoffToken,
            deviceId: deviceId,
            platform: platform
        )
        return try await acceptConciergeCallHandoff(payload)
    }

    public func acceptConciergeCallHandoff(_ payload: ConciergeCallHandoffAcceptPayload) async throws -> ConciergeCallEvent {
        let data = try await sendAndWait(type: MessageType.conciergeCallHandoffAccept, payload: payload)
        let response = try decoder.decode(ConciergeCallEventResponsePayload.self, from: data)
        return response.event
    }

    public func registerConciergeCallPush(
        deviceId: String? = nil,
        platform: String,
        pushToken: String,
        voipTopic: String? = nil,
        proactiveOptIn: Bool? = nil,
        apiVersion: String? = nil
    ) async throws -> ConciergeVoipPushRegistration {
        let payload = ConciergeCallRegisterPushPayload(
            apiVersion: apiVersion,
            deviceId: deviceId,
            platform: platform,
            pushToken: pushToken,
            voipTopic: voipTopic,
            proactiveOptIn: proactiveOptIn
        )
        return try await registerConciergeCallPush(payload)
    }

    public func registerConciergeCallPush(_ payload: ConciergeCallRegisterPushPayload) async throws -> ConciergeVoipPushRegistration {
        let data = try await sendAndWait(type: MessageType.conciergeCallRegisterPush, payload: payload)
        let response = try decoder.decode(ConciergeCallRegisterPushResponsePayload.self, from: data)
        return response.registration
    }
}
