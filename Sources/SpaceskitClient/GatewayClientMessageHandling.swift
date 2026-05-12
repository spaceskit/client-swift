// GatewayClient inbound message handling and auth.

import Foundation

extension GatewayClient {
    // MARK: - Private: Receive

    func receiveLoop() async {
        guard let ws = task else { return }

        while !Task.isCancelled {
            do {
                let message = try await ws.receive()

                switch message {
                case .string(let text):
                    guard let data = text.data(using: .utf8) else { continue }
                    await handleMessage(data)
                case .data(let data):
                    await handleMessage(data)
                @unknown default:
                    break
                }
            } catch {
                if !Task.isCancelled {
                    await handleDisconnect()
                }
                return
            }
        }
    }

    func handleMessage(_ data: Data) async {
        do {
            let envelope = try decoder.decode(MessageEnvelope.self, from: data)

            // Check for reply to pending request
            if let replyTo = envelope.replyTo, let pending = pendingRequests.removeValue(forKey: replyTo) {
                let result: Result<Data, Error>
                if envelope.type == MessageType.error {
                    do {
                        let errorPayload = try decoder.decode(
                            GatewayMessage<GatewayError>.self,
                            from: data
                        )
                        result = .failure(errorPayload.payload)
                    } catch {
                        result = .failure(GatewayError(
                            code: "PARSE_ERROR",
                            message: "Failed to decode gateway error payload: \(error.localizedDescription)",
                            details: nil
                        ))
                    }
                } else {
                    do {
                        // Extract the "payload" value directly from the raw JSON
                        // instead of round-tripping through AnyCodable encode,
                        // which can cause heap corruption with bridged Foundation types.
                        let payloadData = try Self.extractPayloadData(from: data)
                        result = .success(payloadData)
                    } catch {
                        result = .failure(GatewayError(
                            code: "PARSE_ERROR",
                            message: "Failed to decode gateway response payload: \(error.localizedDescription)",
                            details: nil
                        ))
                    }
                }

                switch result {
                case .success(let payloadData):
                    pending.continuation.resume(returning: payloadData)
                case .failure(let error):
                    pending.continuation.resume(throwing: error)
                }
                return
            }

            // Handle unsolicited messages
            switch envelope.type {
            case MessageType.authChallenge:
                let msg = try decoder.decode(GatewayMessage<AuthChallengePayload>.self, from: data)
                await handleAuthChallenge(msg.payload)

            case MessageType.authResult:
                let msg = try decoder.decode(GatewayMessage<AuthResultPayload>.self, from: data)
                if msg.payload.success {
                    // Challenge/response finished successfully.
                    setState(.connected)
                } else {
                    emit(.error(GatewayError(
                        code: "AUTH_FAILED",
                        message: msg.payload.reason ?? "Authentication failed",
                        details: nil
                    )))
                    disconnect()
                }

            case MessageType.turnEvent:
                let msg = try decoder.decode(GatewayMessage<TurnEvent>.self, from: data)
                emit(.turnEvent(msg.payload))

            case MessageType.turnStream:
                let msg = try decoder.decode(GatewayMessage<TurnStream>.self, from: data)
                emit(.turnStream(msg.payload))

            case MessageType.spaceState:
                let msg = try decoder.decode(GatewayMessage<SpaceState>.self, from: data)
                emit(.spaceState(msg.payload))

            case MessageType.spaceAgentUpdated:
                let msg = try decoder.decode(GatewayMessage<SpaceAgentUpdatedEvent>.self, from: data)
                emit(.spaceAgentUpdated(msg.payload))

            case MessageType.notification:
                let msg = try decoder.decode(GatewayMessage<GatewayNotification>.self, from: data)
                emit(.notification(msg.payload))

            case MessageType.appNavigate:
                let msg = try decoder.decode(GatewayMessage<AppNavigateEvent>.self, from: data)
                emit(.appNavigate(msg.payload))

            case MessageType.appConciergeActionRequest:
                let msg = try decoder.decode(GatewayMessage<AppConciergeActionRequestPayload>.self, from: data)
                emit(.conciergeActionRequest(msg.payload))

            case MessageType.capabilityInvokeAdapter:
                let msg = try decoder.decode(GatewayMessage<AdapterCapabilityInvokePayload>.self, from: data)
                emit(.capabilityInvoke(msg.payload))

            case MessageType.agentMessage:
                let msg = try decoder.decode(GatewayMessage<AgentMessage>.self, from: data)
                emit(.agentMessage(msg.payload))

            case MessageType.agentPoke:
                let msg = try decoder.decode(GatewayMessage<AgentPoke>.self, from: data)
                emit(.agentPoke(msg.payload))

            case MessageType.agentIdle:
                let msg = try decoder.decode(GatewayMessage<AgentIdle>.self, from: data)
                emit(.agentIdle(msg.payload))

            case MessageType.taskDependencyResolved:
                let msg = try decoder.decode(GatewayMessage<TaskDependencyResolved>.self, from: data)
                emit(.taskDependencyResolved(msg.payload))

            case MessageType.orchestratorEvent:
                let msg = try decoder.decode(GatewayMessage<OrchestratorEvent>.self, from: data)
                emit(.orchestratorEvent(msg.payload))

            case MessageType.speechEvent:
                let msg = try decoder.decode(GatewayMessage<SpeechSessionEvent>.self, from: data)
                emit(.speechEvent(msg.payload))

            case MessageType.conciergeCallEvent:
                let msg = try decoder.decode(GatewayMessage<ConciergeCallEvent>.self, from: data)
                emit(.conciergeCallEvent(msg.payload))

            case MessageType.error:
                let msg = try decoder.decode(GatewayMessage<GatewayError>.self, from: data)
                handleServerError(msg.payload)

            case MessageType.pong:
                break // Silently handle

            default:
                break
            }
        } catch {
            emit(.error(GatewayError(
                code: "PARSE_ERROR",
                message: "Failed to parse message: \(error.localizedDescription)",
                details: nil
            )))
        }
    }

