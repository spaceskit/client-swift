import XCTest
@testable import SpaceskitClient

final class GatewayRuntimeIntegrationTests: XCTestCase {
    private struct RetryFailure: Error, LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    private func isTruthy(_ value: String?) -> Bool {
        guard let raw = value?.lowercased() else { return false }
        return raw == "1" || raw == "true" || raw == "yes"
    }

    private func requireRuntimeMode() throws {
        let env = ProcessInfo.processInfo.environment
        let enabled = isTruthy(env["SPACESKIT_E2E_RUNTIME"])

        if !enabled {
            throw XCTSkip("Skipping live runtime integration test. Set SPACESKIT_E2E_RUNTIME=1 to enable.")
        }
    }

    private func gatewayURL() throws -> URL {
        let env = ProcessInfo.processInfo.environment
        let raw = env["SPACESKIT_MAIN_GATEWAY_WS_URL"] ?? "ws://127.0.0.1:9320"
        guard let url = URL(string: raw) else {
            throw XCTSkip("Invalid SPACESKIT_MAIN_GATEWAY_WS_URL: \(raw)")
        }
        return url
    }

    private func retry<T>(
        label: String,
        attempts: Int = 15,
        delayMs: UInt64 = 200,
        operation: () async throws -> T
    ) async throws -> T {
        precondition(attempts > 0)

        var lastError: Error?
        for attempt in 1...attempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < attempts {
                    try await Task.sleep(nanoseconds: delayMs * 1_000_000)
                }
            }
        }

        throw RetryFailure(message: "\(label) failed after \(attempts) attempts: \(String(describing: lastError))")
    }

    func testGatewayRuntimeCoreFlow() async throws {
        try requireRuntimeMode()
        let keyPair = AuthKeyPair()

        let client = GatewayClient(options: .init(
            url: try gatewayURL(),
            clientType: "swift-runtime-smoke",
            clientVersion: "1.0.0",
            authKeyPair: keyPair,
            deviceId: "swift-runtime-smoke-device",
            devicePublicKey: keyPair.publicKeyBase64,
            reconnect: false,
            requestTimeoutSec: 10
        ))

        do {
            try await client.connect()

            try await retry(label: "ping", attempts: 10, delayMs: 150) {
                try await client.ping()
            }

            let bootstrap = try await retry(label: "connectAndBootstrapMainSpace", attempts: 20, delayMs: 150) {
                try await client.connectAndBootstrapMainSpace(.init(subscribe: false))
            }

            XCTAssertFalse(bootstrap.space.id.isEmpty)

            let ack = try await retry(label: "executeTurnEvent", attempts: 10, delayMs: 200) {
                try await client.executeTurnEvent(
                    spaceUid: bootstrap.space.spaceUid,
                    input: "Core runtime smoke: return an immediate ack."
                )
            }

            XCTAssertEqual(ack.spaceId, bootstrap.space.id)
            XCTAssertFalse(ack.turnId.isEmpty)

            await client.disconnect()
            let state = await client.connectionState
            XCTAssertEqual(state, .disconnected)
        } catch {
            await client.disconnect()
            throw error
        }
    }
}
