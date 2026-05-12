// GatewayClient connection and reconnect handling.

import Foundation

extension GatewayClient {
    /// Connect to the Spaceskit.
    public func connect() async throws {
        reconnectAllowed = true
        guard state == .disconnected || {
            if case .reconnecting = state { return true }
            return false
        }() else {
            return // Already connected or connecting
        }

        setState(.connecting)

        let request = URLRequest(url: options.url)
        task = session.webSocketTask(with: request)
        task?.resume()

        // Confirm the WebSocket handshake by attempting the first receive.
        // URLSessionWebSocketTask.resume() is non-blocking — the connection
        // may fail immediately (e.g. -1004 Connection Refused). Only move
        // to .connected once we know the transport is alive.
        guard let ws = task else {
            setState(.disconnected)
            return
        }

        do {
            let firstMessage = try await ws.receive()
            // Handshake succeeded — transport is up, but auth hasn't completed yet.
            // The authResult handler will promote state to .connected
            // after the Ed25519 challenge/response succeeds.
            setState(.authenticating)
            reconnectAttempts = 0

            // Process the first message we already received
            switch firstMessage {
            case .string(let text):
                if let data = text.data(using: .utf8) {
                    await handleMessage(data)
                }
            case .data(let data):
                await handleMessage(data)
            @unknown default:
                break
            }

            // Continue receiving
            receiveTask = Task { [weak self] in
                await self?.receiveLoop()
            }
        } catch {
            // Connection failed during handshake — don't set .connected
            task?.cancel(with: .abnormalClosure, reason: nil)
            task = nil
            throw error
        }
    }

    /// Disconnect from the gateway.
    public func disconnect() {
        reconnectAllowed = false
        receiveTask?.cancel()
        receiveTask = nil
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        setState(.disconnected)

        // Reject all pending requests
        for (_, pending) in pendingRequests {
            pending.continuation.resume(throwing: GatewayError(
                code: "DISCONNECTED",
                message: "Client disconnected",
                details: nil
            ))
        }
        pendingRequests.removeAll()
    }

    /// Current connection state.
    public var connectionState: ConnectionState { state }

    // MARK: - API Methods
}
