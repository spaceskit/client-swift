import XCTest
@testable import SpaceskitClient

final class GatewayClientTypesCodableTests: GatewayClientTestCase {

    // MARK: - Types Codable

    func testTurnResultDecoding() throws {
        let json = """
        {
            "turnId": "turn-123",
            "spaceId": "space-456",
            "output": "Hello from agent",
            "status": "completed",
            "mode": "assistant",
            "effort": "high"
        }
        """
        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(TurnResult.self, from: data)

        XCTAssertEqual(result.turnId, "turn-123")
        XCTAssertEqual(result.spaceId, "space-456")
        XCTAssertEqual(result.output, "Hello from agent")
        XCTAssertEqual(result.status, .completed)
        XCTAssertNil(result.error)
        XCTAssertEqual(result.mode, "assistant")
        XCTAssertEqual(result.effort, "high")
    }

    func testGatewayIntegrationsSnapshotDecodesSupportedInterconnectors() throws {
        let json = """
        {
            "groups": [],
            "supportedInterconnectors": [
                {
                    "bundleId": "jira-cli",
                    "bundleDisplayName": "Jira CLI",
                    "bundleDescription": "Gateway-managed Jira CLI bundle.",
                    "availabilityStatus": "inactive",
                    "detected": false,
                    "executablePath": null,
                    "installHint": "Install `jira` on the gateway host and make it resolvable, then rescan CLI Tools.",
                    "toolIds": ["jira.issue.view"],
                    "toolCount": 1,
                    "managedEnabled": true,
                    "healthStatus": "unknown",
                    "healthMessage": "Jira CLI is not detected on this gateway.",
                    "updatedAt": "2026-03-09T10:00:00Z"
                }
            ],
            "generatedAt": "2026-03-09T10:00:00Z"
        }
        """
        let snapshot = try JSONDecoder().decode(GatewayIntegrationsSnapshot.self, from: Data(json.utf8))

        XCTAssertEqual(snapshot.supportedInterconnectors?.first?.bundleId, "jira-cli")
        XCTAssertEqual(snapshot.supportedInterconnectors?.first?.availabilityStatus, .inactive)
        XCTAssertEqual(snapshot.supportedInterconnectors?.first?.toolCount, 1)
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

}