    // MARK: - Private: Auth

    func handleAuthChallenge(_ payload: AuthChallengePayload) async {
        guard let challenge = payload.challenge, let keyPair = options.authKeyPair else {
            emit(.error(GatewayError(
                code: "AUTH_NO_KEYPAIR",
                message: "Received auth challenge but no key pair configured",
                details: nil
            )))
            disconnect()
            return
        }

        setState(.authenticating)

        do {
            let signature = try signChallenge(challenge, with: keyPair)
            let effectiveDeviceProofSignature: String?
            if let provided = options.deviceProofSignature, !provided.isEmpty {
                effectiveDeviceProofSignature = provided
            } else if
                let deviceId = options.deviceId,
                !deviceId.isEmpty,
                let devicePublicKey = options.devicePublicKey,
                !devicePublicKey.isEmpty,
                devicePublicKey == keyPair.publicKeyBase64
            {
                effectiveDeviceProofSignature = signature
            } else {
                effectiveDeviceProofSignature = nil
            }
            let authPayload = AuthenticatePayload(
                publicKey: keyPair.publicKeyBase64,
                signature: signature,
                clientType: options.clientType,
                clientVersion: options.clientVersion,
                deviceId: options.deviceId,
                devicePublicKey: options.devicePublicKey,
                deviceProofSignature: effectiveDeviceProofSignature
            )
            _ = try await send(type: MessageType.authenticate, payload: authPayload)
        } catch {
            emit(.error(GatewayError(
                code: "AUTH_SIGN_FAILED",
                message: "Failed to sign challenge: \(error.localizedDescription)",
                details: nil
            )))
            disconnect()
        }
    }

    // MARK: - Private: Reconnect

    func handleDisconnect() async {
        receiveTask?.cancel()
        receiveTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil

        // Reject all pending requests so continuations don't leak
        for (_, pending) in pendingRequests {
            pending.continuation.resume(throwing: GatewayError(
                code: "DISCONNECTED",
                message: "Connection lost",
                details: nil
            ))
        }
        pendingRequests.removeAll()

        guard options.reconnect, reconnectAllowed, reconnectAttempts < options.maxReconnectAttempts else {
            setState(.disconnected)
            return
        }

        reconnectAttempts += 1
        setState(.reconnecting(attempt: reconnectAttempts))

        let exponential = options.reconnectIntervalSec * pow(2, Double(reconnectAttempts - 1))
        let delay = min(exponential, options.maxReconnectDelaySec)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        do {
            try await connect()
        } catch {
            emit(.error(GatewayError(
                code: "RECONNECT_FAILED",
                message: "Reconnection attempt \(reconnectAttempts) failed: \(error.localizedDescription)",
                details: nil
            )))
            await handleDisconnect() // Retry
        }
    }
}
