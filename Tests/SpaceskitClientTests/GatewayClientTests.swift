// GatewayClientTests.swift — Basic tests for Spaceskit Swift Client SDK

import XCTest
@testable import SpaceskitClient

final class GatewayClientTests: GatewayClientTestCase {

    // MARK: - Auth Key Pair

    func testAuthKeyPairGeneration() throws {
        let keyPair = AuthKeyPair()

        // Public key should be 32 bytes → 44 chars in base64
        XCTAssertFalse(keyPair.publicKeyBase64.isEmpty)
        XCTAssertEqual(keyPair.publicKey.rawRepresentation.count, 32)
    }

    func testAuthKeyPairFromRawKey() throws {
        let original = AuthKeyPair()
        let rawKey = original.privateKey.rawRepresentation

        let restored = try AuthKeyPair(rawPrivateKey: rawKey)
        XCTAssertEqual(restored.publicKeyBase64, original.publicKeyBase64)
    }

    // MARK: - Challenge Signing

    func testSignAndVerifyChallenge() throws {
        let keyPair = AuthKeyPair()

        // Simulate a 32-byte challenge (like the server sends)
        let challengeBytes = (0..<32).map { _ in UInt8.random(in: 0...255) }
        let challengeBase64 = Data(challengeBytes).base64EncodedString()

        // Sign the challenge
        let signature = try signChallenge(challengeBase64, with: keyPair)
        XCTAssertFalse(signature.isEmpty)

        // Verify the signature
        let isValid = verifySignature(
            signature,
            for: challengeBase64,
            publicKey: keyPair.publicKey
        )
        XCTAssertTrue(isValid, "Signature should be valid")
    }

    func testSignChallengeWithInvalidBase64() {
        let keyPair = AuthKeyPair()

        XCTAssertThrowsError(try signChallenge("not-valid-base64!!!", with: keyPair)) { error in
            XCTAssertTrue(error is AuthError)
        }
    }

    func testVerifyWithWrongKey() throws {
        let keyPair1 = AuthKeyPair()
        let keyPair2 = AuthKeyPair()

        let challengeBytes = (0..<32).map { _ in UInt8.random(in: 0...255) }
        let challengeBase64 = Data(challengeBytes).base64EncodedString()

        let signature = try signChallenge(challengeBase64, with: keyPair1)

        // Verify with wrong public key should fail
        let isValid = verifySignature(
            signature,
            for: challengeBase64,
            publicKey: keyPair2.publicKey
        )
        XCTAssertFalse(isValid, "Signature should be invalid with wrong key")
    }

    // MARK: - Client Options

