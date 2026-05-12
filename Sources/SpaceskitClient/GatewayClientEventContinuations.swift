// Thread-safe AsyncStream continuation fan-out for GatewayClient events.

import Foundation

// MARK: - Event Continuations (Thread-safe)

/// Manages multiple AsyncStream continuations for broadcasting events.
final class EventContinuations: @unchecked Sendable {
    private var continuations: [UUID: AsyncStream<GatewayEvent>.Continuation] = [:]
    private let lock = NSLock()

    func makeStream() -> AsyncStream<GatewayEvent> {
        let id = UUID()
        return AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            self.withLockVoid {
                self.continuations[id] = continuation
            }

            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.withLockVoid {
                    self.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    func yield(_ event: GatewayEvent) {
        let conts = withLock {
            Array(continuations.values)
        }

        for continuation in conts {
            continuation.yield(event)
        }
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    private func withLockVoid(_ body: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        body()
    }
}
