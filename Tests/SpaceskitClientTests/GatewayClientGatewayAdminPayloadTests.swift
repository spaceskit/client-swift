import XCTest
@testable import SpaceskitClient

final class GatewayClientGatewayAdminPayloadTests: GatewayClientTestCase {

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
            profileBinding: .explicit,
            role: .participant,
            turnOrder: 1,
            isPrimary: true
        )
        let templateJSON = try encodeJSONObject(templateAgent)
        XCTAssertEqual(templateJSON["agentDefinitionId"] as? String, "agent-definition-1")
        XCTAssertEqual(templateJSON["profileId"] as? String, "agent-definition-1")
        XCTAssertEqual(templateJSON["profileBinding"] as? String, "explicit")

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
}
