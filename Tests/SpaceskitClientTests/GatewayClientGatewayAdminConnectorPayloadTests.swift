import XCTest
@testable import SpaceskitClient

final class GatewayClientGatewayAdminConnectorPayloadTests: GatewayClientTestCase {

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
}
