import XCTest
@testable import SpaceskitClient

final class GatewayClientTypesCodableTests: GatewayClientTestCase {

    // MARK: - Types Codable

    func testTurnResultDecoding() throws {
        let json = """
        {
            "turnId": "turn-123",
            "spaceId": "space-456",
            "output": "Hello from agent",
            "status": "completed",
            "mode": "assistant",
            "effort": "high"
        }
        """
        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(TurnResult.self, from: data)

        XCTAssertEqual(result.turnId, "turn-123")
        XCTAssertEqual(result.spaceId, "space-456")
        XCTAssertEqual(result.output, "Hello from agent")
        XCTAssertEqual(result.status, .completed)
        XCTAssertNil(result.error)
        XCTAssertEqual(result.mode, "assistant")
        XCTAssertEqual(result.effort, "high")
    }

    func testTurnStreamDecoding() throws {
        let json = """
        {
            "spaceId": "space-1",
            "spaceUid": "space-uid-1",
            "turnId": "turn-1",
            "agentId": "agent-1",
            "transcriptVisibility": "activity_only",
            "streamKind": "provider_client",
            "delta": "Hello ",
            "seq": 0,
            "done": false
        }
        """
        let data = json.data(using: .utf8)!
        let stream = try JSONDecoder().decode(TurnStream.self, from: data)

        XCTAssertEqual(stream.delta, "Hello ")
        XCTAssertEqual(stream.seq, 0)
        XCTAssertFalse(stream.done)
        XCTAssertEqual(stream.transcriptVisibility, .activityOnly)
        XCTAssertEqual(stream.streamKind, .providerClient)
        XCTAssertNil(stream.timestamp)
    }

    func testTurnStreamDecodingFromInternalEnvelopeShape() throws {
        let json = """
        {
            "type": "space.turn_event",
            "spaceId": "space-1",
            "spaceUid": "space-uid-1",
            "turnId": "turn-1",
            "event": {
                "type": "text_delta",
                "text": "Hello from envelope"
            },
            "timestamp": "2026-02-25T14:00:00Z"
        }
        """
        let data = json.data(using: .utf8)!
        let stream = try JSONDecoder().decode(TurnStream.self, from: data)

        XCTAssertEqual(stream.spaceId, "space-1")
        XCTAssertEqual(stream.turnId, "turn-1")
        XCTAssertEqual(stream.delta, "Hello from envelope")
        XCTAssertFalse(stream.done)
        XCTAssertEqual(stream.timestamp, "2026-02-25T14:00:00Z")
    }

    func testTurnEventDecodingFromInternalEnvelopeShape() throws {
        let json = """
        {
            "type": "space.turn_event",
            "spaceId": "space-1",
            "spaceUid": "space-uid-1",
            "turnId": "turn-1",
            "event": {
                "type": "turn_completed",
                "result": {
                    "finalMessage": { "role": "assistant", "content": "Done." }
                }
            },
            "timestamp": "2026-02-25T14:00:00Z"
        }
        """
        let data = json.data(using: .utf8)!
        let event = try JSONDecoder().decode(TurnEvent.self, from: data)

        XCTAssertEqual(event.spaceId, "space-1")
        XCTAssertEqual(event.turnId, "turn-1")
        XCTAssertEqual(event.eventType, "completed")
        XCTAssertEqual(event.timestamp, "2026-02-25T14:00:00Z")
    }

    func testTurnEventCompatibilityMapsStateChangedLifecycleType() throws {
        let json = """
        {
            "type": "space.turn_event",
            "spaceId": "space-1",
            "spaceUid": "space-uid-1",
            "turnId": "turn-1",
            "event": {
                "type": "state_changed",
                "state": "needs_feedback"
            },
            "timestamp": "2026-02-25T14:00:01Z"
        }
        """
        let event = try JSONDecoder().decode(TurnEvent.self, from: Data(json.utf8))

        XCTAssertEqual(event.eventType, "state_changed")
        XCTAssertEqual(event.timestamp, "2026-02-25T14:00:01Z")
    }

    func testTypedTurnEventPayloadDecodesCanonicalActivityState() throws {
        let json = """
        {
            "kind": "state.changed",
            "state": "acting"
        }
        """

        let payload = try JSONDecoder().decode(TypedTurnEventPayload.self, from: Data(json.utf8))

        guard case .stateChanged(let statePayload) = payload else {
            return XCTFail("Expected state.changed payload")
        }
        XCTAssertEqual(statePayload.state, .acting)
    }

