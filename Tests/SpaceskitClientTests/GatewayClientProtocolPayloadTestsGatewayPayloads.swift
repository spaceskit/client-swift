import XCTest
@testable import SpaceskitClient

final class GatewayClientProtocolPayloadTestsGatewayPayloads: GatewayClientTestCase {

    // MARK: - Gateway Connector and Tool Payloads

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

    func testBuiltinMcpAdminRuntimeStateDecodesPrincipalTokenAuthMode() throws {
        let json = """
        {
            "endpointPath": "/mcp/spaces-admin",
            "effectiveEnabled": true,
            "bootstrapDefaultEnabled": true,
            "authMode": "principal_token",
            "tokenIssuerAvailable": true,
            "defaultTargetSpaceId": "main-space"
        }
        """

        let decoded = try JSONDecoder().decode(
            GatewayBuiltinMcpAdminRuntimeState.self,
            from: Data(json.utf8)
        )
        XCTAssertEqual(decoded.authMode, .principalToken)

        let encoded = try encodeJSONObject(decoded)
        XCTAssertEqual(encoded["authMode"] as? String, "principal_token")
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
}
