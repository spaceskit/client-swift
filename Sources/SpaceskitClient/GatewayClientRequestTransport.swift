// GatewayClient request transport helpers.

import Foundation

extension GatewayClient {
    func send<T: Codable>(type: String, payload: T) async throws -> String {
        guard let ws = task else {
            throw GatewayError(code: "NOT_CONNECTED", message: "WebSocket not connected", details: nil)
        }

        let messageId = UUID().uuidString
        let message = GatewayMessage(type: type, id: messageId, payload: payload)
        let data = try encoder.encode(message)
        let string = String(data: data, encoding: .utf8)!

        try await ws.send(.string(string))

        return messageId
    }

    func sendAndWait(
        type: String,
        payload: some Codable,
        timeoutSec: TimeInterval? = nil
    ) async throws -> Data {
        let messageId = UUID().uuidString
        let message = GatewayMessage(type: type, id: messageId, payload: payload)
        let data = try encoder.encode(message)
        guard let encodedMessage = String(data: data, encoding: .utf8) else {
            throw GatewayError(
                code: "ENCODE_ERROR",
                message: "Failed to encode gateway message as UTF-8.",
                details: nil
            )
        }
        let timeoutNanos = requestTimeoutNanoseconds(timeoutSec: timeoutSec)

        return try await withUnsafeThrowingContinuation { continuation in
            pendingRequests[messageId] = PendingRequest(continuation: continuation)

            Task { [weak self] in
                await self?.sendPendingRequest(messageId: messageId, encodedMessage: encodedMessage)
            }

            // Schedule timeout
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: timeoutNanos)
                await self?.timeoutRequest(messageId)
            }
        }
    }

    func decodeOrchestratorResult<T: Decodable>(
        _ command: OrchestratorCommandResult,
        as type: T.Type
    ) throws -> T {
        guard command.status == "completed" else {
            if let error = command.error {
                throw error
            }
            throw GatewayError(
                code: "FAILED_PRECONDITION",
                message: "Gateway command did not complete successfully.",
                details: nil
            )
        }

        guard let payload = command.result else {
            throw GatewayError(
                code: "FAILED_PRECONDITION",
                message: "Gateway command returned no payload.",
                details: nil
            )
        }

        let jsonObject = payload.mapValues(\.value)
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        return try decoder.decode(type, from: data)
    }

    func requestTimeoutNanoseconds(timeoutSec: TimeInterval?) -> UInt64 {
        let effectiveTimeout = max(timeoutSec ?? options.requestTimeoutSec, 0.1)
        return UInt64((effectiveTimeout * 1_000_000_000).rounded())
    }

    func timeoutRequest(_ messageId: String) {
        guard let pending = pendingRequests.removeValue(forKey: messageId) else { return }
        pending.continuation.resume(throwing: GatewayError(
            code: "TIMEOUT",
            message: "Request timed out",
            details: nil
        ))
    }

    func sendPendingRequest(messageId: String, encodedMessage: String) async {
        guard let ws = task else {
            failPendingRequest(
                messageId,
                error: GatewayError(
                    code: "NOT_CONNECTED",
                    message: "WebSocket not connected",
                    details: nil
                )
            )
            return
        }

        do {
            try await ws.send(.string(encodedMessage))
        } catch {
            failPendingRequest(messageId, error: error)
        }
    }

    func failPendingRequest(_ messageId: String, error: Error) {
        guard let pending = pendingRequests.removeValue(forKey: messageId) else { return }
        pending.continuation.resume(throwing: error)
    }
}