    func testApplePushDeviceRegistrationRequestEncoding() throws {
        let request = ApplePushDeviceRegistrationRequest(
            deviceId: "device-1",
            platform: .ios,
            tokenKind: .voip,
            pushToken: "voip-token-1",
            topic: "io.spaces.app.voip",
            environment: .sandbox,
            appBundleId: "io.spaces.app",
            deviceName: "iPhone",
            metadata: ["locale": AnyCodable("en-US")]
        )

        let json = try encodeJSONObject(request)

        XCTAssertEqual(json["deviceId"] as? String, "device-1")
        XCTAssertEqual(json["platform"] as? String, "ios")
        XCTAssertEqual(json["tokenKind"] as? String, "voip")
        XCTAssertEqual(json["pushToken"] as? String, "voip-token-1")
        XCTAssertEqual(json["topic"] as? String, "io.spaces.app.voip")
        XCTAssertEqual(json["environment"] as? String, "sandbox")
    }

    func testNotificationActionPayloadDecoding() throws {
        let json = """
        {
            "gatewayId": "gateway-1",
            "deliveryId": "delivery-1",
            "feedbackId": "feedback-1",
            "action": "approve",
            "deepLink": "spaces://feedback/feedback-1",
            "payload": {
                "source": "push"
            }
        }
        """

        let context = try JSONDecoder().decode(NotificationActionContext.self, from: Data(json.utf8))

        XCTAssertEqual(context.gatewayId, "gateway-1")
        XCTAssertEqual(context.deliveryId, "delivery-1")
        XCTAssertEqual(context.feedbackId, "feedback-1")
        XCTAssertEqual(context.action, .approve)
        XCTAssertEqual(context.payload?["source"]?.value as? String, "push")
    }

    func testBackgroundFeedbackResolveModelsRoundTrip() throws {
        let request = BackgroundFeedbackResolveRequest(
            deliveryId: "delivery-1",
            action: .revise,
            message: "Use a safer rollout",
            payload: ["scope": AnyCodable("staging")]
        )
        let encoded = try JSONEncoder().encode(request)
        let encodedJSON = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

        XCTAssertEqual(encodedJSON?["deliveryId"] as? String, "delivery-1")
        XCTAssertEqual(encodedJSON?["action"] as? String, "revise")

        let resultJSON = """
        {
            "feedbackId": "feedback-1",
            "action": "revise",
            "status": "resolved",
            "result": {
                "requestId": "feedback-1"
            }
        }
        """
        let result = try JSONDecoder().decode(BackgroundFeedbackActionResult.self, from: Data(resultJSON.utf8))

        XCTAssertEqual(result.feedbackId, "feedback-1")
        XCTAssertEqual(result.action, .revise)
        XCTAssertEqual(result.status, "resolved")
        XCTAssertEqual(result.result?["requestId"]?.value as? String, "feedback-1")
    }

    func testTurnEventResolvedAgentActivityStateFallsBackToLegacyEventPayload() throws {
        let json = """
        {
            "type": "space.turn_event",
            "spaceId": "space-1",
            "spaceUid": "space-uid-1",
            "turnId": "turn-1",
            "event": {
                "type": "state_changed",
                "state": "needs_feedback"
            }
        }
        """

        let event = try JSONDecoder().decode(TurnEvent.self, from: Data(json.utf8))

        XCTAssertEqual(event.resolvedAgentActivityState, .needsFeedback)
        XCTAssertEqual(event.resolvedAgentState, AgentActivityState.needsFeedback.rawValue)
    }

    func testTurnEventCompatibilityMapsReasoningDeltaToStreamingLifecycleType() throws {
        let json = """
        {
            "type": "space.turn_event",
            "spaceId": "space-1",
            "spaceUid": "space-uid-1",
            "turnId": "turn-1",
            "event": {
                "type": "reasoning_delta",
                "text": "Thinking..."
            }
        }
        """
        let event = try JSONDecoder().decode(TurnEvent.self, from: Data(json.utf8))

        XCTAssertEqual(event.eventType, "streaming")
    }

    func testTurnEventCompatibilityMapsToolAndRateLimitLifecycleTypes() throws {
        let toolJson = """
        {
            "type": "space.turn_event",
            "spaceId": "space-1",
            "spaceUid": "space-uid-1",
            "turnId": "turn-1",
            "event": {
                "type": "tool_result",
                "toolResult": {
                    "toolCallId": "call-1",
                    "result": { "ok": true }
                }
            }
        }
        """
        let rateLimitJson = """
        {
            "type": "space.turn_event",
            "spaceId": "space-1",
            "spaceUid": "space-uid-1",
            "turnId": "turn-1",
            "event": {
                "type": "rate_limited",
                "retryAfterMs": 1200
            }
        }
        """

        let toolEvent = try JSONDecoder().decode(TurnEvent.self, from: Data(toolJson.utf8))
        let rateLimitEvent = try JSONDecoder().decode(TurnEvent.self, from: Data(rateLimitJson.utf8))

        XCTAssertEqual(toolEvent.eventType, "tool_call")
        XCTAssertEqual(rateLimitEvent.eventType, "rate_limited")
    }

