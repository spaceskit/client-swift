// GatewayClient state handling and package-level testing hooks.

import Foundation

extension GatewayClient {
    // MARK: - Private: State & Events

    func setState(_ newState: ConnectionState) {
        state = newState
        emit(.connectionStateChanged(newState))
    }

    func handleServerError(_ error: GatewayError) {
        if Self.errorDisablesReconnect(error.code) {
            reconnectAllowed = false
        }
        emit(.error(error))
    }

    static func errorDisablesReconnect(_ code: String) -> Bool {
        code.uppercased() == "SESSION_SUPERSEDED"
    }

    func factoryResetTimeoutNanosecondsForTesting() -> UInt64 {
        requestTimeoutNanoseconds(timeoutSec: max(options.requestTimeoutSec, 180))
    }

    func spaceResetTimeoutNanosecondsForTesting() -> UInt64 {
        requestTimeoutNanoseconds(timeoutSec: max(options.requestTimeoutSec, 180))
    }

    func awaitPendingRequestForTesting(messageId: String) async throws -> Data {
        try await withUnsafeThrowingContinuation { continuation in
            pendingRequests[messageId] = PendingRequest(continuation: continuation)
        }
    }

    func handleMessageForTesting(_ data: Data) async {
        await handleMessage(data)
    }

    func hasPendingRequestForTesting(_ messageId: String) -> Bool {
        pendingRequests[messageId] != nil
    }

    func pendingRequestCountForTesting() -> Int {
        pendingRequests.count
    }

    var reconnectAllowedForTesting: Bool { reconnectAllowed }
}