    func testSessionSupersededErrorDisablesReconnectPolicy() async {
        let client = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: true,
            maxReconnectAttempts: 1,
            requestTimeoutSec: 1
        ))

        await client.handleServerError(.init(
            code: "SESSION_SUPERSEDED",
            message: "Session superseded by newer connection",
            details: nil
        ))
        let blockedAfterSupersede = await client.reconnectAllowedForTesting
        XCTAssertFalse(blockedAfterSupersede)

        do {
            try await client.connect()
            XCTFail("Expected connect to fail without a running gateway.")
        } catch {
            // Expected: no server is running on test port.
        }

        let resetByConnect = await client.reconnectAllowedForTesting
        XCTAssertTrue(resetByConnect)

        await client.disconnect()
        let blockedAfterDisconnect = await client.reconnectAllowedForTesting
        XCTAssertFalse(blockedAfterDisconnect)
    }

    func testOnlySessionSupersededErrorDisablesReconnect() {
        XCTAssertTrue(GatewayClient.errorDisablesReconnect("SESSION_SUPERSEDED"))
        XCTAssertTrue(GatewayClient.errorDisablesReconnect("session_superseded"))
        XCTAssertFalse(GatewayClient.errorDisablesReconnect("AUTH_FAILED"))
    }

    func testDefaultOptions() {
        let options = GatewayClientOptions(url: URL(string: "ws://localhost:9320")!)

        XCTAssertEqual(options.clientType, "swift-sdk")
        XCTAssertEqual(options.clientVersion, "1.0.0")
        XCTAssertTrue(options.reconnect)
        XCTAssertEqual(options.maxReconnectAttempts, 10)
        XCTAssertEqual(options.requestTimeoutSec, 30)
    }

    func testFactoryResetUsesPerCallTimeoutOverride() async {
        let shortTimeoutClient = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 0.25
        ))

        let overriddenTimeoutNanos = await shortTimeoutClient.factoryResetTimeoutNanosecondsForTesting()
        XCTAssertEqual(
            overriddenTimeoutNanos,
            UInt64((180.0 * 1_000_000_000).rounded()),
            "Factory reset should override short default request timeouts to 180s."
        )

        let longTimeoutClient = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 240
        ))
        let longTimeoutNanos = await longTimeoutClient.factoryResetTimeoutNanosecondsForTesting()
        XCTAssertEqual(
            longTimeoutNanos,
            UInt64((240.0 * 1_000_000_000).rounded()),
            "Factory reset should preserve larger per-client timeouts."
        )
    }

    func testSpaceResetUsesPerCallTimeoutOverride() async {
        let shortTimeoutClient = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 0.25
        ))

        let overriddenTimeoutNanos = await shortTimeoutClient.spaceResetTimeoutNanosecondsForTesting()
        XCTAssertEqual(
            overriddenTimeoutNanos,
            UInt64((180.0 * 1_000_000_000).rounded()),
            "Space reset should override short default request timeouts to 180s."
        )

        let longTimeoutClient = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 240
        ))
        let longTimeoutNanos = await longTimeoutClient.spaceResetTimeoutNanosecondsForTesting()
        XCTAssertEqual(
            longTimeoutNanos,
            UInt64((240.0 * 1_000_000_000).rounded()),
            "Space reset should preserve larger per-client timeouts."
        )
    }

    func testResetSpaceRequiresConnection() async {
        let client = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 1
        ))

        do {
            _ = try await client.resetSpace(.init(spaceId: "space-reset-target"))
            XCTFail("Expected resetSpace to fail when WebSocket is not connected.")
        } catch let gatewayError as GatewayError {
            XCTAssertEqual(gatewayError.code, "NOT_CONNECTED")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testParseErrorReplyStillAllowsNextRequestToSucceed() async throws {
        let client = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 1
        ))

        let firstRequestId = "req-parse-failure"
        let firstRequestTask = Task {
            try await client.awaitPendingRequestForTesting(messageId: firstRequestId)
        }

        let firstPendingRegistered = await waitForPendingRequest(firstRequestId, on: client)
        XCTAssertTrue(firstPendingRegistered, "First request should be pending before injecting a reply.")

        let parseErrorReply = """
        {
            "type": "error",
            "id": "resp-parse-failure",
            "replyTo": "\(firstRequestId)",
            "ts": "2026-03-02T12:00:00.000Z",
            "payload": {}
        }
        """
        await client.handleMessageForTesting(Data(parseErrorReply.utf8))

        do {
            _ = try await firstRequestTask.value
            XCTFail("Expected first request to fail with PARSE_ERROR.")
        } catch let gatewayError as GatewayError {
            XCTAssertEqual(gatewayError.code, "PARSE_ERROR")
        } catch {
            XCTFail("Unexpected error type for parse failure continuation: \(error)")
        }

        let pendingCountAfterParseError = await client.pendingRequestCountForTesting()
        XCTAssertEqual(
            pendingCountAfterParseError,
            0,
            "PARSE_ERROR reply should clear the completed pending request."
        )

        let secondRequestId = "req-after-parse-failure"
        let secondRequestTask = Task {
            try await client.awaitPendingRequestForTesting(messageId: secondRequestId)
        }

        let secondPendingRegistered = await waitForPendingRequest(secondRequestId, on: client)
        XCTAssertTrue(secondPendingRegistered, "Second request should be pending before injecting success reply.")

        let successReply = """
        {
            "type": "gateway.factory_reset",
            "id": "resp-success",
            "replyTo": "\(secondRequestId)",
            "ts": "2026-03-02T12:00:01.000Z",
            "payload": {
                "gatewayId": "resource:main",
                "rowsDeleted": 42
            }
        }
        """
        await client.handleMessageForTesting(Data(successReply.utf8))

        let secondPayloadData = try await secondRequestTask.value
        let secondPayload = try JSONSerialization.jsonObject(with: secondPayloadData) as? [String: Any]
        XCTAssertEqual(secondPayload?["gatewayId"] as? String, "resource:main")
        XCTAssertEqual(secondPayload?["rowsDeleted"] as? Int, 42)
        let finalPendingCount = await client.pendingRequestCountForTesting()
        XCTAssertEqual(finalPendingCount, 0)
    }

    func testAppNavigateEventIsDecodedAndEmitted() async {
        let client = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 1
        ))

        let events = client.events
        let waitTask = Task {
            await self.waitForNextEvent(from: events)
        }

        let payload = """
        {
            "type": "app.navigate",
            "id": "evt-app-navigate",
            "ts": "2026-03-08T12:00:00.000Z",
            "payload": {
                "destination": "space",
                "gatewayId": "gateway-1",
                "spaceId": "space-123",
                "promptText": "Pick up the refactor."
            }
        }
        """
        await client.handleMessageForTesting(Data(payload.utf8))

        guard let event = await waitTask.value else {
            XCTFail("Expected app.navigate to emit an event.")
            return
        }

        guard case .appNavigate(let navigate) = event else {
            XCTFail("Expected appNavigate event, got \(event)")
            return
        }

        XCTAssertEqual(navigate.destination, "space")
        XCTAssertEqual(navigate.gatewayId, "gateway-1")
        XCTAssertEqual(navigate.spaceId, "space-123")
        XCTAssertEqual(navigate.promptText, "Pick up the refactor.")
    }

    func testAppConciergeActionRequestEventIsDecodedAndEmitted() async {
        let client = GatewayClient(options: .init(
            url: URL(string: "ws://127.0.0.1:65530")!,
            reconnect: false,
            requestTimeoutSec: 1
        ))

        let events = client.events
        let waitTask = Task {
            await self.waitForNextEvent(from: events)
        }

        let payload = """
        {
            "type": "app.concierge_action_request",
            "id": "evt-concierge-action",
            "ts": "2026-03-11T12:00:00.000Z",
            "payload": {
                "requestId": "request-1",
                "action": "update_space",
                "gatewayId": "gateway-2",
                "params": {
                    "spaceId": "space-456",
                    "name": "Refinement Space"
                }
            }
        }
        """
        await client.handleMessageForTesting(Data(payload.utf8))

        guard let event = await waitTask.value else {
            XCTFail("Expected app.concierge_action_request to emit an event.")
            return
        }

        guard case .conciergeActionRequest(let request) = event else {
            XCTFail("Expected conciergeActionRequest event, got \(event)")
            return
        }

        XCTAssertEqual(request.requestId, "request-1")
        XCTAssertEqual(request.action, .updateSpace)
        XCTAssertEqual(request.gatewayId, "gateway-2")
        XCTAssertEqual(request.params?["spaceId"]?.value as? String, "space-456")
        XCTAssertEqual(request.params?["name"]?.value as? String, "Refinement Space")
    }

}
