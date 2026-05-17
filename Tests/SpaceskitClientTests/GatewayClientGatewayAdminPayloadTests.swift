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
            GatewayPutSecretRefResult.self,
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
            GatewayDeleteSecretRefResult.self,
            from: Data(deleteResponseJSON.utf8)
        )
        XCTAssertTrue(deleteResponse.deleted)
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

}
