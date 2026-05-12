import XCTest
@testable import SpaceskitClient

class GatewayClientTestCase: XCTestCase {
    func loadFixture(_ name: String) throws -> Data {
        let fixtureDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
        return try Data(contentsOf: fixtureDir.appendingPathComponent("\(name).json"))
    }

    func encodeJSONObject<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let json = try JSONSerialization.jsonObject(with: data)
        guard let dict = json as? [String: Any] else {
            XCTFail("Expected encoded JSON dictionary.")
            return [:]
        }
        return dict
    }

    func waitForPendingRequest(
        _ messageId: String,
        on client: GatewayClient,
        maxAttempts: Int = 200,
        pollIntervalNanos: UInt64 = 5_000_000
    ) async -> Bool {
        for _ in 0..<maxAttempts {
            if await client.hasPendingRequestForTesting(messageId) {
                return true
            }
            try? await Task.sleep(nanoseconds: pollIntervalNanos)
        }
        return await client.hasPendingRequestForTesting(messageId)
    }

    func waitForNextEvent(
        from stream: AsyncStream<GatewayEvent>,
        timeoutNanoseconds: UInt64 = 500_000_000
    ) async -> GatewayEvent? {
        await withTaskGroup(of: GatewayEvent?.self) { group in
            group.addTask {
                var iterator = stream.makeAsyncIterator()
                return await iterator.next()
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                return nil
            }

            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
