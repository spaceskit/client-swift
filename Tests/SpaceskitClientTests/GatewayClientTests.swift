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
            "status": "completed"
        }
        """
        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(TurnResult.self, from: data)

        XCTAssertEqual(result.turnId, "turn-123")
        XCTAssertEqual(result.spaceId, "space-456")
        XCTAssertEqual(result.output, "Hello from agent")
        XCTAssertEqual(result.status, .completed)
        XCTAssertNil(result.error)
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

    // MARK: - Protocol Message Encoding

    func testGatewayMessageEncoding() throws {
        let payload = ExecuteTurnPayload(spaceUid: "11111111-2222-3333-4444-555555555555", input: "Hello")
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
    }

    func testConnectorListPayloadEncoding() throws {
        let payload = GatewayListConnectorsPayload(apiVersion: "v1", familyId: "apple-calendar-eventkit")
        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["apiVersion"] as? String, "v1")
        XCTAssertEqual(json?["familyId"] as? String, "apple-calendar-eventkit")
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
            "nativeCliToolsEnabled": false,
            "updatedAt": "2026-02-24T00:00:00.000Z",
            "source": "runtime"
        }
        """
        let providerConfig = try JSONDecoder().decode(GatewayProviderRuntimeConfig.self, from: Data(providerConfigJSON.utf8))
        XCTAssertEqual(providerConfig.apiKeySecretRef, "secretref-openrouter-primary")
        XCTAssertEqual(providerConfig.allowedModels, ["openrouter/openai/gpt-4.1-mini"])
        XCTAssertFalse(providerConfig.allowCustomModel)
        XCTAssertFalse(providerConfig.nativeCliToolsEnabled)

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

    func testListAvailableModelsPayloadAndResponseDecoding() throws {
        let payload = GatewayListAvailableModelsPayload(apiVersion: "v1", providerId: "openai")
        let payloadJSON = try encodeJSONObject(payload)
        XCTAssertEqual(payloadJSON["providerId"] as? String, "openai")

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
        let listCatalogsPayload = GatewayListProviderCatalogsPayload(apiVersion: "v1", providerId: "openai")
        let listCatalogsJSON = try encodeJSONObject(listCatalogsPayload)
        XCTAssertEqual(listCatalogsJSON["providerId"] as? String, "openai")

        let getSettingsPayload = GatewayGetProviderSettingsPayload(apiVersion: "v1", providerId: "openai")
        let getSettingsJSON = try encodeJSONObject(getSettingsPayload)
        XCTAssertEqual(getSettingsJSON["providerId"] as? String, "openai")

        let setConfigPayload = GatewaySetProviderConfigPayload(
            apiVersion: "v1",
            providerId: "claude",
            model: "claude/sonnet",
            apiKey: nil,
            apiKeySecretRef: "secretref-claude-primary",
            baseURL: nil,
            allowedModels: ["claude/sonnet"],
            allowCustomModel: false,
            nativeCliToolsEnabled: true
        )
        let setConfigJSON = try encodeJSONObject(setConfigPayload)
        XCTAssertEqual(setConfigJSON["providerId"] as? String, "claude")
        XCTAssertEqual(setConfigJSON["allowCustomModel"] as? Bool, false)
        XCTAssertEqual(setConfigJSON["allowedModels"] as? [String], ["claude/sonnet"])
        XCTAssertEqual(setConfigJSON["nativeCliToolsEnabled"] as? Bool, true)

        let updateSettingsPayload = GatewayUpdateProviderSettingsPayload(
            apiVersion: "v1",
            providerId: "claude",
            model: "claude/sonnet",
            apiKey: nil,
            apiKeySecretRef: "secretref-claude-primary",
            baseURL: nil,
            allowedModels: ["claude/sonnet"],
            allowCustomModel: false,
            nativeCliToolsEnabled: true
        )
        let updateSettingsJSON = try encodeJSONObject(updateSettingsPayload)
        XCTAssertEqual(updateSettingsJSON["providerId"] as? String, "claude")
        XCTAssertEqual(updateSettingsJSON["allowCustomModel"] as? Bool, false)
        XCTAssertEqual(updateSettingsJSON["nativeCliToolsEnabled"] as? Bool, true)

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
                "nativeCliToolsEnabled": false,
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
        XCTAssertFalse(getSettingsResponse.settings.nativeCliToolsEnabled)

        let updateSettingsResponse = try JSONDecoder().decode(
            GatewayUpdateProviderSettingsResponsePayload.self,
            from: Data(settingsJSON.utf8)
        )
        XCTAssertEqual(updateSettingsResponse.settings.allowedModels, ["openai/qwen2.5-coder"])
        XCTAssertFalse(updateSettingsResponse.settings.nativeCliToolsEnabled)
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
            sourceProfileId: nil,
            copyPersonality: nil
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
                "mainProfileId": "main-profile",
                "assignedProfileId": "main-profile",
                "providerHint": "openai",
                "modelHint": "openai/gpt-4.1",
                "status": "fallback",
                "repaired": true,
                "fallbackApplied": true,
                "fallbackReason": "Configured provider unavailable: missing-provider",
                "updatedAt": "2026-03-02T12:00:00.000Z"
            }
        }
        """
        let decoded = try JSONDecoder().decode(
            GatewayGetMainAgentResponsePayload.self,
            from: Data(responseJSON.utf8)
        )
        XCTAssertEqual(decoded.state.mainAgentId, "main-agent")
        XCTAssertEqual(decoded.state.status, .fallback)
        XCTAssertEqual(decoded.state.fallbackApplied, true)
    }

    func testAdminFixturesRemainLoadable() throws {
        let fixtureNames = [
            "GatewayGetMainAgentPayload",
            "GatewaySetMainAgentPayload",
            "GatewayGetMainAgentResponsePayload",
            "GatewaySetMainAgentResponsePayload",
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
        XCTAssertEqual(decoded.metaPath, "/tmp/spaces/space-1/.space")
        XCTAssertEqual(decoded.metadataStatus, .ready)
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
                "layoutVersion": 2,
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
        XCTAssertEqual(decoded.workspace?.metadataStatus, .ready)
    }

    func testAdapterPayloadEncoding() throws {
        let provider = AdapterCapabilityProvider(
            id: "apple-reminders-eventkit",
            name: "Apple Reminders (EventKit)",
            capabilityType: "lists",
            operations: ["listLists", "listItems", "createItem"]
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
}