    func testGatewayIntegrationsSnapshotDecodesSupportedInterconnectors() throws {
        let json = """
        {
            "groups": [],
            "supportedInterconnectors": [
                {
                    "bundleId": "jira-cli",
                    "bundleDisplayName": "Jira CLI",
                    "bundleDescription": "Gateway-managed Jira CLI bundle.",
                    "availabilityStatus": "inactive",
                    "detected": false,
                    "executablePath": null,
                    "installHint": "Install `jira` on the gateway host and make it resolvable, then rescan CLI Tools.",
                    "toolIds": ["jira.issue.view"],
                    "toolCount": 1,
                    "managedEnabled": true,
                    "healthStatus": "unknown",
                    "healthMessage": "Jira CLI is not detected on this gateway.",
                    "updatedAt": "2026-03-09T10:00:00Z"
                }
            ],
            "generatedAt": "2026-03-09T10:00:00Z"
        }
        """
        let snapshot = try JSONDecoder().decode(GatewayIntegrationsSnapshot.self, from: Data(json.utf8))

        XCTAssertEqual(snapshot.supportedInterconnectors?.first?.bundleId, "jira-cli")
        XCTAssertEqual(snapshot.supportedInterconnectors?.first?.availabilityStatus, .inactive)
        XCTAssertEqual(snapshot.supportedInterconnectors?.first?.toolCount, 1)
    }

    func testGatewayNotificationDecodingUsesBodyAndData() throws {
        let json = """
        {
            "notificationId": "notif-1",
            "category": "feedback.requested",
            "severity": "warning",
            "title": "Approval needed",
            "body": "Agent needs your input",
            "spaceId": "space-1",
            "spaceUid": "space-uid-1",
            "agentId": "agent-1",
            "data": {
                "requestId": "request-1"
            },
            "createdAt": "2026-03-14T10:00:00Z"
        }
        """
        let notification = try JSONDecoder().decode(GatewayNotification.self, from: Data(json.utf8))

        XCTAssertEqual(notification.notificationId, "notif-1")
        XCTAssertEqual(notification.body, "Agent needs your input")
        XCTAssertEqual(notification.spaceId, "space-1")
        XCTAssertEqual(notification.data?["requestId"]?.value as? String, "request-1")
    }

    func testGatewayNotificationDecodingFallsBackToLegacyMessageField() throws {
        let json = """
        {
            "notificationId": "notif-2",
            "category": "feedback.requested",
            "severity": "warning",
            "title": "Approval needed",
            "message": "Legacy notification body",
            "createdAt": "2026-03-14T10:00:00Z"
        }
        """
        let notification = try JSONDecoder().decode(GatewayNotification.self, from: Data(json.utf8))

        XCTAssertEqual(notification.notificationId, "notif-2")
        XCTAssertEqual(notification.body, "Legacy notification body")
    }

    func testGatewayErrorDecoding() throws {
        let json = """
        {
            "code": "AUTH_FAILED",
            "message": "Invalid signature"
        }
        """
        let data = json.data(using: .utf8)!
        let error = try JSONDecoder().decode(GatewayError.self, from: data)

        XCTAssertEqual(error.code, "AUTH_FAILED")
        XCTAssertEqual(error.message, "Invalid signature")
    }

    func testSpaceCreateResponsePayloadDecodesWrappedAndLegacyRawShapes() throws {
        let wrapped = """
        {
            "space": {
                "id": "space-1",
                "spaceUid": "space-uid-1",
                "workspace": {
                    "spaceId": "space-1",
                    "spaceUid": "space-uid-1",
                    "mode": "managed",
                    "effectiveWorkspaceRoot": "/tmp/spaces/space-uid-1",
                    "metaPath": "/tmp/spaces/space-uid-1/.space",
                    "logsPath": "/tmp/spaces/space-uid-1/.space/logs",
                    "workPath": "/tmp/spaces/space-uid-1/.space/work",
                    "sharedContextPath": "/tmp/spaces/space-uid-1/.space/shared-context",
                    "scratchpadsPath": "/tmp/spaces/space-uid-1/.space/scratchpads",
                    "updatedAt": "2026-03-14T17:00:00.000Z"
                },
                "resourceId": "resource:main",
                "name": "Main",
                "turnModel": "primary_only",
                "createdAt": "2026-03-14T17:00:00.000Z",
                "updatedAt": "2026-03-14T17:00:00.000Z"
            }
        }
        """
        let legacyRaw = """
        {
            "id": "space-2",
            "spaceUid": "space-uid-2",
            "resourceId": "resource:main",
            "name": "Legacy",
            "turnModel": "primary_only",
            "createdAt": "2026-03-14T17:00:00.000Z",
            "updatedAt": "2026-03-14T17:00:00.000Z"
        }
        """

        let wrappedDecoded = try JSONDecoder().decode(
            SpaceCreateResponsePayload.self,
            from: Data(wrapped.utf8)
        )
        XCTAssertEqual(wrappedDecoded.space.id, "space-1")
        XCTAssertEqual(wrappedDecoded.space.name, "Main")
        XCTAssertEqual(
            wrappedDecoded.space.workspace?.artifactsPath,
            "/tmp/spaces/space-uid-1/.space/artifacts"
        )

        let legacyDecoded = try JSONDecoder().decode(
            SpaceCreateResponsePayload.self,
            from: Data(legacyRaw.utf8)
        )
        XCTAssertEqual(legacyDecoded.space.id, "space-2")
        XCTAssertEqual(legacyDecoded.space.name, "Legacy")
    }

