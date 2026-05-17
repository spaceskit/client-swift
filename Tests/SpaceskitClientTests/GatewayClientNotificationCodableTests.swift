import XCTest
@testable import SpaceskitClient

final class GatewayClientNotificationCodableTests: GatewayClientTestCase {

    func testApplePushDeviceRegistrationRequestEncoding() throws {
        let request = ApplePushDeviceRegistrationRequest(
            deviceId: "device-1",
            platform: .ios,
            tokenKind: .voip,
            pushToken: "voip-token-1",
            topic: "io.spaces.app.voip",
            environment: .sandbox,
            appBundleId: "io.spaces.app",
            deviceName: "iPhone",
            metadata: ["locale": AnyCodable("en-US")]
        )

        let json = try encodeJSONObject(request)

        XCTAssertEqual(json["deviceId"] as? String, "device-1")
        XCTAssertEqual(json["platform"] as? String, "ios")
        XCTAssertEqual(json["tokenKind"] as? String, "voip")
        XCTAssertEqual(json["pushToken"] as? String, "voip-token-1")
        XCTAssertEqual(json["topic"] as? String, "io.spaces.app.voip")
        XCTAssertEqual(json["environment"] as? String, "sandbox")
    }

    func testNotificationActionPayloadDecoding() throws {
        let json = """
        {
            "gatewayId": "gateway-1",
            "deliveryId": "delivery-1",
            "feedbackId": "feedback-1",
            "action": "approve",
            "deepLink": "spaces://feedback/feedback-1",
            "payload": {
                "source": "push"
            }
        }
        """

        let context = try JSONDecoder().decode(NotificationActionContext.self, from: Data(json.utf8))

        XCTAssertEqual(context.gatewayId, "gateway-1")
        XCTAssertEqual(context.deliveryId, "delivery-1")
        XCTAssertEqual(context.feedbackId, "feedback-1")
        XCTAssertEqual(context.action, .approve)
        XCTAssertEqual(context.payload?["source"]?.value as? String, "push")
    }

    func testBackgroundFeedbackResolveModelsRoundTrip() throws {
        let request = BackgroundFeedbackResolveRequest(
            deliveryId: "delivery-1",
            action: .revise,
            message: "Use a safer rollout",
            payload: ["scope": AnyCodable("staging")]
        )
        let encoded = try JSONEncoder().encode(request)
        let encodedJSON = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

        XCTAssertEqual(encodedJSON?["deliveryId"] as? String, "delivery-1")
        XCTAssertEqual(encodedJSON?["action"] as? String, "revise")

        let resultJSON = """
        {
            "feedbackId": "feedback-1",
            "action": "revise",
            "status": "resolved",
            "result": {
                "requestId": "feedback-1"
            }
        }
        """
        let result = try JSONDecoder().decode(BackgroundFeedbackActionResult.self, from: Data(resultJSON.utf8))

        XCTAssertEqual(result.feedbackId, "feedback-1")
        XCTAssertEqual(result.action, .revise)
        XCTAssertEqual(result.status, "resolved")
        XCTAssertEqual(result.result?["requestId"]?.value as? String, "feedback-1")
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

}
