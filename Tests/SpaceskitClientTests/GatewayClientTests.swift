// GatewayClientTests.swift — Basic tests for Spaceskit Swift Client SDK

import XCTest
@testable import SpaceskitClient

final class GatewayClientTests: XCTestCase {

    private func loadFixture(_ name: String) throws -> Data {
        let fixtureDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
        return try Data(contentsOf: fixtureDir.appendingPathComponent("\(name).json"))
    }

    private func encodeJSONObject<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let json = try JSONSerialization.jsonObject(with: data)
        guard let dict = json as? [String: Any] else {
            XCTFail("Expected encoded JSON dictionary.")
            return [:]
        }
        return dict
    }

    private func waitForPendingRequest(
        _ messageId: String,
        on client: GatewayClient,
        maxAttempts: Int = 200,
        pollIntervalNanos: UInt64 = 5_000_000
    ) async -> Bool {
        for _ in 0..<maxAttempts {
            if await client.hasPendingRequestForTesting(messageId) {
                return true
            }
            try? await Task.sleep(nanoseconds: pollIntervalNanos)
        }
        return await client.hasPendingRequestForTesting(messageId)
    }

    private func waitForNextEvent(
        from stream: AsyncStream<GatewayEvent>,
        timeoutNanoseconds: UInt64 = 500_000_000
    ) async -> GatewayEvent? {
        await withTaskGroup(of: GatewayEvent?.self) { group in
            group.addTask {
                var iterator = stream.makeAsyncIterator()
                return await iterator.next()
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                return nil
            }

            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    // MARK: - Auth Key Pair

    func testAuthKeyPairGeneration() throws {
        let keyPair = AuthKeyPair()

        // Public key should be 32 bytes → 44 chars in base64
        XCTAssertFalse(keyPair.publicKeyBase64.isEmpty)
        XCTAssertEqual(keyPair.publicKey.rawRepresentation.count, 32)
    }

    func testAuthKeyPairFromRawKey() throws {
        let original = AuthKeyPair()
        let rawKey = original.privateKey.rawRepresentation

        let restored = try AuthKeyPair(rawPrivateKey: rawKey)
        XCTAssertEqual(restored.publicKeyBase64, original.publicKeyBase64)
    }

    // MARK: - Challenge Signing

    func testSignAndVerifyChallenge() throws {
        let keyPair = AuthKeyPair()

        // Simulate a 32-byte challenge (like the server sends)
        let challengeBytes = (0..<32).map { _ in UInt8.random(in: 0...255) }
        let challengeBase64 = Data(challengeBytes).base64EncodedString()

        // Sign the challenge
        let signature = try signChallenge(challengeBase64, with: keyPair)
        XCTAssertFalse(signature.isEmpty)

        // Verify the signature
        let isValid = verifySignature(
            signature,
            for: challengeBase64,
            publicKey: keyPair.publicKey
        )
        XCTAssertTrue(isValid, "Signature should be valid")
    }

    func testSignChallengeWithInvalidBase64() {
        let keyPair = AuthKeyPair()

        XCTAssertThrowsError(try signChallenge("not-valid-base64!!!", with: keyPair)) { error in
            XCTAssertTrue(error is AuthError)
        }
    }

    func testVerifyWithWrongKey() throws {
        let keyPair1 = AuthKeyPair()
        let keyPair2 = AuthKeyPair()

        let challengeBytes = (0..<32).map { _ in UInt8.random(in: 0...255) }
        let challengeBase64 = Data(challengeBytes).base64EncodedString()

        let signature = try signChallenge(challengeBase64, with: keyPair1)

        // Verify with wrong public key should fail
        let isValid = verifySignature(
            signature,
            for: challengeBase64,
            publicKey: keyPair2.publicKey
        )
        XCTAssertFalse(isValid, "Signature should be invalid with wrong key")
    }

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

    // MARK: - Protocol Message Encoding

    func testGatewayMessageEncoding() throws {
        let payload = ExecuteTurnPayload(
            spaceUid: "11111111-2222-3333-4444-555555555555",
            input: "Hello",
            targetAgentId: "agent-1",
            replyToTurnId: "turn-0",
            mode: "assistant",
            effort: "medium"
        )
        let message = GatewayMessage(
            type: MessageType.executeTurn,
            id: "msg-1",
            payload: payload
        )

        let data = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["type"] as? String, "execute_turn")
        XCTAssertEqual(json["id"] as? String, "msg-1")
        XCTAssertNotNil(json["ts"])

        let payloadDict = json["payload"] as! [String: Any]
        XCTAssertEqual(payloadDict["spaceUid"] as? String, "11111111-2222-3333-4444-555555555555")
        XCTAssertEqual(payloadDict["input"] as? String, "Hello")
        XCTAssertEqual(payloadDict["targetAgentId"] as? String, "agent-1")
        XCTAssertEqual(payloadDict["replyToTurnId"] as? String, "turn-0")
        XCTAssertEqual(payloadDict["mode"] as? String, "assistant")
        XCTAssertEqual(payloadDict["effort"] as? String, "medium")
    }

    func testExecuteTurnOptionsPayloadEncoding() throws {
        let options = ExecuteTurnOptions(
            spaceUid: "space-1",
            input: "Draft a plan",
            targetAgentId: "agent-7",
            replyToTurnId: "turn-6",
            mode: "planner",
            effort: "high"
        )
        let payload = ExecuteTurnPayload(options)
        let json = try encodeJSONObject(payload)

        XCTAssertEqual(json["spaceUid"] as? String, "space-1")
        XCTAssertEqual(json["input"] as? String, "Draft a plan")
        XCTAssertEqual(json["targetAgentId"] as? String, "agent-7")
        XCTAssertEqual(json["replyToTurnId"] as? String, "turn-6")
        XCTAssertEqual(json["mode"] as? String, "planner")
        XCTAssertEqual(json["effort"] as? String, "high")
    }

    func testResumeFeedbackPayloadEncodingIncludesApprovalGrant() throws {
        let payload = ResumeFeedbackPayload(
            spaceUid: "space-1",
            turnId: "turn-7",
            response: .approve,
            revision: "rev-2",
            approvalGrant: ApprovalGrantPayload(
                mode: .timeWindow,
                ttlSeconds: 900
            )
        )
        let json = try encodeJSONObject(payload)

        XCTAssertEqual(json["spaceUid"] as? String, "space-1")
        XCTAssertEqual(json["turnId"] as? String, "turn-7")
        XCTAssertEqual(json["response"] as? String, "approve")
        XCTAssertEqual(json["revision"] as? String, "rev-2")

        let approvalGrant = try XCTUnwrap(json["approvalGrant"] as? [String: Any])
        XCTAssertEqual(approvalGrant["mode"] as? String, "time_window")
        XCTAssertEqual(approvalGrant["ttlSeconds"] as? Int, 900)
    }

    func testConnectorListPayloadEncoding() throws {
        let payload = GatewayListConnectorsPayload(apiVersion: "v1", familyId: "apple-calendar-eventkit")
        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["apiVersion"] as? String, "v1")
        XCTAssertEqual(json?["familyId"] as? String, "apple-calendar-eventkit")
    }

    func testGatewayRegisterToolPayloadEncodingIncludesBundleMetadata() throws {
        let payload = GatewayRegisterToolPayload(
            apiVersion: "v1",
            schemaVersion: 1,
            id: "tool.rg_search",
            displayName: "Ripgrep Search",
            description: "Search the workspace with ripgrep.",
            bundleId: "search-cli",
            bundleDisplayName: "Search CLI",
            bundleDescription: "Repository search helpers.",
            toolGroupId: "workspace",
            toolGroupDisplayName: "Workspace",
            executable: "/usr/bin/rg",
            argsTemplate: ["--json", "{{query}}"],
            inputSchema: [
                "type": "object",
                "properties": [
                    "query": [
                        "type": "string"
                    ]
                ]
            ],
            instructions: "Use this for repository text search only.",
            examples: [
                GatewayToolExample(
                    name: "Find TODO comments",
                    description: "Search for TODO markers.",
                    arguments: ["query": "TODO"],
                    expectedOutput: "JSON lines from ripgrep."
                )
            ],
            timeoutMs: 5_000,
            maxOutputBytes: 131_072,
            cwdMode: "space_root",
            outputMode: "json",
            dangerLevel: .standard,
            readme: "# Ripgrep Search",
            enabled: false
        )
        let json = try encodeJSONObject(payload)

        XCTAssertEqual(json["schemaVersion"] as? Int, 1)
        XCTAssertEqual(json["instructions"] as? String, "Use this for repository text search only.")
        XCTAssertEqual(json["maxOutputBytes"] as? Int, 131_072)
        XCTAssertEqual(json["dangerLevel"] as? String, "standard")
        XCTAssertEqual(json["bundleId"] as? String, "search-cli")
        XCTAssertEqual(json["bundleDisplayName"] as? String, "Search CLI")
        XCTAssertEqual(json["bundleDescription"] as? String, "Repository search helpers.")
        XCTAssertEqual(json["toolGroupId"] as? String, "workspace")
        XCTAssertEqual(json["toolGroupDisplayName"] as? String, "Workspace")
        XCTAssertEqual(json["enabled"] as? Bool, false)

        let examples = try XCTUnwrap(json["examples"] as? [[String: Any]])
        XCTAssertEqual(examples.count, 1)
        let firstExample = try XCTUnwrap(examples.first)
        XCTAssertEqual(firstExample["name"] as? String, "Find TODO comments")
    }

    func testGatewaySetToolEnabledPayloadEncodingIncludesEnabledFlag() throws {
        let payload = GatewaySetToolEnabledPayload(
            apiVersion: "v1",
            toolId: "tool.rg_search",
            enabled: false
        )
        let json = try encodeJSONObject(payload)

        XCTAssertEqual(json["apiVersion"] as? String, "v1")
        XCTAssertEqual(json["toolId"] as? String, "tool.rg_search")
        XCTAssertEqual(json["enabled"] as? Bool, false)
    }

    func testGatewaySetToolEnabledResponseDecodingPreservesEnabledFlag() throws {
        let json = """
        {
            "tools": [
                {
                    "schemaVersion": 1,
                    "id": "tool.rg_search",
                    "providerId": "cli-tool-service",
                    "displayName": "Ripgrep Search",
                    "description": "Search the workspace with ripgrep.",
                    "bundleId": "search-cli",
                    "bundleDisplayName": "Search CLI",
                    "bundleDescription": "Repository search helpers.",
                    "toolGroupId": "workspace",
                    "toolGroupDisplayName": "Workspace",
                    "executable": "rg",
                    "resolvedExecutable": "/usr/bin/rg",
                    "argsTemplate": ["--json", "{{query}}"],
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "query": { "type": "string" }
                        }
                    },
                    "instructions": "Use this for repository text search only.",
                    "examples": [],
                    "timeoutMs": 5000,
                    "maxOutputBytes": 131072,
                    "cwdMode": "space_root",
                    "fixedCwd": null,
                    "outputMode": "json",
                    "dangerLevel": "standard",
                    "enabled": false,
                    "available": true,
                    "healthStatus": "unknown",
                    "healthMessage": null,
                    "manifestPath": "/tmp/tools/tool.rg_search/manifest.json",
                    "readmePath": null,
                    "readmeContent": null,
                    "requiresApproval": true,
                    "createdAt": "2026-03-09T10:00:00Z",
                    "updatedAt": "2026-03-09T10:00:00Z"
                }
            ]
        }
        """

        let decoded = try JSONDecoder().decode(
            GatewaySetToolEnabledResponsePayload.self,
            from: Data(json.utf8)
        )
        XCTAssertEqual(decoded.tools.count, 1)
        XCTAssertEqual(decoded.tools.first?.id, "tool.rg_search")
        XCTAssertFalse(decoded.tools.first?.enabled ?? true)
    }

    func testSpaceListTurnsPayloadEncoding() throws {
        let payload = SpaceListTurnsPayload(
            apiVersion: "v1",
            spaceId: "space-main",
            spaceUid: "space-uid-main",
            limit: 100,
            offset: 200
        )
        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["apiVersion"] as? String, "v1")
        XCTAssertEqual(json?["spaceId"] as? String, "space-main")
        XCTAssertEqual(json?["spaceUid"] as? String, "space-uid-main")
        XCTAssertEqual(json?["limit"] as? Int, 100)
        XCTAssertEqual(json?["offset"] as? Int, 200)
    }

    func testSpaceListTurnsPayloadEncodingWithCursor() throws {
        let payload = SpaceListTurnsPayload(
            apiVersion: "v1",
            spaceId: "space-main",
            spaceUid: "space-uid-main",
            limit: 50,
            offset: 0,
            lastSeenTurnId: "turn-seen-1"
        )
        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["spaceId"] as? String, "space-main")
        XCTAssertEqual(json?["spaceUid"] as? String, "space-uid-main")
        XCTAssertEqual(json?["limit"] as? Int, 50)
        XCTAssertEqual(json?["offset"] as? Int, 0)
        XCTAssertEqual(json?["lastSeenTurnId"] as? String, "turn-seen-1")
    }

    func testSpaceListTurnsResponseDecoding() throws {
        let json = """
        {
            "spaceId": "space-main",
            "spaceUid": "space-uid-main",
            "turns": [
                {
                    "turnId": "turn-1",
                    "agentId": "agent-main",
                    "status": "completed",
                    "inputText": "Hello",
                    "outputText": "Hi there",
                    "mode": "assistant",
                    "effort": "medium",
                    "createdAt": "2026-02-26T12:00:00.000Z",
                    "completedAt": "2026-02-26T12:00:01.000Z"
                }
            ],
            "total": 1,
            "nextOffset": null
        }
        """

        let decoded = try JSONDecoder().decode(SpaceListTurnsResponsePayload.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.spaceId, "space-main")
        XCTAssertEqual(decoded.spaceUid, "space-uid-main")
        XCTAssertEqual(decoded.turns.count, 1)
        XCTAssertEqual(decoded.turns.first?.turnId, "turn-1")
        XCTAssertEqual(decoded.turns.first?.mode, "assistant")
        XCTAssertEqual(decoded.turns.first?.effort, "medium")
        XCTAssertEqual(decoded.total, 1)
        XCTAssertNil(decoded.nextOffset)
    }

    func testUpsertConnectorResponseDecoding() throws {
        let json = """
        {
            "connector": {
                "connectorId": "apple-calendar-eventkit:acct_12345678:primary",
                "familyId": "apple-calendar-eventkit",
                "displayName": "Primary Calendar",
                "accountFingerprintHash": "hash-123",
                "labelSlug": "primary",
                "status": "active",
                "metadata": { "region": "us-east-1" },
                "createdAt": "2026-02-24T00:00:00.000Z",
                "updatedAt": "2026-02-24T00:00:00.000Z"
            }
        }
        """

        let decoded = try JSONDecoder().decode(GatewayUpsertConnectorResponsePayload.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.connector.connectorId, "apple-calendar-eventkit:acct_12345678:primary")
        XCTAssertEqual(decoded.connector.status, .active)
        XCTAssertEqual(decoded.connector.metadata["region"]?.value as? String, "us-east-1")
    }

    func testConnectorPolicyResponseDecoding() throws {
        let json = """
        {
            "policy": {
                "scopeType": "instance",
                "scopeId": "apple-calendar-eventkit:acct_12345678:primary",
                "requestsPerMinute": 120,
                "burst": 60,
                "disabled": false,
                "disableReason": null,
                "disabledUntil": null,
                "updatedBy": "test-suite",
                "updatedAt": "2026-02-24T00:00:00.000Z"
            }
        }
        """

        let decoded = try JSONDecoder().decode(GatewayGetConnectorPolicyResponsePayload.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.policy.scopeType, .instance)
        XCTAssertEqual(decoded.policy.requestsPerMinute, 120)
        XCTAssertFalse(decoded.policy.disabled)
    }

    func testCapabilityGrantAndRevokeDecoding() throws {
        let grantJSON = """
        {
            "grant": {
                "principalId": "principal-1",
                "deviceId": "device-1",
                "capabilityId": "speech.execute",
                "level": "execute",
                "source": "runtime",
                "reason": "integration test",
                "grantedBy": "admin",
                "grantedAt": "2026-02-24T00:00:00.000Z",
                "expiresAt": null,
                "revokedAt": null,
                "updatedAt": "2026-02-24T00:00:00.000Z"
            }
        }
        """
        let grantResponse = try JSONDecoder().decode(GatewayGrantCapabilityResponsePayload.self, from: Data(grantJSON.utf8))
        XCTAssertEqual(grantResponse.grant.capabilityId, "speech.execute")
        XCTAssertEqual(grantResponse.grant.level, .execute)

        let revokeJSON = """
        {
            "revoked": true,
            "capabilityId": "speech.execute",
            "principalId": "principal-1",
            "deviceId": "device-1",
            "grant": {
                "principalId": "principal-1",
                "deviceId": "device-1",
                "capabilityId": "speech.execute",
                "level": "execute",
                "source": "runtime",
                "reason": "integration test",
                "grantedBy": "admin",
                "grantedAt": "2026-02-24T00:00:00.000Z",
                "expiresAt": null,
                "revokedAt": "2026-02-24T00:10:00.000Z",
                "updatedAt": "2026-02-24T00:10:00.000Z"
            }
        }
        """
        let revokeResponse = try JSONDecoder().decode(GatewayRevokeCapabilityResponsePayload.self, from: Data(revokeJSON.utf8))
        XCTAssertTrue(revokeResponse.revoked)
        XCTAssertEqual(revokeResponse.grant?.revokedAt, "2026-02-24T00:10:00.000Z")
    }

    func testGatewayToolResponseDecoding() throws {
        let json = """
        {
            "tool": {
                "schemaVersion": 1,
                "id": "tool.rg_search",
                "providerId": "cli-tool-service",
                "displayName": "Ripgrep Search",
                "description": "Search the workspace with ripgrep.",
                "bundleId": "search-cli",
                "bundleDisplayName": "Search CLI",
                "bundleDescription": "Repository search helpers.",
                "toolGroupId": "workspace",
                "toolGroupDisplayName": "Workspace",
                "executable": "rg",
                "resolvedExecutable": "/usr/bin/rg",
                "argsTemplate": ["--json", "{{query}}"],
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": { "type": "string" }
                    }
                },
                "instructions": "Use this for repository text search only.",
                "examples": [
                    {
                        "name": "Find TODO comments",
                        "description": "Search for TODO markers.",
                        "arguments": { "query": "TODO" },
                        "expectedOutput": "JSON lines from ripgrep."
                    }
                ],
                "timeoutMs": 5000,
                "maxOutputBytes": 131072,
                "cwdMode": "space_root",
                "fixedCwd": null,
                "outputMode": "json",
                "dangerLevel": "standard",
                "available": true,
                "healthStatus": "degraded",
                "healthMessage": "Jira auth is unavailable on this gateway.",
                "manifestPath": "/tmp/tools/tool.rg_search/manifest.json",
                "readmePath": "/tmp/tools/tool.rg_search/README.md",
                "readmeContent": "# Ripgrep Search\\n\\nUse responsibly.",
                "requiresApproval": true,
                "createdAt": "2026-03-09T10:00:00Z",
                "updatedAt": "2026-03-09T10:00:00Z"
            }
        }
        """

        let decoded = try JSONDecoder().decode(GatewayGetToolResponsePayload.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.tool?.schemaVersion, 1)
        XCTAssertEqual(decoded.tool?.dangerLevel, .standard)
        XCTAssertEqual(decoded.tool?.healthStatus, .degraded)
        XCTAssertEqual(decoded.tool?.healthMessage, "Jira auth is unavailable on this gateway.")
        XCTAssertEqual(decoded.tool?.bundleId, "search-cli")
        XCTAssertEqual(decoded.tool?.bundleDisplayName, "Search CLI")
        XCTAssertEqual(decoded.tool?.bundleDescription, "Repository search helpers.")
        XCTAssertEqual(decoded.tool?.toolGroupId, "workspace")
        XCTAssertEqual(decoded.tool?.toolGroupDisplayName, "Workspace")
        XCTAssertEqual(decoded.tool?.examples.first?.arguments["query"]?.value as? String, "TODO")
        XCTAssertEqual(decoded.tool?.readmeContent, "# Ripgrep Search\n\nUse responsibly.")
        XCTAssertTrue(decoded.tool?.enabled ?? false)
    }

    func testGatewayRescanJiraCliToolsResponseDecoding() throws {
        let json = """
        {
            "detected": true,
            "toolCount": 22,
            "toolIds": ["jira.me", "jira.issue.view"],
            "removedToolIds": [],
            "healthStatus": "ok",
            "healthMessage": null,
            "executablePath": "/opt/homebrew/bin/jira"
        }
        """

        let decoded = try JSONDecoder().decode(
            GatewayRescanJiraCliToolsResponsePayload.self,
            from: Data(json.utf8)
        )
        XCTAssertTrue(decoded.detected)
        XCTAssertEqual(decoded.toolCount, 22)
        XCTAssertEqual(decoded.toolIds, ["jira.me", "jira.issue.view"])
        XCTAssertEqual(decoded.removedToolIds, [])
        XCTAssertEqual(decoded.healthStatus, .ok)
        XCTAssertNil(decoded.healthMessage)
        XCTAssertEqual(decoded.executablePath, "/opt/homebrew/bin/jira")
    }

    func testGatewayToolApprovalGrantResponseDecoding() throws {
        let json = """
        {
            "grants": [
                {
                    "principalId": "principal-1",
                    "deviceId": "device-1",
                    "spaceId": "space-1",
                    "toolId": "tool.rg_search",
                    "mode": "durable",
                    "source": "runtime",
                    "reason": "Approved from review sheet.",
                    "grantedBy": "admin",
                    "grantedAt": "2026-03-09T10:05:00Z",
                    "expiresAt": null,
                    "revokedAt": null,
                    "updatedAt": "2026-03-09T10:05:00Z"
                }
            ]
        }
        """

        let decoded = try JSONDecoder().decode(GatewayListToolApprovalGrantsResponsePayload.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.grants.count, 1)
        XCTAssertEqual(decoded.grants.first?.mode, .durable)
        XCTAssertEqual(decoded.grants.first?.toolId, "tool.rg_search")
    }

    func testSpaceGetMcpEndpointResponseDecoding() throws {
        let json = """
        {
            "spaceId": "space-1",
            "endpoint": {
                "endpointId": "mcp-endpoint-1",
                "spaceId": "space-1",
                "transport": "stdio",
                "endpoint": "npx",
                "args": ["-y", "@modelcontextprotocol/server-filesystem"],
                "secretRef": null,
                "enabled": true,
                "healthStatus": "ok",
                "healthMessage": "Connected",
                "lastConnectedAt": "2026-03-09T10:04:00Z",
                "lastErrorAt": null,
                "createdAt": "2026-03-09T10:00:00Z",
                "updatedAt": "2026-03-09T10:04:00Z"
            },
            "fallbackEnabled": false
        }
        """

        let decoded = try JSONDecoder().decode(SpaceGetMcpEndpointResponsePayload.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.endpoint?.transport, .stdio)
        XCTAssertEqual(decoded.endpoint?.healthStatus, .ok)
        XCTAssertEqual(decoded.endpoint?.args.count, 2)
        XCTAssertFalse(decoded.fallbackEnabled)
    }

    func testProviderConfigAndSecretRefDecoding() throws {
        let providerConfigJSON = """
        {
            "providerId": "openrouter",
            "model": "openrouter/openai/gpt-4.1-mini",
            "baseURL": null,
            "hasApiKey": true,
            "apiKeySecretRef": "secretref-openrouter-primary",
            "allowedModels": ["openrouter/openai/gpt-4.1-mini"],
            "allowCustomModel": false,
            "updatedAt": "2026-02-24T00:00:00.000Z",
            "source": "runtime"
        }
        """
        let providerConfig = try JSONDecoder().decode(GatewayProviderRuntimeConfig.self, from: Data(providerConfigJSON.utf8))
        XCTAssertEqual(providerConfig.apiKeySecretRef, "secretref-openrouter-primary")
        XCTAssertEqual(providerConfig.allowedModels, ["openrouter/openai/gpt-4.1-mini"])
        XCTAssertFalse(providerConfig.allowCustomModel)

        let putSecretRefJSON = """
        {
            "secretRef": {
                "secretRef": "secretref-openrouter-primary",
                "providerId": "openrouter",
                "label": "OpenRouter Primary",
                "backend": "gateway_encrypted",
                "createdAt": "2026-02-24T00:00:00.000Z",
                "updatedAt": "2026-02-24T00:00:00.000Z",
                "lastUsedAt": null
            },
            "created": true
        }
        """
        let secretRefResult = try JSONDecoder().decode(GatewayPutSecretRefResult.self, from: Data(putSecretRefJSON.utf8))
        XCTAssertTrue(secretRefResult.created)
        XCTAssertEqual(secretRefResult.secretRef.providerId, "openrouter")

        let localAgentJSON = """
        {
            "id": "lmstudio",
            "name": "LM Studio",
            "detected": true,
            "serviceReachable": true,
            "recommendedProviderId": "openai",
            "recommendedModel": "openai/qwen2.5-coder",
            "requiresApiKey": false,
            "availableModels": ["openai/qwen2.5-coder", "openai/deepseek-r1"],
            "detectionError": null,
            "notes": "Local endpoint"
        }
        """
        let localAgent = try JSONDecoder().decode(DiscoveredLocalAgent.self, from: Data(localAgentJSON.utf8))
        XCTAssertEqual(localAgent.availableModels?.count, 2)
    }

    func testProviderAuthModeAndCatalogAuthMetadataDecoding() throws {
        let providerConfigJSON = """
        {
            "providerId": "claude-agent-sdk",
            "model": "claude-agent-sdk/claude-sonnet-4-5",
            "baseURL": null,
            "hasApiKey": false,
            "apiKeySecretRef": null,
            "authMode": "host_login",
            "allowedModels": ["claude-agent-sdk/claude-sonnet-4-5"],
            "allowCustomModel": false,
            "updatedAt": "2026-04-08T09:00:00.000Z",
            "source": "runtime"
        }
        """

        let providerConfig = try JSONDecoder().decode(GatewayProviderRuntimeConfig.self, from: Data(providerConfigJSON.utf8))
        XCTAssertEqual(providerConfig.authMode, .hostLogin)
        XCTAssertFalse(providerConfig.hasApiKey)

        let catalogJSON = """
        {
            "providerId": "claude-agent-sdk",
            "displayName": "Claude Agent SDK",
            "group": "executor",
            "integrationClass": "executor",
            "status": "needs_auth",
            "hasApiKey": false,
            "requiresApiKey": false,
            "supportedAuthModes": ["api_key", "host_login"],
            "authMode": "host_login",
            "authStatus": "needs_auth",
            "authAccount": {
                "email": "agent@example.com",
                "organization": "Acme",
                "subscriptionType": "max",
                "apiProvider": "firstParty",
                "tokenSource": "oauth"
            },
            "detectionStatus": "available",
            "models": [
                {
                    "id": "claude-agent-sdk/claude-sonnet-4-6",
                    "displayName": "Claude Sonnet 4.6",
                    "source": "detected",
                    "available": true
                }
            ],
            "recommended": false,
            "supportsHostedBilling": false,
            "configAllowed": true
        }
        """

        let catalog = try JSONDecoder().decode(GatewayModelProviderCatalog.self, from: Data(catalogJSON.utf8))
        XCTAssertEqual(catalog.supportedAuthModes, [.apiKey, .hostLogin])
        XCTAssertEqual(catalog.authMode, .hostLogin)
        XCTAssertEqual(catalog.authStatus, .needsAuth)
        XCTAssertEqual(catalog.authAccount?.email, "agent@example.com")
        XCTAssertEqual(catalog.authAccount?.subscriptionType, "max")
    }

    func testListAvailableModelsPayloadAndResponseDecoding() throws {
        let payload = GatewayListAvailableModelsPayload(apiVersion: "v1", providerId: "openai", refresh: true)
        let payloadJSON = try encodeJSONObject(payload)
        XCTAssertEqual(payloadJSON["providerId"] as? String, "openai")
        XCTAssertEqual(payloadJSON["refresh"] as? Bool, true)

        let responseJSON = """
        {
            "providers": [
                {
                    "providerId": "openai",
                    "displayName": "OpenAI-Compatible",
                    "group": "local_runtime",
                    "hasApiKey": false,
                    "requiresApiKey": false,
                    "baseURL": "http://127.0.0.1:1234/v1",
                    "detectionStatus": "available",
                    "detectionError": null,
                    "models": [
                        {
                            "id": "openai/qwen2.5-coder",
                            "displayName": "qwen2.5-coder",
                            "source": "allowlist",
                            "available": true
                        }
                    ]
                }
            ],
            "generatedAt": "2026-02-24T00:00:00.000Z"
        }
        """
        let response = try JSONDecoder().decode(
            GatewayListAvailableModelsResponsePayload.self,
            from: Data(responseJSON.utf8)
        )
        XCTAssertEqual(response.providers.count, 1)
        XCTAssertEqual(response.providers[0].providerId, "openai")
        XCTAssertEqual(response.providers[0].displayName, "OpenAI-Compatible")
        XCTAssertEqual(response.providers[0].group, .localRuntime)
        XCTAssertEqual(response.providers[0].models[0].source, .allowlist)
        XCTAssertEqual(response.providers[0].models[0].id, "openai/qwen2.5-coder")
    }

    func testProviderSettingsPayloadAndResponseDecoding() throws {
        let listCatalogsPayload = GatewayListProviderCatalogsPayload(
            apiVersion: "v1",
            providerId: "openai",
            refresh: true
        )
        let listCatalogsJSON = try encodeJSONObject(listCatalogsPayload)
        XCTAssertEqual(listCatalogsJSON["providerId"] as? String, "openai")
        XCTAssertEqual(listCatalogsJSON["refresh"] as? Bool, true)

        let getSettingsPayload = GatewayGetProviderSettingsPayload(apiVersion: "v1", providerId: "openai")
        let getSettingsJSON = try encodeJSONObject(getSettingsPayload)
        XCTAssertEqual(getSettingsJSON["providerId"] as? String, "openai")

        let setConfigPayload = GatewaySetProviderConfigPayload(
            apiVersion: "v1",
            providerId: "claude-agent-sdk",
            model: "claude-agent-sdk/claude-sonnet-4-5",
            apiKey: nil,
            apiKeySecretRef: "secretref-claude-primary",
            authMode: .hostLogin,
            baseURL: nil,
            allowedModels: ["claude-agent-sdk/claude-sonnet-4-5"],
            allowCustomModel: false
        )
        let setConfigJSON = try encodeJSONObject(setConfigPayload)
        XCTAssertEqual(setConfigJSON["providerId"] as? String, "claude-agent-sdk")
        XCTAssertEqual(setConfigJSON["authMode"] as? String, "host_login")
        XCTAssertEqual(setConfigJSON["allowCustomModel"] as? Bool, false)
        XCTAssertEqual(
            setConfigJSON["allowedModels"] as? [String],
            ["claude-agent-sdk/claude-sonnet-4-5"]
        )

        let updateSettingsPayload = GatewayUpdateProviderSettingsPayload(
            apiVersion: "v1",
            providerId: "claude-agent-sdk",
            model: "claude-agent-sdk/claude-sonnet-4-5",
            apiKey: nil,
            apiKeySecretRef: "secretref-claude-primary",
            authMode: .hostLogin,
            baseURL: nil,
            allowedModels: ["claude-agent-sdk/claude-sonnet-4-5"],
            allowCustomModel: false
        )
        let updateSettingsJSON = try encodeJSONObject(updateSettingsPayload)
        XCTAssertEqual(updateSettingsJSON["providerId"] as? String, "claude-agent-sdk")
        XCTAssertEqual(updateSettingsJSON["authMode"] as? String, "host_login")
        XCTAssertEqual(updateSettingsJSON["allowCustomModel"] as? Bool, false)

        let listCatalogsResponseJSON = """
        {
            "providers": [
                {
                    "providerId": "openai",
                    "displayName": "OpenAI-Compatible",
                    "group": "local_runtime",
                    "hasApiKey": false,
                    "requiresApiKey": false,
                    "baseURL": "http://127.0.0.1:1234/v1",
                    "detectionStatus": "available",
                    "detectionError": null,
                    "models": [
                        {
                            "id": "openai/qwen2.5-coder",
                            "displayName": "qwen2.5-coder",
                            "source": "allowlist",
                            "available": true
                        }
                    ]
                }
            ],
            "generatedAt": "2026-02-24T00:00:00.000Z"
        }
        """
        let listCatalogsResponse = try JSONDecoder().decode(
            GatewayListProviderCatalogsResponsePayload.self,
            from: Data(listCatalogsResponseJSON.utf8)
        )
        XCTAssertEqual(listCatalogsResponse.providers.count, 1)
        XCTAssertEqual(listCatalogsResponse.providers[0].group, .localRuntime)

        let settingsJSON = """
        {
            "settings": {
                "providerId": "openai",
                "model": "openai/qwen2.5-coder",
                "baseURL": "http://127.0.0.1:1234/v1",
                "hasApiKey": true,
                "apiKeySecretRef": "secretref-openai-primary",
                "allowedModels": ["openai/qwen2.5-coder"],
                "allowCustomModel": false,
                "updatedAt": "2026-02-24T00:00:00.000Z",
                "source": "runtime"
            }
        }
        """
        let getSettingsResponse = try JSONDecoder().decode(
            GatewayGetProviderSettingsResponsePayload.self,
            from: Data(settingsJSON.utf8)
        )
        XCTAssertEqual(getSettingsResponse.settings.providerId, "openai")
        XCTAssertFalse(getSettingsResponse.settings.allowCustomModel)

        let updateSettingsResponse = try JSONDecoder().decode(
            GatewayUpdateProviderSettingsResponsePayload.self,
            from: Data(settingsJSON.utf8)
        )
        XCTAssertEqual(updateSettingsResponse.settings.allowedModels, ["openai/qwen2.5-coder"])
    }

    func testSpaceUsageDecodesAccuracyMetadata() throws {
        let usageJSON = """
        {
            "spaceUsage": {
                "spaceId": "space-usage-1",
                "stagingBytes": 0,
                "openChangeSets": 0,
                "appliedChangeSetsPerMonth": 0,
                "inputTokens": 120,
                "outputTokens": 30,
                "totalTokens": 150,
                "tokenSpendUsd": 0.0045,
                "tokenAccuracy": "reported",
                "usageSource": "ledger",
                "updatedAt": "2026-03-07T10:00:00.000Z"
            },
            "agentSessions": [
                {
                    "sessionId": "session-1",
                    "spaceId": "space-usage-1",
                    "agentId": "agent-main",
                    "agentRole": "participant",
                    "status": "active",
                    "startedAt": "2026-03-07T09:55:00.000Z",
                    "lastActivityAt": "2026-03-07T10:00:00.000Z",
                    "turnCount": 2,
                    "inputTokens": 90,
                    "outputTokens": 20,
                    "totalTokens": 110,
                    "spentUsd": 0.0033,
                    "tokenAccuracy": "estimated",
                    "usageSource": "legacy_turns"
                }
            ],
            "globalLifetime": {
                "inputTokens": 240,
                "outputTokens": 60,
                "totalTokens": 300,
                "spentUsd": 0.0090,
                "tokenAccuracy": "mixed",
                "usageSource": "ledger"
            }
        }
        """

        let result = try JSONDecoder().decode(SpaceGetUsageResult.self, from: Data(usageJSON.utf8))
        XCTAssertEqual(result.spaceUsage.tokenAccuracy, "reported")
        XCTAssertEqual(result.spaceUsage.usageSource, "ledger")
        XCTAssertEqual(result.agentSessions?.first?.tokenAccuracy, "estimated")
        XCTAssertEqual(result.agentSessions?.first?.usageSource, "legacy_turns")
        XCTAssertEqual(result.globalLifetime?.tokenAccuracy, "mixed")
        XCTAssertEqual(result.globalLifetime?.usageSource, "ledger")
    }

    func testGatewayFactoryResetPayloadAndResponseDecoding() throws {
        let payload = GatewayFactoryResetPayload(
            apiVersion: "v1",
            confirmation: "DELETE resource:main"
        )
        let payloadJSON = try encodeJSONObject(payload)
        XCTAssertEqual(payloadJSON["apiVersion"] as? String, "v1")
        XCTAssertEqual(payloadJSON["confirmation"] as? String, "DELETE resource:main")

        let responseJSON = """
        {
            "gatewayId": "resource:main",
            "gatewayUuid": "11111111-2222-3333-4444-555555555555",
            "resetAt": "2026-02-27T00:00:00.000Z",
            "tablesCleared": 17,
            "rowsDeleted": 321
        }
        """
        let response = try JSONDecoder().decode(
            GatewayFactoryResetResponsePayload.self,
            from: Data(responseJSON.utf8)
        )
        XCTAssertEqual(response.gatewayId, "resource:main")
        XCTAssertEqual(response.gatewayUuid, "11111111-2222-3333-4444-555555555555")
        XCTAssertEqual(response.tablesCleared, 17)
        XCTAssertEqual(response.rowsDeleted, 321)

        let result = try JSONDecoder().decode(
            GatewayFactoryResetResult.self,
            from: Data(responseJSON.utf8)
        )
        XCTAssertEqual(result.gatewayId, "resource:main")
        XCTAssertEqual(result.rowsDeleted, 321)
    }

    func testSpaceResetPayloadAndResponseDecoding() throws {
        let payload = SpaceResetPayload(
            apiVersion: "v1",
            spaceId: "space-reset-target"
        )
        let payloadJSON = try encodeJSONObject(payload)
        XCTAssertEqual(payloadJSON["apiVersion"] as? String, "v1")
        XCTAssertEqual(payloadJSON["spaceId"] as? String, "space-reset-target")

        let responseJSON = """
        {
            "spaceId": "space-reset-target",
            "resetAt": "2026-03-02T22:00:00.000Z",
            "tablesCleared": 9,
            "rowsDeleted": 128
        }
        """
        let response = try JSONDecoder().decode(
            SpaceResetResponsePayload.self,
            from: Data(responseJSON.utf8)
        )
        XCTAssertEqual(response.spaceId, "space-reset-target")
        XCTAssertEqual(response.tablesCleared, 9)
        XCTAssertEqual(response.rowsDeleted, 128)

        let result = try JSONDecoder().decode(
            SpaceResetResult.self,
            from: Data(responseJSON.utf8)
        )
        XCTAssertEqual(result.spaceId, "space-reset-target")
        XCTAssertEqual(result.rowsDeleted, 128)
    }

    func testSpaceListActivityLogResultDecoding() throws {
        let decoded = try JSONDecoder().decode(
            SpaceListActivityLogResult.self,
            from: loadFixture("SpaceListActivityLogResult")
        )

        XCTAssertEqual(decoded.spaceId, "space-1")
        XCTAssertEqual(decoded.entries.count, 2)
        XCTAssertEqual(decoded.entries.first?.eventType, "turn.started")
        XCTAssertEqual(decoded.entries.last?.category, "memory")
        XCTAssertEqual(decoded.total, 2)
        XCTAssertEqual(decoded.nextOffset, 2)
    }

    func testTurnTraceDecodingDefaultsActivitiesWhenMissing() throws {
        let json = """
        {
          "trace": {
            "spaceId": "space-1",
            "turnId": "turn-1",
            "total": 1,
            "events": [
              {
                "eventId": "evt-1",
                "seq": 1,
                "eventType": "turn.completed",
                "createdAt": "2026-03-17T08:01:00.000Z",
                "payload": {}
              }
            ],
            "toolCalls": [],
            "artifactIds": []
          }
        }
        """
        let result = try JSONDecoder().decode(SpaceGetTurnTraceResult.self, from: Data(json.utf8))
        XCTAssertEqual(result.trace.turnId, "turn-1")
        XCTAssertEqual(result.trace.activities.count, 0)
    }

    func testMemoryLifecycleResultDecoding() throws {
        let experiences = try JSONDecoder().decode(
            SpaceListExperiencesResult.self,
            from: loadFixture("SpaceListExperiencesResult")
        )
        XCTAssertEqual(experiences.experiences.count, 1)
        XCTAssertEqual(experiences.experiences.first?.experienceId, "exp-1")

        let insights = try JSONDecoder().decode(
            SpaceListInsightsResult.self,
            from: loadFixture("SpaceListInsightsResult")
        )
        XCTAssertEqual(insights.insights.count, 1)
        XCTAssertEqual(insights.insights.first?.insightId, "insight-1")

        let profile = try JSONDecoder().decode(
            SpaceUserProfileResult.self,
            from: loadFixture("SpaceUserProfileResult")
        )
        XCTAssertEqual(profile.profile?.principalId, "principal:local")
        XCTAssertEqual(profile.profile?.facts.first, "prefers concise summaries")

        let memories = try JSONDecoder().decode(
            SpaceListMemoriesResult.self,
            from: loadFixture("SpaceListMemoriesResult")
        )
        XCTAssertEqual(memories.memories.count, 1)
        XCTAssertEqual(memories.memories.first?.memoryId, "mem-1")
    }

    func testExtractPayloadDataHandlesObjectPayload() throws {
        let envelope = """
        {
            "type": "gateway.factory_reset",
            "id": "msg-1",
            "replyTo": "req-1",
            "ts": "2026-03-02T10:00:00.000Z",
            "payload": {
                "gatewayId": "resource:main",
                "rowsDeleted": 42
            }
        }
        """

        let payloadData = try GatewayClient.extractPayloadData(from: Data(envelope.utf8))
        let payload = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any]
        XCTAssertEqual(payload?["gatewayId"] as? String, "resource:main")
        XCTAssertEqual(payload?["rowsDeleted"] as? Int, 42)
    }

    func testExtractPayloadDataHandlesScalarAndNullPayloads() throws {
        let boolEnvelope = """
        {
            "type": "pong",
            "id": "msg-bool",
            "replyTo": "req-bool",
            "ts": "2026-03-02T10:00:00.000Z",
            "payload": true
        }
        """
        let boolPayloadData = try GatewayClient.extractPayloadData(from: Data(boolEnvelope.utf8))
        XCTAssertTrue(try JSONDecoder().decode(Bool.self, from: boolPayloadData))

        let stringEnvelope = """
        {
            "type": "notification",
            "id": "msg-string",
            "replyTo": "req-string",
            "ts": "2026-03-02T10:00:00.000Z",
            "payload": "ok"
        }
        """
        let stringPayloadData = try GatewayClient.extractPayloadData(from: Data(stringEnvelope.utf8))
        XCTAssertEqual(try JSONDecoder().decode(String.self, from: stringPayloadData), "ok")

        let nullEnvelope = """
        {
            "type": "pong",
            "id": "msg-null",
            "replyTo": "req-null",
            "ts": "2026-03-02T10:00:00.000Z",
            "payload": null
        }
        """
        let nullPayloadData = try GatewayClient.extractPayloadData(from: Data(nullEnvelope.utf8))
        XCTAssertEqual(String(data: nullPayloadData, encoding: .utf8), "null")
    }

    func testSecretRefPayloadEncodingAndResponseDecoding() throws {
        let putPayload = GatewayPutSecretRefPayload(
            apiVersion: "v1",
            secretRef: "secretref-openai-primary",
            providerId: "openai",
            label: "OpenAI Primary",
            secret: "sk-test",
            backend: "gateway_encrypted"
        )
        let putJSON = try encodeJSONObject(putPayload)
        XCTAssertEqual(putJSON["apiVersion"] as? String, "v1")
        XCTAssertEqual(putJSON["secretRef"] as? String, "secretref-openai-primary")
        XCTAssertEqual(putJSON["providerId"] as? String, "openai")
        XCTAssertEqual(putJSON["backend"] as? String, "gateway_encrypted")

        let listPayload = GatewayListSecretRefsPayload(apiVersion: "v1", providerId: "openai")
        let listJSON = try encodeJSONObject(listPayload)
        XCTAssertEqual(listJSON["providerId"] as? String, "openai")

        let deletePayload = GatewayDeleteSecretRefPayload(apiVersion: "v1", secretRef: "secretref-openai-primary")
        let deleteJSON = try encodeJSONObject(deletePayload)
        XCTAssertEqual(deleteJSON["secretRef"] as? String, "secretref-openai-primary")

        let putResponseJSON = """
        {
            "secretRef": {
                "secretRef": "secretref-openai-primary",
                "providerId": "openai",
                "label": "OpenAI Primary",
                "backend": "gateway_encrypted",
                "createdAt": "2026-02-24T00:00:00.000Z",
                "updatedAt": "2026-02-24T00:00:00.000Z",
                "lastUsedAt": null
            },
            "created": false
        }
        """
        let putResponse = try JSONDecoder().decode(
            GatewayPutSecretRefResponsePayload.self,
            from: Data(putResponseJSON.utf8)
        )
        XCTAssertEqual(putResponse.secretRef.secretRef, "secretref-openai-primary")
        XCTAssertFalse(putResponse.created)

        let listResponseJSON = """
        {
            "secretRefs": [
                {
                    "secretRef": "secretref-openai-primary",
                    "providerId": "openai",
                    "label": "OpenAI Primary",
                    "backend": "gateway_encrypted",
                    "createdAt": "2026-02-24T00:00:00.000Z",
                    "updatedAt": "2026-02-24T00:00:00.000Z",
                    "lastUsedAt": null
                }
            ]
        }
        """
        let listResponse = try JSONDecoder().decode(
            GatewayListSecretRefsResponsePayload.self,
            from: Data(listResponseJSON.utf8)
        )
        XCTAssertEqual(listResponse.secretRefs.count, 1)
        XCTAssertEqual(listResponse.secretRefs[0].providerId, "openai")

        let deleteResponseJSON = """
        {
            "secretRef": "secretref-openai-primary",
            "deleted": true
        }
        """
        let deleteResponse = try JSONDecoder().decode(
            GatewayDeleteSecretRefResponsePayload.self,
            from: Data(deleteResponseJSON.utf8)
        )
        XCTAssertTrue(deleteResponse.deleted)
    }

    func testConnectorControlPlanePayloadEncodingAndResponseDecoding() throws {
        let familiesPayload = GatewayListConnectorFamiliesPayload(apiVersion: "v1")
        let familiesJSON = try encodeJSONObject(familiesPayload)
        XCTAssertEqual(familiesJSON["apiVersion"] as? String, "v1")

        let connectorsPayload = GatewayListConnectorsPayload(apiVersion: "v1", familyId: "apple-calendar-eventkit")
        let connectorsJSON = try encodeJSONObject(connectorsPayload)
        XCTAssertEqual(connectorsJSON["familyId"] as? String, "apple-calendar-eventkit")

        let upsertConnectorPayload = GatewayUpsertConnectorPayload(
            apiVersion: "v1",
            connectorId: "apple-calendar-eventkit:acct_hash:primary",
            familyId: "apple-calendar-eventkit",
            displayName: "Primary Calendar",
            accountFingerprint: "acct_hash",
            label: "primary",
            status: .active,
            metadata: ["region": "us-east-1"],
            secretRefs: [.init(key: "token", ref: "secretref-calendar-token")]
        )
        let upsertConnectorJSON = try encodeJSONObject(upsertConnectorPayload)
        XCTAssertEqual(upsertConnectorJSON["connectorId"] as? String, "apple-calendar-eventkit:acct_hash:primary")
        XCTAssertEqual(upsertConnectorJSON["familyId"] as? String, "apple-calendar-eventkit")
        XCTAssertEqual((upsertConnectorJSON["metadata"] as? [String: Any])?["region"] as? String, "us-east-1")

        let removeConnectorPayload = GatewayRemoveConnectorPayload(
            apiVersion: "v1",
            connectorId: "apple-calendar-eventkit:acct_hash:primary"
        )
        let removeConnectorJSON = try encodeJSONObject(removeConnectorPayload)
        XCTAssertEqual(removeConnectorJSON["connectorId"] as? String, "apple-calendar-eventkit:acct_hash:primary")

        let listBindingsPayload = GatewayListConnectorBindingsPayload(
            apiVersion: "v1",
            connectorId: "apple-calendar-eventkit:acct_hash:primary"
        )
        let listBindingsJSON = try encodeJSONObject(listBindingsPayload)
        XCTAssertEqual(listBindingsJSON["connectorId"] as? String, "apple-calendar-eventkit:acct_hash:primary")

        let upsertBindingPayload = GatewayUpsertConnectorBindingPayload(
            apiVersion: "v1",
            bindingId: "binding-primary",
            connectorId: "apple-calendar-eventkit:acct_hash:primary",
            bindingType: .inboundRoute,
            selector: ["intent": "calendar.create"],
            targetType: .mainOrchestrator,
            targetSpaceId: "main-space",
            allowedActions: [.notify, .sendMessage],
            capabilityTypes: ["calendar.event.create"],
            priority: 10,
            enabled: true
        )
        let upsertBindingJSON = try encodeJSONObject(upsertBindingPayload)
        XCTAssertEqual(upsertBindingJSON["bindingId"] as? String, "binding-primary")
        XCTAssertEqual(upsertBindingJSON["bindingType"] as? String, "inbound_route")
        XCTAssertEqual((upsertBindingJSON["selector"] as? [String: Any])?["intent"] as? String, "calendar.create")

        let removeBindingPayload = GatewayRemoveConnectorBindingPayload(apiVersion: "v1", bindingId: "binding-primary")
        let removeBindingJSON = try encodeJSONObject(removeBindingPayload)
        XCTAssertEqual(removeBindingJSON["bindingId"] as? String, "binding-primary")

        let getPolicyPayload = GatewayGetConnectorPolicyPayload(
            apiVersion: "v1",
            scopeType: .instance,
            scopeId: "apple-calendar-eventkit:acct_hash:primary"
        )
        let getPolicyJSON = try encodeJSONObject(getPolicyPayload)
        XCTAssertEqual(getPolicyJSON["scopeType"] as? String, "instance")

        let updatePolicyPayload = GatewayUpdateConnectorPolicyPayload(
            apiVersion: "v1",
            scopeType: .instance,
            scopeId: "apple-calendar-eventkit:acct_hash:primary",
            requestsPerMinute: 60,
            burst: 10,
            disabled: false,
            disableReason: nil,
            disabledUntil: nil,
            updatedBy: "test-suite"
        )
        let updatePolicyJSON = try encodeJSONObject(updatePolicyPayload)
        XCTAssertEqual(updatePolicyJSON["requestsPerMinute"] as? Int, 60)
        XCTAssertEqual(updatePolicyJSON["updatedBy"] as? String, "test-suite")

        let testConnectorPayload = GatewayTestConnectorPayload(
            apiVersion: "v1",
            connectorId: "apple-calendar-eventkit:acct_hash:primary"
        )
        let testConnectorJSON = try encodeJSONObject(testConnectorPayload)
        XCTAssertEqual(testConnectorJSON["connectorId"] as? String, "apple-calendar-eventkit:acct_hash:primary")

        let familiesResponseJSON = """
        {
            "families": [
                {
                    "familyId": "apple-calendar-eventkit",
                    "displayName": "Apple Calendar (EventKit)",
                    "kind": "capability",
                    "runtime": "adapter",
                    "trustClass": "embedded_safe",
                    "embeddedEnabled": true,
                    "capabilityTypes": ["calendar.event.create"],
                    "features": { "oauth": false },
                    "createdAt": "2026-02-24T00:00:00.000Z",
                    "updatedAt": "2026-02-24T00:00:00.000Z"
                }
            ]
        }
        """
        let familiesResponse = try JSONDecoder().decode(
            GatewayListConnectorFamiliesResponsePayload.self,
            from: Data(familiesResponseJSON.utf8)
        )
        XCTAssertEqual(familiesResponse.families[0].familyId, "apple-calendar-eventkit")

        let connectorsResponseJSON = """
        {
            "connectors": [
                {
                    "connectorId": "apple-calendar-eventkit:acct_hash:primary",
                    "familyId": "apple-calendar-eventkit",
                    "displayName": "Primary Calendar",
                    "accountFingerprintHash": "acct_hash",
                    "labelSlug": "primary",
                    "status": "active",
                    "metadata": { "region": "us-east-1" },
                    "createdAt": "2026-02-24T00:00:00.000Z",
                    "updatedAt": "2026-02-24T00:00:00.000Z"
                }
            ]
        }
        """
        let connectorsResponse = try JSONDecoder().decode(
            GatewayListConnectorsResponsePayload.self,
            from: Data(connectorsResponseJSON.utf8)
        )
        XCTAssertEqual(connectorsResponse.connectors[0].metadata["region"]?.value as? String, "us-east-1")

        let bindingsResponseJSON = """
        {
            "bindings": [
                {
                    "bindingId": "binding-primary",
                    "connectorId": "apple-calendar-eventkit:acct_hash:primary",
                    "bindingType": "inbound_route",
                    "selector": { "intent": "calendar.create" },
                    "targetType": "main_orchestrator",
                    "targetSpaceId": "main-space",
                    "allowedActions": ["notify"],
                    "capabilityTypes": ["calendar.event.create"],
                    "priority": 10,
                    "enabled": true,
                    "createdAt": "2026-02-24T00:00:00.000Z",
                    "updatedAt": "2026-02-24T00:00:00.000Z"
                }
            ]
        }
        """
        let bindingsResponse = try JSONDecoder().decode(
            GatewayListConnectorBindingsResponsePayload.self,
            from: Data(bindingsResponseJSON.utf8)
        )
        XCTAssertEqual(bindingsResponse.bindings[0].bindingType, .inboundRoute)

        let testResponseJSON = """
        {
            "ok": true,
            "reason": null,
            "connector": {
                "connectorId": "apple-calendar-eventkit:acct_hash:primary",
                "familyId": "apple-calendar-eventkit",
                "displayName": "Primary Calendar",
                "accountFingerprintHash": "acct_hash",
                "labelSlug": "primary",
                "status": "active",
                "metadata": {},
                "createdAt": "2026-02-24T00:00:00.000Z",
                "updatedAt": "2026-02-24T00:00:00.000Z"
            },
            "inboundRoute": {
                "route": "binding",
                "targetType": "main_orchestrator",
                "targetSpaceId": "main-space",
                "bindingId": "binding-primary",
                "matchedScore": 0.95
            },
            "policy": {
                "scopeType": "instance",
                "scopeId": "apple-calendar-eventkit:acct_hash:primary",
                "requestsPerMinute": 120,
                "burst": 40,
                "disabled": false,
                "disableReason": null,
                "disabledUntil": null,
                "updatedBy": "test-suite",
                "updatedAt": "2026-02-24T00:00:00.000Z"
            }
        }
        """
        let testResponse = try JSONDecoder().decode(
            GatewayTestConnectorResponsePayload.self,
            from: Data(testResponseJSON.utf8)
        )
        XCTAssertTrue(testResponse.ok)
        XCTAssertEqual(testResponse.inboundRoute?.route, .binding)
        XCTAssertEqual(testResponse.policy?.scopeType, .instance)
    }

    func testCapabilityGrantPayloadEncodingAndResponseDecoding() throws {
        let listPayload = GatewayListCapabilityGrantsPayload(
            apiVersion: "v1",
            principalId: "principal-1",
            deviceId: "device-1",
            includeRevoked: true,
            includeExpired: true
        )
        let listJSON = try encodeJSONObject(listPayload)
        XCTAssertEqual(listJSON["principalId"] as? String, "principal-1")
        XCTAssertEqual(listJSON["includeRevoked"] as? Bool, true)

        let grantPayload = GatewayGrantCapabilityPayload(
            apiVersion: "v1",
            principalId: "principal-1",
            deviceId: "device-1",
            capabilityId: "speech.execute",
            reason: "admin override",
            expiresAt: "2026-03-01T00:00:00.000Z"
        )
        let grantJSON = try encodeJSONObject(grantPayload)
        XCTAssertEqual(grantJSON["capabilityId"] as? String, "speech.execute")
        XCTAssertEqual(grantJSON["reason"] as? String, "admin override")

        let revokePayload = GatewayRevokeCapabilityPayload(
            apiVersion: "v1",
            principalId: "principal-1",
            deviceId: "device-1",
            capabilityId: "speech.execute",
            reason: "cleanup"
        )
        let revokeJSON = try encodeJSONObject(revokePayload)
        XCTAssertEqual(revokeJSON["capabilityId"] as? String, "speech.execute")
        XCTAssertEqual(revokeJSON["reason"] as? String, "cleanup")

        let grantResponseJSON = """
        {
            "grant": {
                "principalId": "principal-1",
                "deviceId": "device-1",
                "capabilityId": "speech.execute",
                "level": "execute",
                "source": "runtime",
                "reason": "admin override",
                "grantedBy": "admin",
                "grantedAt": "2026-02-24T00:00:00.000Z",
                "expiresAt": "2026-03-01T00:00:00.000Z",
                "revokedAt": null,
                "updatedAt": "2026-02-24T00:00:00.000Z"
            }
        }
        """
        let grantResponse = try JSONDecoder().decode(
            GatewayGrantCapabilityResponsePayload.self,
            from: Data(grantResponseJSON.utf8)
        )
        XCTAssertEqual(grantResponse.grant.level, .execute)

        let listResponseJSON = """
        {
            "grants": [
                {
                    "principalId": "principal-1",
                    "deviceId": "device-1",
                    "capabilityId": "speech.execute",
                    "level": "execute",
                    "source": "runtime",
                    "reason": "admin override",
                    "grantedBy": "admin",
                    "grantedAt": "2026-02-24T00:00:00.000Z",
                    "expiresAt": null,
                    "revokedAt": null,
                    "updatedAt": "2026-02-24T00:00:00.000Z"
                }
            ]
        }
        """
        let listResponse = try JSONDecoder().decode(
            GatewayListCapabilityGrantsResponsePayload.self,
            from: Data(listResponseJSON.utf8)
        )
        XCTAssertEqual(listResponse.grants.count, 1)
        XCTAssertEqual(listResponse.grants[0].capabilityId, "speech.execute")

        let revokeResponseJSON = """
        {
            "revoked": true,
            "capabilityId": "speech.execute",
            "principalId": "principal-1",
            "deviceId": "device-1",
            "grant": {
                "principalId": "principal-1",
                "deviceId": "device-1",
                "capabilityId": "speech.execute",
                "level": "execute",
                "source": "runtime",
                "reason": "admin override",
                "grantedBy": "admin",
                "grantedAt": "2026-02-24T00:00:00.000Z",
                "expiresAt": null,
                "revokedAt": "2026-02-24T00:10:00.000Z",
                "updatedAt": "2026-02-24T00:10:00.000Z"
            }
        }
        """
        let revokeResponse = try JSONDecoder().decode(
            GatewayRevokeCapabilityResponsePayload.self,
            from: Data(revokeResponseJSON.utf8)
        )
        XCTAssertTrue(revokeResponse.revoked)
        XCTAssertEqual(revokeResponse.grant?.revokedAt, "2026-02-24T00:10:00.000Z")
    }

    func testMainAgentPayloadEncodingAndResponseDecoding() throws {
        let getPayload = GatewayGetMainAgentPayload(
            apiVersion: "v1",
            spaceId: "main-space",
            repairIfMissing: true
        )
        let getJSON = try encodeJSONObject(getPayload)
        XCTAssertEqual(getJSON["apiVersion"] as? String, "v1")
        XCTAssertEqual(getJSON["spaceId"] as? String, "main-space")
        XCTAssertEqual(getJSON["repairIfMissing"] as? Bool, true)

        let setPayload = GatewaySetMainAgentPayload(
            apiVersion: "v1",
            spaceId: "main-space",
            selectionMode: .providerModel,
            providerId: "openai",
            modelId: "gpt-4.1",
            sourceAgentDefinitionId: nil,
            applyPersonaInstructions: nil
        )
        let setJSON = try encodeJSONObject(setPayload)
        XCTAssertEqual(setJSON["selectionMode"] as? String, "provider_model")
        XCTAssertEqual(setJSON["providerId"] as? String, "openai")
        XCTAssertEqual(setJSON["modelId"] as? String, "gpt-4.1")

        let responseJSON = """
        {
            "state": {
                "spaceId": "main-space",
                "spaceUid": "11111111-2222-3333-4444-555555555555",
                "mainAgentId": "main-agent",
                "mainAgentDefinitionId": "main-agent-definition",
                "mainProfileId": "main-profile",
                "assignedAgentDefinitionId": "main-agent-definition",
                "assignedProfileId": "main-profile",
                "providerHint": "openai",
                "modelHint": "openai/gpt-4.1",
                "status": "degraded",
                "repaired": false,
                "fallbackApplied": false,
                "runtimeIssueReason": "Configured provider unavailable: missing-provider",
                "updatedAt": "2026-03-02T12:00:00.000Z"
            }
        }
        """
        let decoded = try JSONDecoder().decode(
            GatewayGetMainAgentResponsePayload.self,
            from: Data(responseJSON.utf8)
        )
        XCTAssertEqual(decoded.state.mainAgentId, "main-agent")
        XCTAssertEqual(decoded.state.mainAgentDefinitionId, "main-agent-definition")
        XCTAssertEqual(decoded.state.assignedAgentDefinitionId, "main-agent-definition")
        XCTAssertEqual(decoded.state.status, .degraded)
        XCTAssertEqual(decoded.state.fallbackApplied, false)
        XCTAssertEqual(decoded.state.runtimeIssueReason, "Configured provider unavailable: missing-provider")
    }

    func testConciergeAgentPayloadEncodingAndResponseDecoding() throws {
        let getPayload = GatewayGetConciergeAgentPayload(
            apiVersion: "v1",
            spaceId: "concierge-space",
            repairIfMissing: true
        )
        let getJSON = try encodeJSONObject(getPayload)
        XCTAssertEqual(getJSON["apiVersion"] as? String, "v1")
        XCTAssertEqual(getJSON["spaceId"] as? String, "concierge-space")
        XCTAssertEqual(getJSON["repairIfMissing"] as? Bool, true)

        let setPayload = GatewaySetConciergeAgentPayload(
            apiVersion: "v1",
            spaceId: "concierge-space",
            selectionMode: .providerModel,
            providerId: "openai",
            modelId: "gpt-4.1",
            sourceAgentDefinitionId: nil,
            applyPersonaInstructions: nil
        )
        let setJSON = try encodeJSONObject(setPayload)
        XCTAssertEqual(setJSON["selectionMode"] as? String, "provider_model")
        XCTAssertEqual(setJSON["providerId"] as? String, "openai")
        XCTAssertEqual(setJSON["modelId"] as? String, "gpt-4.1")

        let responseJSON = """
        {
            "state": {
                "spaceId": "concierge-space",
                "spaceUid": "aaaa1111-2222-3333-4444-555555555555",
                "conciergeAgentId": "concierge-agent",
                "conciergeAgentDefinitionId": "concierge-profile",
                "conciergeProfileId": "concierge-profile",
                "assignedAgentDefinitionId": "concierge-profile",
                "assignedProfileId": "concierge-profile",
                "providerHint": "openai",
                "modelHint": "openai/gpt-4.1",
                "status": "fallback",
                "repaired": true,
                "fallbackApplied": true,
                "fallbackReason": "Configured provider unavailable: missing-provider",
                "runtimeIssueReason": "Configured provider unavailable: missing-provider",
                "updatedAt": "2026-03-29T12:00:00.000Z"
            }
        }
        """
        let decoded = try JSONDecoder().decode(
            GatewayGetConciergeAgentResponsePayload.self,
            from: Data(responseJSON.utf8)
        )
        XCTAssertEqual(decoded.state.conciergeAgentId, "concierge-agent")
        XCTAssertEqual(decoded.state.conciergeAgentDefinitionId, "concierge-profile")
        XCTAssertEqual(decoded.state.assignedAgentDefinitionId, "concierge-profile")
        XCTAssertEqual(decoded.state.status, .fallback)
        XCTAssertTrue(decoded.state.fallbackApplied)
        XCTAssertEqual(decoded.state.runtimeIssueReason, "Configured provider unavailable: missing-provider")
    }

    func testAssignmentAndTemplateAliasesRoundTrip() throws {
        let assignmentJSON = """
        {
            "spaceId": "space-1",
            "agentId": "agent-1",
            "agentDefinitionId": "agent-definition-1",
            "role": "participant",
            "turnOrder": 1,
            "isPrimary": true,
            "assignedAt": "2026-03-07T12:00:00.000Z"
        }
        """
        let decodedAssignment = try JSONDecoder().decode(
            SpaceAgentAssignment.self,
            from: Data(assignmentJSON.utf8)
        )
        XCTAssertEqual(decodedAssignment.agentDefinitionId, "agent-definition-1")
        XCTAssertEqual(decodedAssignment.profileId, "agent-definition-1")

        let templateAgent = TemplateAgentDefinition(
            agentId: "agent-1",
            agentDefinitionId: "agent-definition-1",
            role: .participant,
            turnOrder: 1,
            isPrimary: true
        )
        let templateJSON = try encodeJSONObject(templateAgent)
        XCTAssertEqual(templateJSON["agentDefinitionId"] as? String, "agent-definition-1")
        XCTAssertEqual(templateJSON["profileId"] as? String, "agent-definition-1")

        let updatePayload = SpaceUpdateAgentAssignmentPayload(
            apiVersion: "v1",
            idempotencyKey: "idem-1",
            spaceId: "space-1",
            agentId: "agent-1",
            agentDefinitionId: "agent-definition-1",
            profileId: nil,
            role: "participant",
            turnOrder: 1,
            isPrimary: true,
            resetSession: true
        )
        let updateJSON = try encodeJSONObject(updatePayload)
        XCTAssertEqual(updateJSON["agentDefinitionId"] as? String, "agent-definition-1")
        XCTAssertEqual(updateJSON["profileId"] as? String, "agent-definition-1")
    }

    func testSpaceConfigDecodesOrchestratorAgentDefinitionAlias() throws {
        let json = """
        {
            "id": "space-1",
            "spaceUid": "space-uid-1",
            "resourceId": "resource:space-1",
            "name": "Space One",
            "orchestratorAgentDefinitionId": "agent-definition-1",
            "turnModel": "primary_only",
            "agents": [],
            "capabilities": [],
            "capabilityOverrides": {},
            "visibility": "shared",
            "createdAt": "2026-03-07T12:00:00.000Z",
            "updatedAt": "2026-03-07T12:05:00.000Z"
        }
        """

        let decoded = try JSONDecoder().decode(SpaceConfig.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.orchestratorAgentDefinitionId, "agent-definition-1")
        XCTAssertEqual(decoded.orchestratorProfileId, "agent-definition-1")
    }

    func testHardCutIdentityLibraryAndTemplatePayloads() throws {
        let createAgentDefinitionPayload = IdentityCreateAgentDefinitionPayload(
            apiVersion: "v1",
            idempotencyKey: "idem-1",
            agentDefinitionId: "agent-definition-1",
            personaId: "persona-1",
            name: "Builder",
            description: "Build things",
            instructions: "Be precise.",
            defaultSkillIds: ["skill-1"],
            providerHint: "openai",
            modelHint: "gpt-4.1",
            modelConfig: ProfileModelConfig(preferredModels: ["gpt-4.1"]),
            isDefault: true
        )
        let agentDefinitionJSON = try encodeJSONObject(createAgentDefinitionPayload)
        XCTAssertEqual(agentDefinitionJSON["agentDefinitionId"] as? String, "agent-definition-1")
        XCTAssertEqual(agentDefinitionJSON["personaId"] as? String, "persona-1")

        let saveSkillPayload = LibrarySaveSkillPayload(
            apiVersion: "v1",
            idempotencyKey: "idem-2",
            entryId: "entry-1",
            skillId: "skill-1",
            name: "Formatter",
            description: "Format output",
            contentMarkdown: "# Formatter",
            tags: ["formatting"],
            sourceKind: .installed,
            sourceRef: "local",
            enabled: true
        )
        let saveSkillJSON = try encodeJSONObject(saveSkillPayload)
        XCTAssertEqual(saveSkillJSON["entryId"] as? String, "entry-1")
        XCTAssertEqual(saveSkillJSON["sourceKind"] as? String, "installed")
        XCTAssertEqual(saveSkillJSON["enabled"] as? Bool, true)

        let templatePayload = SpaceTemplateSavePayload(
            apiVersion: "v1",
            idempotencyKey: "idem-3",
            templateId: "template-1",
            name: "Research Team",
            description: "Managed template",
            communicationMode: CommunicationMode.chatFirst.rawValue,
            baseAgents: [
                TemplateAgentDefinition(
                    agentId: "agent-1",
                    agentDefinitionId: "agent-definition-1",
                    role: .participant,
                    turnOrder: 1,
                    isPrimary: true
                )
            ],
            sourceSpaceId: "space-1"
        )
        let templatePayloadJSON = try encodeJSONObject(templatePayload)
        XCTAssertEqual(templatePayloadJSON["name"] as? String, "Research Team")
        let baseAgents = templatePayloadJSON["baseAgents"] as? [[String: Any]]
        XCTAssertEqual(baseAgents?.first?["agentDefinitionId"] as? String, "agent-definition-1")
        XCTAssertEqual(baseAgents?.first?["profileId"] as? String, "agent-definition-1")

        let previewResponseJSON = """
        {
            "preview": {
                "agentDefinitionId": "agent-definition-1",
                "personaId": "persona-1",
                "sections": [
                    {
                        "key": "agent_definition",
                        "title": "Agent Definition",
                        "content": "Be precise."
                    }
                ],
                "compiledText": "Be precise.",
                "generatedAt": "2026-03-07T12:10:00.000Z"
            }
        }
        """
        let preview = try JSONDecoder().decode(
            IdentityPreviewCompiledInstructionsResponsePayload.self,
            from: Data(previewResponseJSON.utf8)
        )
        XCTAssertEqual(preview.preview.sections.first?.key, .agentDefinition)

        let matrixResponseJSON = """
        {
            "matrix": {
                "agentDefinitionId": "agent-definition-1",
                "personaId": "persona-1",
                "generatedAt": "2026-03-14T10:20:00.000Z",
                "variants": [
                    {
                        "budgetClass": "full",
                        "label": "Cloud",
                        "tokenEstimate": 321,
                        "sections": [
                            {
                                "key": "conversation_prompt",
                                "title": "Conversation Prompt",
                                "content": "Keep responses concise."
                            },
                            {
                                "key": "assignment_context",
                                "title": "Assignment Context",
                                "content": "Focus on synthesis."
                            }
                        ],
                        "compiledText": "Keep responses concise. Focus on synthesis."
                    }
                ]
            }
        }
        """
        let matrixResponse = try JSONDecoder().decode(
            IdentityPreviewSystemPromptMatrixResponsePayload.self,
            from: Data(matrixResponseJSON.utf8)
        )
        XCTAssertEqual(matrixResponse.matrix.variants.first?.sections.first?.key, .conversationPrompt)
        XCTAssertEqual(matrixResponse.matrix.variants.first?.sections.last?.key, .assignmentContext)

        let libraryResponseJSON = """
        {
            "entries": [
                {
                    "entryId": "entry-1",
                    "skillId": "skill-1",
                    "name": "Formatter",
                    "description": "Format output",
                    "contentMarkdown": "# Formatter",
                    "sourceKind": "installed",
                    "sourceRef": "local",
                    "provenance": {"publisher": "OpenAI"},
                    "tags": ["formatting"],
                    "status": "enabled",
                    "importable": false,
                    "importedSkillId": "skill-1",
                    "createdAt": "2026-03-07T12:00:00.000Z",
                    "updatedAt": "2026-03-07T12:05:00.000Z"
                }
            ]
        }
        """
        let libraryResponse = try JSONDecoder().decode(
            LibraryListEntriesResponsePayload.self,
            from: Data(libraryResponseJSON.utf8)
        )
        XCTAssertEqual(libraryResponse.entries.first?.sourceKind, .installed)
        XCTAssertEqual(libraryResponse.entries.first?.status, .enabled)

        let managedTemplateResponseJSON = """
        {
            "template": {
                "templateId": "template-1",
                "name": "Research Team",
                "description": "Managed template",
                "status": "active",
                "activeRevision": 2,
                "communicationMode": "chat_first",
                "turnModel": "sequential_all",
                "agentDefinitions": [
                    {
                        "agentId": "agent-1",
                        "agentDefinitionId": "agent-definition-1",
                        "role": "participant",
                        "turnOrder": 1,
                        "isPrimary": true
                    }
                ],
                "createdBy": "principal-1",
                "createdAt": "2026-03-07T12:00:00.000Z",
                "updatedAt": "2026-03-07T12:05:00.000Z"
            },
            "resolved": {
                "templateId": "template-1",
                "templateRevision": 2,
                "name": "Research Team",
                "resourceId": "resource:space-1",
                "communicationMode": "chat_first",
                "turnModel": "sequential_all",
                "initialAgents": [
                    {
                        "agentId": "agent-1",
                        "agentDefinitionId": "agent-definition-1",
                        "role": "participant",
                        "turnOrder": 1,
                        "isPrimary": true
                    }
                ]
            },
            "warnings": []
        }
        """
        let managedTemplateResponse = try JSONDecoder().decode(
            SpaceTemplatePreviewResponsePayload.self,
            from: Data(managedTemplateResponseJSON.utf8)
        )
        XCTAssertEqual(managedTemplateResponse.template.name, "Research Team")
        XCTAssertEqual(managedTemplateResponse.template.agentDefinitions.first?.agentDefinitionId, "agent-definition-1")
    }

    func testAdminFixturesRemainLoadable() throws {
        let fixtureNames = [
            "GatewayGetMainAgentPayload",
            "GatewaySetMainAgentPayload",
            "GatewayGetMainAgentResponsePayload",
            "GatewaySetMainAgentResponsePayload",
            "GatewayGetConciergeAgentPayload",
            "GatewaySetConciergeAgentPayload",
            "GatewayGetConciergeAgentResponsePayload",
            "GatewaySetConciergeAgentResponsePayload",
            "GatewayListAvailableModelsPayload",
            "GatewayListAvailableModelsResponsePayload",
            "GatewayFactoryResetPayload",
            "GatewayFactoryResetResponsePayload",
            "SpaceResetPayload",
            "SpaceResetResponsePayload",
            "GatewayPutSecretRefPayload",
            "GatewayPutSecretRefResponsePayload",
            "GatewayListSecretRefsPayload",
            "GatewayListSecretRefsResponsePayload",
            "GatewayDeleteSecretRefPayload",
            "GatewayDeleteSecretRefResponsePayload",
            "GatewayListConnectorFamiliesPayload",
            "GatewayListConnectorFamiliesResponsePayload",
            "GatewayListConnectorsPayload",
            "GatewayListConnectorsResponsePayload",
            "GatewayUpsertConnectorPayload",
            "GatewayUpsertConnectorResponsePayload",
            "GatewayRemoveConnectorPayload",
            "GatewayRemoveConnectorResponsePayload",
            "GatewayListConnectorBindingsPayload",
            "GatewayListConnectorBindingsResponsePayload",
            "GatewayUpsertConnectorBindingPayload",
            "GatewayUpsertConnectorBindingResponsePayload",
            "GatewayRemoveConnectorBindingPayload",
            "GatewayRemoveConnectorBindingResponsePayload",
            "GatewayGetConnectorPolicyPayload",
            "GatewayGetConnectorPolicyResponsePayload",
            "GatewayUpdateConnectorPolicyPayload",
            "GatewayUpdateConnectorPolicyResponsePayload",
            "GatewayTestConnectorPayload",
            "GatewayTestConnectorResponsePayload",
            "GatewayListCapabilityGrantsPayload",
            "GatewayListCapabilityGrantsResponsePayload",
            "GatewayGrantCapabilityPayload",
            "GatewayGrantCapabilityResponsePayload",
            "GatewayRevokeCapabilityPayload",
            "GatewayRevokeCapabilityResponsePayload",
            "GatewayGetWorkspaceDefaultsPayload",
            "GatewayGetWorkspaceDefaultsResponsePayload",
            "GatewaySetWorkspaceDefaultsPayload",
            "GatewaySetWorkspaceDefaultsResponsePayload",
            "GatewayGetMemoryDefaultsPayload",
            "GatewayGetMemoryDefaultsResponsePayload",
            "GatewaySetMemoryDefaultsPayload",
            "GatewaySetMemoryDefaultsResponsePayload",
            "GatewayGetExternalConnectivityPayload",
            "GatewayGetExternalConnectivityResponsePayload",
            "GatewaySetExternalConnectivityPayload",
            "GatewaySetExternalConnectivityResponsePayload",
            "SpaceGetMemoryPolicyPayload",
            "SpaceGetMemoryPolicyResponsePayload",
            "SpaceSetMemoryPolicyPayload",
            "SpaceSetMemoryPolicyResponsePayload",
            "SpaceEndIncognitoSessionPayload",
            "SpaceEndIncognitoSessionResponsePayload",
            "SpaceListActivityLogPayload",
            "SpaceListActivityLogResult",
            "SpaceListExperiencesPayload",
            "SpaceListExperiencesResult",
            "SpaceListInsightsPayload",
            "SpaceListInsightsResult",
            "SpaceGetUserProfilePayload",
            "SpaceUserProfileResult",
            "SpaceListMemoriesPayload",
            "SpaceListMemoriesResult",
        ]

        for name in fixtureNames {
            let data = try loadFixture(name)
            XCTAssertNoThrow(
                try JSONSerialization.jsonObject(with: data),
                "Fixture \(name).json should be valid JSON"
            )
        }
    }

    func testSpaceCreatePayloadEncodesWorkspaceRoot() throws {
        let payload = SpaceCreatePayload(
            apiVersion: "v1",
            idempotencyKey: "idem-1",
            spaceId: "space-1",
            workspaceRoot: "/tmp/spaces/space-1",
            resourceId: "resource:space-1",
            spaceType: nil,
            name: "Workspace Space",
            goal: "Workspace root test"
        )

        let json = try encodeJSONObject(payload)
        XCTAssertEqual(json["workspaceRoot"] as? String, "/tmp/spaces/space-1")
    }

    func testSpaceWorkspaceDecoding() throws {
        let decoded = try JSONDecoder().decode(SpaceWorkspace.self, from: loadFixture("SpaceWorkspacePayload"))
        XCTAssertEqual(decoded.spaceId, "space-1")
        XCTAssertEqual(decoded.mode, "folder_bound")
        XCTAssertEqual(decoded.explicitWorkspaceRoot, "/tmp/spaces/space-1")
        XCTAssertEqual(decoded.sharedContextPath, "/tmp/spaces/space-1/.space/shared-context")
        XCTAssertEqual(decoded.scratchpadsPath, "/tmp/spaces/space-1/.space/scratchpads")
        XCTAssertEqual(decoded.artifactsPath, "/tmp/spaces/space-1/.space/artifacts")
        XCTAssertEqual(decoded.metaPath, "/tmp/spaces/space-1/.space")
        XCTAssertEqual(decoded.layoutVersion, 3)
        XCTAssertEqual(decoded.metadataStatus, .ready)
    }

    func testSpaceWorkspaceDecodingFallsBackForLegacyPartialPayload() throws {
        let json = """
        {
            "spaceId": "space-legacy",
            "mode": "managed",
            "effectiveWorkspaceRoot": "/tmp/spaces/space-legacy",
            "metaPath": "/tmp/spaces/space-legacy/.space",
            "logsPath": "/tmp/spaces/space-legacy/.space/logs",
            "workPath": "/tmp/spaces/space-legacy/.space/work",
            "scratchpadsPath": "/tmp/spaces/space-legacy/.space/scratchpads"
        }
        """

        let decoded = try JSONDecoder().decode(SpaceWorkspace.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.spaceId, "space-legacy")
        XCTAssertEqual(decoded.spaceUid, "space-legacy")
        XCTAssertEqual(decoded.sharedContextPath, "/tmp/spaces/space-legacy/.space/shared-context")
        XCTAssertEqual(decoded.scratchpadsPath, "/tmp/spaces/space-legacy/.space/scratchpads")
        XCTAssertEqual(decoded.artifactsPath, "/tmp/spaces/space-legacy/.space/artifacts")
        XCTAssertEqual(decoded.layoutVersion, 2)
        XCTAssertEqual(decoded.metadataStatus, .unknown)
    }

    func testSpaceConfigDecodingIncludesWorkspace() throws {
        let json = """
        {
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
                "artifactsPath": "/tmp/spaces/space-uid-1/.space/artifacts",
                "layoutVersion": 3,
                "gitRepoDetected": false,
                "metadataStatus": "ready",
                "updatedAt": "2026-02-28T09:05:00.000Z"
            },
            "resourceId": "resource:space-1",
            "name": "Space One",
            "turnModel": "primary_only",
            "agents": [],
            "capabilities": [],
            "capabilityOverrides": {},
            "visibility": "shared",
            "createdAt": "2026-02-28T09:00:00.000Z",
            "updatedAt": "2026-02-28T09:05:00.000Z"
        }
        """

        let decoded = try JSONDecoder().decode(SpaceConfig.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.id, "space-1")
        XCTAssertEqual(decoded.workspace?.mode, "managed")
        XCTAssertEqual(decoded.workspace?.effectiveWorkspaceRoot, "/tmp/spaces/space-uid-1")
        XCTAssertEqual(decoded.workspace?.artifactsPath, "/tmp/spaces/space-uid-1/.space/artifacts")
        XCTAssertEqual(decoded.workspace?.metadataStatus, .ready)
    }

    func testSpaceOpenWorkspacePayloadEncodesWorkspaceRoot() throws {
        let payload = SpaceOpenWorkspacePayload(apiVersion: "v1", workspaceRoot: "/tmp/repo")
        let json = try encodeJSONObject(payload)
        XCTAssertEqual(json["workspaceRoot"] as? String, "/tmp/repo")
    }

    func testGatewayWorkspaceDefaultsPayloadEncodesOptionalRoot() throws {
        let payload = GatewaySetWorkspaceDefaultsPayload(apiVersion: "v1", spaceHomeRoot: "/tmp/spaces-home")
        let json = try encodeJSONObject(payload)
        XCTAssertEqual(json["spaceHomeRoot"] as? String, "/tmp/spaces-home")
    }

    func testSpaceMemoryPolicyPayloadEncodingAndResponseDecoding() throws {
        let payload = SpaceSetMemoryPolicyPayload(
            apiVersion: "v1",
            idempotencyKey: "idem-memory-policy",
            spaceId: "space-1",
            memoryPolicy: SpaceMemoryPolicy(
                experienceCapture: .disabled,
                privacyMode: .incognitoSession
            )
        )
        let json = try encodeJSONObject(payload)
        XCTAssertEqual(json["spaceId"] as? String, "space-1")
        XCTAssertEqual(json["idempotencyKey"] as? String, "idem-memory-policy")
        let memoryPolicy = json["memoryPolicy"] as? [String: Any]
        XCTAssertEqual(memoryPolicy?["experienceCapture"] as? String, "DISABLED")
        XCTAssertEqual(memoryPolicy?["privacyMode"] as? String, "INCOGNITO_SESSION")

        let getResponse = try JSONDecoder().decode(
            SpaceGetMemoryPolicyResponsePayload.self,
            from: loadFixture("SpaceGetMemoryPolicyResponsePayload")
        )
        XCTAssertEqual(getResponse.spaceId, "sample-spaceId")
        XCTAssertEqual(getResponse.memoryPolicy.experienceCapture, .inherit)
        XCTAssertEqual(getResponse.memoryPolicy.privacyMode, .standard)

        let spaceResponseJSON = """
        {
            "space": {
                "id": "space-1",
                "spaceUid": "space-uid-1",
                "resourceId": "resource:space-1",
                "name": "Incognito Space",
                "turnModel": "primary_only",
                "agents": [],
                "capabilities": [],
                "capabilityOverrides": {},
                "visibility": "shared",
                "thinkingCapturePolicy": "OFF",
                "memoryPolicy": {
                    "experienceCapture": "INHERIT",
                    "privacyMode": "STANDARD"
                },
                "createdAt": "2026-03-11T10:00:00.000Z",
                "updatedAt": "2026-03-11T10:05:00.000Z"
            }
        }
        """

        let setResponse = try JSONDecoder().decode(
            SpaceSetMemoryPolicyResponsePayload.self,
            from: Data(spaceResponseJSON.utf8)
        )
        XCTAssertEqual(setResponse.space.memoryPolicy.experienceCapture, .inherit)
        XCTAssertEqual(setResponse.space.memoryPolicy.privacyMode, .standard)

        let endResponseJSON = """
        {
            "space": {
                "id": "space-1",
                "spaceUid": "space-uid-1",
                "resourceId": "resource:space-1",
                "name": "Incognito Space",
                "turnModel": "primary_only",
                "agents": [],
                "capabilities": [],
                "capabilityOverrides": {},
                "visibility": "shared",
                "thinkingCapturePolicy": "OFF",
                "memoryPolicy": {
                    "experienceCapture": "INHERIT",
                    "privacyMode": "STANDARD"
                },
                "createdAt": "2026-03-11T10:00:00.000Z",
                "updatedAt": "2026-03-11T10:05:00.000Z"
            },
            "ended": true,
            "reason": "manual",
            "purgedAt": "2026-03-11T10:06:00.000Z",
            "sessionId": "sample-sessionId"
        }
        """

        let endResponse = try JSONDecoder().decode(
            SpaceEndIncognitoSessionResponsePayload.self,
            from: Data(endResponseJSON.utf8)
        )
        XCTAssertTrue(endResponse.ended)
        XCTAssertEqual(endResponse.reason, "manual")
        XCTAssertEqual(endResponse.sessionId, "sample-sessionId")
    }

    func testGatewayMemoryDefaultsPayloadEncodingAndResponseDecoding() throws {
        let payload = GatewaySetMemoryDefaultsPayload(
            apiVersion: "v1",
            defaultExperienceCapture: .enabled,
            defaultSpacePrivacyMode: .standard
        )
        let json = try encodeJSONObject(payload)
        XCTAssertEqual(json["apiVersion"] as? String, "v1")
        XCTAssertEqual(json["defaultExperienceCapture"] as? String, "ENABLED")
        XCTAssertEqual(json["defaultSpacePrivacyMode"] as? String, "STANDARD")

        let responseJSON = """
        {
            "defaults": {
                "defaultExperienceCapture": "DISABLED",
                "defaultSpacePrivacyMode": "STANDARD",
                "updatedAt": "2026-03-11T10:00:00.000Z"
            }
        }
        """

        let getResponse = try JSONDecoder().decode(
            GatewayGetMemoryDefaultsResponsePayload.self,
            from: Data(responseJSON.utf8)
        )
        XCTAssertEqual(getResponse.defaults.defaultExperienceCapture, .disabled)
        XCTAssertEqual(getResponse.defaults.defaultSpacePrivacyMode, .standard)
        XCTAssertEqual(getResponse.defaults.updatedAt, "2026-03-11T10:00:00.000Z")

        let setResponse = try JSONDecoder().decode(
            GatewaySetMemoryDefaultsResponsePayload.self,
            from: Data(responseJSON.utf8)
        )
        XCTAssertEqual(setResponse.defaults.defaultExperienceCapture, .disabled)
        XCTAssertEqual(setResponse.defaults.defaultSpacePrivacyMode, .standard)
    }

    func testGatewayExternalConnectivityPayloadEncodesMode() throws {
        let payload = GatewaySetExternalConnectivityPayload(apiVersion: "v1", mode: "TAILSCALE")
        let json = try encodeJSONObject(payload)
        XCTAssertEqual(json["mode"] as? String, "TAILSCALE")
    }

    func testSpaceOpenWorkspaceResponseDecoding() throws {
        let decoded = try JSONDecoder().decode(
            SpaceOpenWorkspaceResponsePayload.self,
            from: loadFixture("SpaceOpenWorkspaceResponsePayload")
        )
        XCTAssertEqual(decoded.result.status, .openedExisting)
        XCTAssertFalse(decoded.result.workspaceRoot.isEmpty)
    }

    func testAdapterPayloadEncoding() throws {
        let provider = AdapterCapabilityProvider(
            id: "apple-reminders-eventkit",
            name: "Apple Reminders (EventKit)",
            capabilityType: "lists",
            operations: ["listLists", "createList", "updateList", "deleteList", "listItems", "createItem", "updateItem", "completeItem", "deleteItem"]
        )

        let registerPayload = CapabilitiesRegisterPayload(providers: [provider])
        let registerJSON = try encodeJSONObject(registerPayload)
        let providersJSON = registerJSON["providers"] as? [[String: Any]]
        XCTAssertEqual(providersJSON?.count, 1)
        XCTAssertEqual(providersJSON?.first?["id"] as? String, "apple-reminders-eventkit")
        XCTAssertEqual(providersJSON?.first?["source"] as? String, "adapter")

        let deregisterPayload = CapabilitiesDeregisterPayload(providerIds: ["apple-reminders-eventkit"])
        let deregisterJSON = try encodeJSONObject(deregisterPayload)
        XCTAssertEqual(deregisterJSON["providerIds"] as? [String], ["apple-reminders-eventkit"])

        let resultPayload = CapabilityResultPayload(
            invocationId: "invoke-1",
            providerId: "apple-reminders-eventkit",
            data: ["ok": true],
            durationMs: 12.5
        )
        let resultJSON = try encodeJSONObject(resultPayload)
        XCTAssertEqual(resultJSON["invocationId"] as? String, "invoke-1")
        XCTAssertEqual((resultJSON["data"] as? [String: Any])?["ok"] as? Bool, true)

        let errorPayload = CapabilityErrorPayload(
            invocationId: "invoke-2",
            providerId: "apple-reminders-eventkit",
            code: "INVALID_ARGUMENT",
            message: "title is required",
            details: ["field": "title"]
        )
        let errorJSON = try encodeJSONObject(errorPayload)
        XCTAssertEqual(errorJSON["code"] as? String, "INVALID_ARGUMENT")
        XCTAssertEqual((errorJSON["details"] as? [String: Any])?["field"] as? String, "title")
    }

    func testDecodeCapabilityInvokeEnvelope() throws {
        let payloadData = try loadFixture("AdapterCapabilityInvokePayload")
        let payloadJSON = try JSONSerialization.jsonObject(with: payloadData) as! [String: Any]

        let envelopeJSON: [String: Any] = [
            "type": MessageType.capabilityInvokeAdapter,
            "id": "msg-1",
            "ts": "2026-03-02T10:00:00.000Z",
            "payload": payloadJSON,
        ]
        let envelopeData = try JSONSerialization.data(withJSONObject: envelopeJSON)
        let envelope = try JSONDecoder().decode(
            GatewayMessage<AdapterCapabilityInvokePayload>.self,
            from: envelopeData
        )

        XCTAssertEqual(envelope.type, MessageType.capabilityInvokeAdapter)
        XCTAssertEqual(envelope.payload.invocationId, "sample-invocationId")
        XCTAssertEqual(envelope.payload.capability, "sample-capability")
        XCTAssertEqual(envelope.payload.operation, "sample-operation")
        XCTAssertEqual(envelope.payload.args["key1"]?.value as? String, "value1")
    }

    func testGatewayEventCapabilityInvokeCase() throws {
        let payload = AdapterCapabilityInvokePayload(
            invocationId: "inv-1",
            capability: "lists",
            operation: "createItem",
            args: ["title": AnyCodable("Buy milk")],
            targetProvider: "apple-reminders-eventkit"
        )

        let event = GatewayEvent.capabilityInvoke(payload)
        guard case .capabilityInvoke(let decoded) = event else {
            XCTFail("Expected capabilityInvoke gateway event")
            return
        }

        XCTAssertEqual(decoded.targetProvider, "apple-reminders-eventkit")
        XCTAssertEqual(decoded.args["title"]?.value as? String, "Buy milk")
    }

    func testGatewayEventConciergeCallCase() throws {
        let payload = ConciergeCallEvent(
            callId: "call-1",
            state: "active",
            platform: "ios",
            deviceId: "device-1",
            displayName: "Spaces Concierge",
            ttsMode: "apple_native",
            muted: false,
            targetGatewayId: "gateway-main",
            transcriptDelta: nil,
            assistantTextDelta: "How can I help?",
            urgency: "important",
            handoffToken: nil,
            metrics: ConciergeCallMetrics(
                callSetupMs: 42,
                sttFirstPartialMs: nil,
                llmFirstTokenMs: nil,
                ttsFirstAudioMs: 120,
                routeChangeCount: 0,
                handoffCount: 0,
                providerFallbackCount: 0,
                interruptCount: 0,
                playbackUnderrunCount: 0,
                reconnectCount: 0
            ),
            reason: "call_answered",
            emittedAt: "2026-03-12T10:00:00.000Z",
            mediaEventType: "assistant_text_final",
            sequence: 1,
            transcriptFinal: nil,
            assistantTextFinal: true,
            activeTurnId: "turn-1",
            providerSource: nil,
            providerId: nil,
            fallbackReason: nil,
            assistantAudioBase64: nil,
            assistantAudioDurationSeconds: nil,
            ts: "2026-03-12T10:00:00.000Z"
        )

        let event = GatewayEvent.conciergeCallEvent(payload)
        guard case .conciergeCallEvent(let decoded) = event else {
            XCTFail("Expected conciergeCallEvent gateway event")
            return
        }

        XCTAssertEqual(decoded.callId, "call-1")
        XCTAssertEqual(decoded.assistantTextDelta, "How can I help?")
        XCTAssertEqual(decoded.metrics?.ttsFirstAudioMs, 120)
    }

    // MARK: - Client Options

    func testSessionSupersededErrorDisablesReconnectPolicy() async {
        let client = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: true,
            maxReconnectAttempts: 1,
            requestTimeoutSec: 1
        ))

        await client.handleServerError(.init(
            code: "SESSION_SUPERSEDED",
            message: "Session superseded by newer connection",
            details: nil
        ))
        let blockedAfterSupersede = await client.reconnectAllowedForTesting
        XCTAssertFalse(blockedAfterSupersede)

        do {
            try await client.connect()
            XCTFail("Expected connect to fail without a running gateway.")
        } catch {
            // Expected: no server is running on test port.
        }

        let resetByConnect = await client.reconnectAllowedForTesting
        XCTAssertTrue(resetByConnect)

        await client.disconnect()
        let blockedAfterDisconnect = await client.reconnectAllowedForTesting
        XCTAssertFalse(blockedAfterDisconnect)
    }

    func testOnlySessionSupersededErrorDisablesReconnect() {
        XCTAssertTrue(GatewayClient.errorDisablesReconnect("SESSION_SUPERSEDED"))
        XCTAssertTrue(GatewayClient.errorDisablesReconnect("session_superseded"))
        XCTAssertFalse(GatewayClient.errorDisablesReconnect("AUTH_FAILED"))
    }

    func testDefaultOptions() {
        let options = GatewayClientOptions(url: URL(string: "ws://localhost:9320")!)

        XCTAssertEqual(options.clientType, "swift-sdk")
        XCTAssertEqual(options.clientVersion, "1.0.0")
        XCTAssertTrue(options.reconnect)
        XCTAssertEqual(options.maxReconnectAttempts, 10)
        XCTAssertEqual(options.requestTimeoutSec, 30)
    }

    func testFactoryResetUsesPerCallTimeoutOverride() async {
        let shortTimeoutClient = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 0.25
        ))

        let overriddenTimeoutNanos = await shortTimeoutClient.factoryResetTimeoutNanosecondsForTesting()
        XCTAssertEqual(
            overriddenTimeoutNanos,
            UInt64((180.0 * 1_000_000_000).rounded()),
            "Factory reset should override short default request timeouts to 180s."
        )

        let longTimeoutClient = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 240
        ))
        let longTimeoutNanos = await longTimeoutClient.factoryResetTimeoutNanosecondsForTesting()
        XCTAssertEqual(
            longTimeoutNanos,
            UInt64((240.0 * 1_000_000_000).rounded()),
            "Factory reset should preserve larger per-client timeouts."
        )
    }

    func testSpaceResetUsesPerCallTimeoutOverride() async {
        let shortTimeoutClient = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 0.25
        ))

        let overriddenTimeoutNanos = await shortTimeoutClient.spaceResetTimeoutNanosecondsForTesting()
        XCTAssertEqual(
            overriddenTimeoutNanos,
            UInt64((180.0 * 1_000_000_000).rounded()),
            "Space reset should override short default request timeouts to 180s."
        )

        let longTimeoutClient = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 240
        ))
        let longTimeoutNanos = await longTimeoutClient.spaceResetTimeoutNanosecondsForTesting()
        XCTAssertEqual(
            longTimeoutNanos,
            UInt64((240.0 * 1_000_000_000).rounded()),
            "Space reset should preserve larger per-client timeouts."
        )
    }

    func testResetSpaceRequiresConnection() async {
        let client = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 1
        ))

        do {
            _ = try await client.resetSpace(.init(spaceId: "space-reset-target"))
            XCTFail("Expected resetSpace to fail when WebSocket is not connected.")
        } catch let gatewayError as GatewayError {
            XCTAssertEqual(gatewayError.code, "NOT_CONNECTED")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testParseErrorReplyStillAllowsNextRequestToSucceed() async throws {
        let client = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 1
        ))

        let firstRequestId = "req-parse-failure"
        let firstRequestTask = Task {
            try await client.awaitPendingRequestForTesting(messageId: firstRequestId)
        }

        let firstPendingRegistered = await waitForPendingRequest(firstRequestId, on: client)
        XCTAssertTrue(firstPendingRegistered, "First request should be pending before injecting a reply.")

        let parseErrorReply = """
        {
            "type": "error",
            "id": "resp-parse-failure",
            "replyTo": "\(firstRequestId)",
            "ts": "2026-03-02T12:00:00.000Z",
            "payload": {}
        }
        """
        await client.handleMessageForTesting(Data(parseErrorReply.utf8))

        do {
            _ = try await firstRequestTask.value
            XCTFail("Expected first request to fail with PARSE_ERROR.")
        } catch let gatewayError as GatewayError {
            XCTAssertEqual(gatewayError.code, "PARSE_ERROR")
        } catch {
            XCTFail("Unexpected error type for parse failure continuation: \(error)")
        }

        let pendingCountAfterParseError = await client.pendingRequestCountForTesting()
        XCTAssertEqual(
            pendingCountAfterParseError,
            0,
            "PARSE_ERROR reply should clear the completed pending request."
        )

        let secondRequestId = "req-after-parse-failure"
        let secondRequestTask = Task {
            try await client.awaitPendingRequestForTesting(messageId: secondRequestId)
        }

        let secondPendingRegistered = await waitForPendingRequest(secondRequestId, on: client)
        XCTAssertTrue(secondPendingRegistered, "Second request should be pending before injecting success reply.")

        let successReply = """
        {
            "type": "gateway.factory_reset",
            "id": "resp-success",
            "replyTo": "\(secondRequestId)",
            "ts": "2026-03-02T12:00:01.000Z",
            "payload": {
                "gatewayId": "resource:main",
                "rowsDeleted": 42
            }
        }
        """
        await client.handleMessageForTesting(Data(successReply.utf8))

        let secondPayloadData = try await secondRequestTask.value
        let secondPayload = try JSONSerialization.jsonObject(with: secondPayloadData) as? [String: Any]
        XCTAssertEqual(secondPayload?["gatewayId"] as? String, "resource:main")
        XCTAssertEqual(secondPayload?["rowsDeleted"] as? Int, 42)
        let finalPendingCount = await client.pendingRequestCountForTesting()
        XCTAssertEqual(finalPendingCount, 0)
    }

    func testAppNavigateEventIsDecodedAndEmitted() async {
        let client = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 1
        ))

        let events = client.events
        let waitTask = Task {
            await self.waitForNextEvent(from: events)
        }

        let payload = """
        {
            "type": "app.navigate",
            "id": "evt-app-navigate",
            "ts": "2026-03-08T12:00:00.000Z",
            "payload": {
                "destination": "space",
                "gatewayId": "gateway-1",
                "spaceId": "space-123",
                "promptText": "Pick up the refactor."
            }
        }
        """
        await client.handleMessageForTesting(Data(payload.utf8))

        guard let event = await waitTask.value else {
            XCTFail("Expected app.navigate to emit an event.")
            return
        }

        guard case .appNavigate(let navigate) = event else {
            XCTFail("Expected appNavigate event, got \(event)")
            return
        }

        XCTAssertEqual(navigate.destination, "space")
        XCTAssertEqual(navigate.gatewayId, "gateway-1")
        XCTAssertEqual(navigate.spaceId, "space-123")
        XCTAssertEqual(navigate.promptText, "Pick up the refactor.")
    }

    func testAppConciergeActionRequestEventIsDecodedAndEmitted() async {
        let client = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 1
        ))

        let events = client.events
        let waitTask = Task {
            await self.waitForNextEvent(from: events)
        }

        let payload = """
        {
            "type": "app.concierge_action_request",
            "id": "evt-concierge-action",
            "ts": "2026-03-11T12:00:00.000Z",
            "payload": {
                "requestId": "request-1",
                "action": "update_space",
                "gatewayId": "gateway-2",
                "params": {
                    "spaceId": "space-456",
                    "name": "Refinement Space"
                }
            }
        }
        """
        await client.handleMessageForTesting(Data(payload.utf8))

        guard let event = await waitTask.value else {
            XCTFail("Expected app.concierge_action_request to emit an event.")
            return
        }

        guard case .conciergeActionRequest(let request) = event else {
            XCTFail("Expected conciergeActionRequest event, got \(event)")
            return
        }

        XCTAssertEqual(request.requestId, "request-1")
        XCTAssertEqual(request.action, .updateSpace)
        XCTAssertEqual(request.gatewayId, "gateway-2")
        XCTAssertEqual(request.params?["spaceId"]?.value as? String, "space-456")
        XCTAssertEqual(request.params?["name"]?.value as? String, "Refinement Space")
    }

    func testSpaceTurnTraceDecodingDefaultsExecutionRunsWhenMissing() throws {
        let json = """
        {
            "spaceId": "space-1",
            "turnId": "turn-1",
            "total": 0,
            "events": [],
            "toolCalls": [],
            "activities": [],
            "artifactIds": []
        }
        """

        let trace = try JSONDecoder().decode(SpaceTurnTrace.self, from: Data(json.utf8))

        XCTAssertEqual(trace.spaceId, "space-1")
        XCTAssertEqual(trace.turnId, "turn-1")
        XCTAssertTrue(trace.executionRuns.isEmpty)
    }

    func testSpaceTurnTraceDecodingIncludesExecutionRunsWhenPresent() throws {
        let json = """
        {
            "spaceId": "space-1",
            "turnId": "turn-1",
            "total": 2,
            "events": [],
            "toolCalls": [],
            "activities": [],
            "executionRuns": [
                {
                    "executionId": "exec-1",
                    "stepIndex": 0,
                    "agentId": "agent-1",
                    "providerId": "claude",
                    "modelId": "sonnet",
                    "status": "completed",
                    "startedAt": "2026-03-29T10:00:00Z",
                    "completedAt": "2026-03-29T10:00:03Z",
                    "durationMs": 3000,
                    "workingDirectory": "/tmp/workspace",
                    "exitCode": 0,
                    "commandPreview": "claude --output-format stream-json",
                    "transcriptArtifactId": "artifact-debug-1",
                    "transcriptTruncated": false
                }
            ],
            "artifactIds": ["artifact-debug-1"]
        }
        """

        let trace = try JSONDecoder().decode(SpaceTurnTrace.self, from: Data(json.utf8))

        XCTAssertEqual(trace.executionRuns.count, 1)
        XCTAssertEqual(trace.executionRuns.first?.executionId, "exec-1")
        XCTAssertEqual(trace.executionRuns.first?.workingDirectory, "/tmp/workspace")
        XCTAssertEqual(trace.executionRuns.first?.transcriptArtifactId, "artifact-debug-1")
    }

    func testSpaceGetDebugArtifactPayloadEncodingAndResultDecoding() throws {
        let payload = try encodeJSONObject(
            SpaceGetDebugArtifactPayload(
                spaceId: "space-1",
                artifactId: "artifact-debug-1"
            )
        )
        XCTAssertEqual(payload["spaceId"] as? String, "space-1")
        XCTAssertEqual(payload["artifactId"] as? String, "artifact-debug-1")

        let json = """
        {
            "artifact": {
                "artifactId": "artifact-debug-1",
                "spaceId": "space-1",
                "turnId": "turn-1",
                "agentId": "agent-1",
                "type": "cli_execution_transcript",
                "title": "CLI transcript",
                "mimeType": "application/x-ndjson",
                "sizeBytes": 24,
                "tags": ["debug", "cli_execution", "transcript"],
                "visibility": "private",
                "createdAt": "2026-03-29T10:00:00Z",
                "updatedAt": "2026-03-29T10:00:04Z",
                "content": "{\\"event\\":\\"started\\"}\\n"
            }
        }
        """

        let result = try JSONDecoder().decode(SpaceGetDebugArtifactResult.self, from: Data(json.utf8))

        XCTAssertEqual(result.artifact.artifactId, "artifact-debug-1")
        XCTAssertEqual(result.artifact.type, "cli_execution_transcript")
        XCTAssertEqual(result.artifact.content.value as? String, "{\"event\":\"started\"}\n")
    }
}
