import XCTest
@testable import SpaceskitClient

final class GatewayClientProtocolPayloadTests: GatewayClientTestCase {

    // MARK: - Protocol Message, Turn, and Feedback Payloads

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
}
