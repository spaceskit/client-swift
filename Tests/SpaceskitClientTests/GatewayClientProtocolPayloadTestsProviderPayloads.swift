import XCTest
@testable import SpaceskitClient

final class GatewayClientProtocolPayloadTestsProviderPayloads: GatewayClientTestCase {

    // MARK: - Gateway Provider Payloads

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
}
