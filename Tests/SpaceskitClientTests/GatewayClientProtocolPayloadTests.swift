import XCTest
@testable import SpaceskitClient

final class GatewayClientProtocolPayloadTests: GatewayClientTestCase {

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
        XCTAssertEqual(result.agentSessions?.first?.displayTitle, "Plan provider session reuse")
        XCTAssertEqual(result.globalLifetime?.tokenAccuracy, "mixed")
        XCTAssertEqual(result.globalLifetime?.usageSource, "ledger")
    }

    func testAgentUsageSessionSnapshotDecodesLegacyPayloadWithoutDisplayTitle() throws {
        let sessionJSON = """
        {
            "sessionId": "session-legacy",
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
        """

        let session = try JSONDecoder().decode(
            AgentUsageSessionSnapshot.self,
            from: Data(sessionJSON.utf8)
        )
        XCTAssertNil(session.displayTitle)
        XCTAssertEqual(session.sessionId, "session-legacy")
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
}
