import XCTest
@testable import SpaceskitClient

final class GatewayClientTurnEventCodableTests: GatewayClientTestCase {

    func testTurnStreamDecoding() throws {
        let json = """
        {
            "spaceId": "space-1",
            "spaceUid": "space-uid-1",
            "turnId": "turn-1",
            "agentId": "agent-1",
            "transcriptVisibility": "activity_only",
            "streamKind": "provider_client",
            "delta": "Hello ",
            "seq": 0,
            "done": false
        }
        """
        let data = json.data(using: .utf8)!
        let stream = try JSONDecoder().decode(TurnStream.self, from: data)

        XCTAssertEqual(stream.delta, "Hello ")
        XCTAssertEqual(stream.seq, 0)
        XCTAssertFalse(stream.done)
        XCTAssertEqual(stream.transcriptVisibility, .activityOnly)
        XCTAssertEqual(stream.streamKind, .providerClient)
        XCTAssertNil(stream.timestamp)
    }

    func testTypedTurnEventPayloadDecodesCanonicalActivityState() throws {
        let json = """
        {
            "kind": "state.changed",
            "state": "acting"
        }
        """

        let payload = try JSONDecoder().decode(TypedTurnEventPayload.self, from: Data(json.utf8))

        guard case .stateChanged(let statePayload) = payload else {
            return XCTFail("Expected state.changed payload")
        }
        XCTAssertEqual(statePayload.state, .acting)
    }

    func testTurnEventResolvedAgentActivityStateUsesTypedPayload() throws {
        let json = """
        {
            "spaceId": "space-1",
            "spaceUid": "space-uid-1",
            "turnId": "turn-1",
            "typedPayload": {
                "kind": "state.changed",
                "state": "needs_feedback"
            }
        }
        """

        let event = try JSONDecoder().decode(TurnEvent.self, from: Data(json.utf8))

        XCTAssertEqual(event.resolvedAgentActivityState, .needsFeedback)
        XCTAssertEqual(event.resolvedAgentState, AgentActivityState.needsFeedback.rawValue)
        XCTAssertEqual(event.kind, "state.changed")
    }

    func testTurnEventRejectsUntypedPayloads() throws {
        let json = """
        {
            "spaceId": "space-1",
            "spaceUid": "space-uid-1",
            "turnId": "turn-1",
            "eventType": "state_changed",
            "data": {
                "state": "needs_feedback"
            }
        }
        """

        XCTAssertThrowsError(try JSONDecoder().decode(TurnEvent.self, from: Data(json.utf8)))
    }

    func testTurnEventEncodingUsesTypedPayloadKindOnly() throws {
        let event = TurnEvent(
            spaceId: "space-1",
            spaceUid: "space-uid-1",
            turnId: "turn-1",
            typedPayload: .stateChanged(StateChangedPayload(state: .acting))
        )

        let encoded = try encodeJSONObject(event)
        XCTAssertNil(encoded["eventType"])
        XCTAssertNil(encoded["data"])
        let payload = encoded["typedPayload"] as? [String: Any]
        XCTAssertEqual(payload?["kind"] as? String, "state.changed")
        XCTAssertEqual(payload?["state"] as? String, "acting")
    }
}
