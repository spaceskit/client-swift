import XCTest
@testable import SpaceskitClient

final class GatewayClientProtocolPayloadTestsSpacePayloads: GatewayClientTestCase {

    // MARK: - Space Content, Memory, and Payload Helpers

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
                    "displayTitle": "Plan provider session reuse",
                    "status": "active",
                    "startedAt": "2026-03-07T09:55:00.000Z",
                    "lastActivityAt": "2026-03-07T10:00:00.000Z",
                    "turnCount": 2,
                    "inputTokens": 90,
                    "outputTokens": 20,
                    "totalTokens": 110,
                    "spentUsd": 0.0033,
                    "tokenAccuracy": "estimated",
                    "usageSource": "turn_ledger"
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
        XCTAssertEqual(result.agentSessions?.first?.usageSource, "turn_ledger")
        XCTAssertEqual(result.agentSessions?.first?.displayTitle, "Plan provider session reuse")
        XCTAssertEqual(result.globalLifetime?.tokenAccuracy, "mixed")
        XCTAssertEqual(result.globalLifetime?.usageSource, "ledger")
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
            SpaceResetResult.self,
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
}
