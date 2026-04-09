import Foundation
import XCTest
@testable import SpaceskitClient

final class SpeechContractDecodingTests: XCTestCase {
    func testSpeechSessionEventDecodesCanonicalFields() throws {
        let json = """
        {
          "sessionId": "speech-1",
          "spaceId": "main-space",
          "type": "started",
          "message": "Speech started",
          "intent": {
            "intentType": "space_content",
            "confidence": 0.91,
            "rationale": "clear content request"
          },
          "state": "running",
          "eventType": "session_started",
          "providerSource": "managed",
          "providerId": "managed/default",
          "sequenceNo": 7,
          "emittedAt": "2026-03-20T10:00:00Z",
          "sttRoute": {
            "channel": "stt",
            "source": "managed",
            "providerId": "managed/stt-primary"
          },
          "ttsRoute": {
            "channel": "tts",
            "source": "local_model",
            "providerId": "local/kokoro"
          },
          "lockDecision": {
            "channel": "tts",
            "source": "managed",
            "allowed": false,
            "reason": "managed_tts_chars_limit_reached",
            "fallbackHint": "local_model"
          },
          "fallbackEvent": {
            "channel": "tts",
            "reason": "quota_fallback",
            "detail": "switched to local Kokoro"
          },
          "providerConfigs": [
            {
              "providerId": "managed/stt-primary",
              "channel": "stt",
              "source": "managed",
              "priority": 10,
              "healthStatus": "healthy",
              "costProfile": "hosted"
            }
          ],
          "engineMetrics": {
            "vadDetectionMs": 45,
            "sttTranscriptionMs": 320,
            "ttsFirstAudioMs": 180
          }
        }
        """

        let event = try JSONDecoder().decode(SpeechSessionEvent.self, from: Data(json.utf8))

        XCTAssertEqual(event.sessionId, "speech-1")
        XCTAssertEqual(event.spaceUid, "main-space")
        XCTAssertEqual(event.type, "started")
        XCTAssertEqual(event.message, "Speech started")
        XCTAssertEqual(event.intent?.intentType, "space_content")
        XCTAssertEqual(event.sequence, 7)
        XCTAssertEqual(event.sequenceNo, 7)
        XCTAssertEqual(event.emittedAt, "2026-03-20T10:00:00Z")
        XCTAssertEqual(event.ts, "2026-03-20T10:00:00Z")
        XCTAssertEqual(event.sttRoute?.providerId, "managed/stt-primary")
        XCTAssertEqual(event.ttsRoute?.providerId, "local/kokoro")
        XCTAssertEqual(event.lockDecision?.fallbackHint, "local_model")
        XCTAssertEqual(event.providerConfigs.count, 1)
        XCTAssertEqual(event.engineMetrics?.ttsFirstAudioMs, 180)
    }

    func testSpeechSessionEventDecodesLegacyFields() throws {
        let json = """
        {
          "sessionId": "speech-legacy",
          "spaceId": "main-space",
          "spaceUid": "main-space-uid",
          "state": "running",
          "eventType": "transcript_segment",
          "sequence": 3,
          "ts": "2026-03-20T10:05:00Z"
        }
        """

        let event = try JSONDecoder().decode(SpeechSessionEvent.self, from: Data(json.utf8))

        XCTAssertEqual(event.spaceUid, "main-space-uid")
        XCTAssertEqual(event.sequence, 3)
        XCTAssertEqual(event.sequenceNo, 3)
        XCTAssertEqual(event.emittedAt, "2026-03-20T10:05:00Z")
        XCTAssertEqual(event.ts, "2026-03-20T10:05:00Z")
    }

    func testVoiceUsageSourceSummaryDecodesNestedAndLegacyShapes() throws {
        let nested = """
        {
          "source": "managed",
          "usage": {
            "sttSeconds": 12.5,
            "ttsChars": 90,
            "ttsSeconds": 3.4,
            "estimatedCostUsd": 1.25
          }
        }
        """

        let legacy = """
        {
          "source": "local_model",
          "sttSeconds": 8.0,
          "ttsChars": 45,
          "ttsSeconds": 2.0,
          "estimatedCostUsd": 0.0
        }
        """

        let nestedSummary = try JSONDecoder().decode(VoiceUsageSourceSummary.self, from: Data(nested.utf8))
        let legacySummary = try JSONDecoder().decode(VoiceUsageSourceSummary.self, from: Data(legacy.utf8))

        XCTAssertEqual(nestedSummary.source, "managed")
        XCTAssertEqual(nestedSummary.usage.sttSeconds, 12.5)
        XCTAssertEqual(legacySummary.source, "local_model")
        XCTAssertEqual(legacySummary.usage.ttsChars, 45)
        XCTAssertEqual(legacySummary.estimatedCostUsd, 0.0)
    }
}