    func testSpaceGetResponsePayloadDecodesWrappedAndLegacyRawShapes() throws {
        let wrapped = """
        {
            "space": {
                "id": "space-3",
                "spaceUid": "space-uid-3",
                "resourceId": "resource:main",
                "name": "Wrapped",
                "turnModel": "primary_only",
                "createdAt": "2026-03-14T17:00:00.000Z",
                "updatedAt": "2026-03-14T17:00:00.000Z"
            }
        }
        """
        let legacyRaw = """
        {
            "id": "space-4",
            "spaceUid": "space-uid-4",
            "resourceId": "resource:main",
            "name": "Raw",
            "turnModel": "primary_only",
            "createdAt": "2026-03-14T17:00:00.000Z",
            "updatedAt": "2026-03-14T17:00:00.000Z"
        }
        """

        let wrappedDecoded = try JSONDecoder().decode(
            SpaceGetResponsePayload.self,
            from: Data(wrapped.utf8)
        )
        XCTAssertEqual(wrappedDecoded.space.id, "space-3")

        let legacyDecoded = try JSONDecoder().decode(
            SpaceGetResponsePayload.self,
            from: Data(legacyRaw.utf8)
        )
        XCTAssertEqual(legacyDecoded.space.id, "space-4")
    }

    func testSpaceListResponsePayloadDecodesWrappedAndLegacyRawArrayShapes() throws {
        let wrapped = """
        {
            "spaces": [
                {
                    "id": "space-5",
                    "spaceUid": "space-uid-5",
                    "workspace": {
                        "spaceId": "space-5",
                        "mode": "managed",
                        "effectiveWorkspaceRoot": "/tmp/spaces/space-uid-5",
                        "metaPath": "/tmp/spaces/space-uid-5/.space",
                        "logsPath": "/tmp/spaces/space-uid-5/.space/logs",
                        "workPath": "/tmp/spaces/space-uid-5/.space/work",
                        "scratchpadsPath": "/tmp/spaces/space-uid-5/.space/scratchpads",
                        "updatedAt": "2026-03-14T17:00:00.000Z"
                    },
                    "resourceId": "resource:main",
                    "name": "Wrapped List",
                    "turnModel": "primary_only",
                    "createdAt": "2026-03-14T17:00:00.000Z",
                    "updatedAt": "2026-03-14T17:00:00.000Z"
                }
            ]
        }
        """
        let legacyRawArray = """
        [
            {
                "id": "space-6",
                "spaceUid": "space-uid-6",
                "resourceId": "resource:main",
                "name": "Raw List",
                "turnModel": "primary_only",
                "createdAt": "2026-03-14T17:00:00.000Z",
                "updatedAt": "2026-03-14T17:00:00.000Z"
            }
        ]
        """

        let wrappedDecoded = try JSONDecoder().decode(
            SpaceListResponsePayload.self,
            from: Data(wrapped.utf8)
        )
        XCTAssertEqual(wrappedDecoded.spaces.count, 1)
        XCTAssertEqual(wrappedDecoded.spaces.first?.id, "space-5")
        XCTAssertEqual(
            wrappedDecoded.spaces.first?.workspace?.sharedContextPath,
            "/tmp/spaces/space-uid-5/.space/shared-context"
        )

        let legacyDecoded = try JSONDecoder().decode(
            SpaceListResponsePayload.self,
            from: Data(legacyRawArray.utf8)
        )
        XCTAssertEqual(legacyDecoded.spaces.count, 1)
        XCTAssertEqual(legacyDecoded.spaces.first?.id, "space-6")
    }
}
