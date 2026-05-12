import XCTest
@testable import SpaceskitClient

final class GatewayClientSpaceWorkspaceAdapterTests: GatewayClientTestCase {

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
}
