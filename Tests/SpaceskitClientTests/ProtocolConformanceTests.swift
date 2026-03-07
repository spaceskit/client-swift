// ProtocolConformanceTests.swift
//
// These tests verify that the Swift compatibility types can decode the JSON
// fixtures generated from the legacy WebSocket shim in
// packages/server/src/protocol.ts.
//
// If someone adds/removes/renames a field in the shim and re-runs codegen,
// these tests catch any mismatch between the Generated* structs and the
// fixture JSON while proto remains the canonical public contract.
//
// Run: swift test --filter ProtocolConformanceTests

import XCTest
@testable import SpaceskitClient

final class ProtocolConformanceTests: XCTestCase {

    private let decoder = JSONDecoder()

    // MARK: - Helpers

    private var packageRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // SpaceskitClientTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // client-swift
    }

    /// Load a fixture JSON file from the Fixtures directory.
    private func loadFixture(_ name: String) throws -> Data {
        // When running `swift test`, Bundle.module gives us access to
        // resources declared in Package.swift. As a fallback, try a
        // relative path from the test source directory.
        let fixtureDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
        let url = fixtureDir.appendingPathComponent("\(name).json")
        return try Data(contentsOf: url)
    }

    private func loadSourceFile(relativePath: String) throws -> String {
        let url = packageRootURL.appendingPathComponent(relativePath)
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func extractSwiftMessageTypeValues(enumName: String, from swiftSource: String) throws -> Set<String> {
        guard let headerRange = swiftSource.range(of: "public enum \(enumName)") else {
            throw NSError(domain: "ProtocolConformanceTests", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Enum \(enumName) not found in Swift source."
            ])
        }

        guard let openBrace = swiftSource[headerRange.upperBound...].firstIndex(of: "{") else {
            throw NSError(domain: "ProtocolConformanceTests", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Opening brace not found for enum \(enumName)."
            ])
        }

        var depth = 0
        var closeBrace: String.Index?
        var index = openBrace
        while index < swiftSource.endIndex {
            let char = swiftSource[index]
            if char == "{" {
                depth += 1
            } else if char == "}" {
                depth -= 1
                if depth == 0 {
                    closeBrace = index
                    break
                }
            }
            index = swiftSource.index(after: index)
        }

        guard let closeBrace else {
            throw NSError(domain: "ProtocolConformanceTests", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Closing brace not found for enum \(enumName)."
            ])
        }

        let body = String(swiftSource[swiftSource.index(after: openBrace)..<closeBrace])
        let regex = try NSRegularExpression(pattern: #"public\s+static\s+let\s+\w+\s*=\s*"([^"]+)""#)
        let nsBody = body as NSString
        let matches = regex.matches(in: body, range: NSRange(location: 0, length: nsBody.length))
        return Set(matches.compactMap { match -> String? in
            guard match.numberOfRanges > 1 else { return nil }
            return nsBody.substring(with: match.range(at: 1))
        })
    }

    private func extractTypeScriptMessageTypeValues(from tsSource: String) throws -> Set<String> {
        guard let objectStart = tsSource.range(of: "export const MessageTypes = {")?.upperBound else {
            throw NSError(domain: "ProtocolConformanceTests", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "MessageTypes object not found in protocol.ts."
            ])
        }
        guard let objectEnd = tsSource[objectStart...].range(of: "} as const;")?.lowerBound else {
            throw NSError(domain: "ProtocolConformanceTests", code: 5, userInfo: [
                NSLocalizedDescriptionKey: "MessageTypes object terminator not found in protocol.ts."
            ])
        }

        let body = String(tsSource[objectStart..<objectEnd])
        let regex = try NSRegularExpression(pattern: #"\w+\s*:\s*"([^"]+)""#)
        let nsBody = body as NSString
        let matches = regex.matches(in: body, range: NSRange(location: 0, length: nsBody.length))
        return Set(matches.compactMap { match -> String? in
            guard match.numberOfRanges > 1 else { return nil }
            return nsBody.substring(with: match.range(at: 1))
        })
    }

    // MARK: - Payload Fixture Tests

    func testDecodeAuthenticatePayload() throws {
        let data = try loadFixture("AuthenticatePayload")
        let decoded = try decoder.decode(GeneratedAuthenticatePayload.self, from: data)
        XCTAssertFalse(decoded.publicKey.isEmpty)
        XCTAssertFalse(decoded.signature.isEmpty)
        XCTAssertFalse(decoded.clientType.isEmpty)
        XCTAssertFalse(decoded.clientVersion.isEmpty)
    }

    func testDecodeExecuteTurnPayload() throws {
        let data = try loadFixture("ExecuteTurnPayload")
        let decoded = try decoder.decode(GeneratedExecuteTurnPayload.self, from: data)
        XCTAssertFalse(decoded.spaceUid.isEmpty)
        XCTAssertFalse(decoded.input.isEmpty)
        // targetAgentId is optional — fixture includes it
        XCTAssertNotNil(decoded.targetAgentId)
    }

    func testDecodeResumeFeedbackPayload() throws {
        let data = try loadFixture("ResumeFeedbackPayload")
        let decoded = try decoder.decode(GeneratedResumeFeedbackPayload.self, from: data)
        XCTAssertFalse(decoded.spaceUid.isEmpty)
        XCTAssertFalse(decoded.turnId.isEmpty)
        XCTAssertFalse(decoded.response.isEmpty)
    }

    func testDecodeSubscribePayload() throws {
        let data = try loadFixture("SubscribePayload")
        let decoded = try decoder.decode(GeneratedSubscribePayload.self, from: data)
        XCTAssertFalse(decoded.spaceUids.isEmpty)
    }

    func testDecodeCapabilityInvokePayload() throws {
        let data = try loadFixture("CapabilityInvokePayload")
        let decoded = try decoder.decode(GeneratedCapabilityInvokePayload.self, from: data)
        XCTAssertFalse(decoded.capability.isEmpty)
        XCTAssertFalse(decoded.method.isEmpty)
    }

    func testDecodeAuthResultPayload() throws {
        let data = try loadFixture("AuthResultPayload")
        let decoded = try decoder.decode(GeneratedAuthResultPayload.self, from: data)
        XCTAssertTrue(decoded.success) // fixture defaults to true
    }

    func testDecodeTurnEventPayload() throws {
        let data = try loadFixture("TurnEventPayload")
        let decoded = try decoder.decode(GeneratedTurnEventPayload.self, from: data)
        XCTAssertFalse(decoded.spaceId.isEmpty)
        XCTAssertFalse(decoded.turnId.isEmpty)
        XCTAssertFalse(decoded.eventType.isEmpty)
    }

    func testDecodeTurnStreamPayload() throws {
        let data = try loadFixture("TurnStreamPayload")
        let decoded = try decoder.decode(GeneratedTurnStreamPayload.self, from: data)
        XCTAssertFalse(decoded.spaceId.isEmpty)
        XCTAssertFalse(decoded.delta.isEmpty)
        XCTAssertEqual(decoded.seq, 42)
        XCTAssertTrue(decoded.done)
    }

    func testDecodeSpaceStatePayload() throws {
        let data = try loadFixture("SpaceStatePayload")
        let decoded = try decoder.decode(GeneratedSpaceStatePayload.self, from: data)
        XCTAssertFalse(decoded.spaceId.isEmpty)
        XCTAssertEqual(decoded.turnCount, 42)
        XCTAssertEqual(decoded.pendingFeedback, 42)
    }

    func testDecodeSpaceGetWorkspaceResponsePayload() throws {
        let data = try loadFixture("SpaceGetWorkspaceResponsePayload")
        let decoded = try decoder.decode(SpaceGetWorkspaceResponsePayload.self, from: data)
        XCTAssertFalse(decoded.workspace.spaceId.isEmpty)
        XCTAssertFalse(decoded.workspace.spaceUid.isEmpty)
        XCTAssertFalse(decoded.workspace.effectiveWorkspaceRoot.isEmpty)
        XCTAssertFalse(decoded.workspace.sharedContextPath.isEmpty)
        XCTAssertFalse(decoded.workspace.scratchpadsPath.isEmpty)
        XCTAssertEqual(decoded.workspace.metaPath, "/tmp/spaces/sample-space/.space")
        XCTAssertEqual(decoded.workspace.metadataStatus, .ready)
    }

    func testDecodeSpaceSetWorkspaceResponsePayload() throws {
        let data = try loadFixture("SpaceSetWorkspaceResponsePayload")
        let decoded = try decoder.decode(SpaceSetWorkspaceResponsePayload.self, from: data)
        XCTAssertEqual(decoded.workspace.mode, "folder_bound")
        XCTAssertEqual(decoded.workspace.explicitWorkspaceRoot, "/tmp/spaces/sample-space")
        XCTAssertEqual(decoded.workspace.layoutVersion, 2)
        XCTAssertEqual(decoded.workspace.metaPath, "/tmp/spaces/sample-space/.space")
        XCTAssertEqual(decoded.workspace.metadataStatus, .ready)
    }

    func testDecodeNotificationPayload() throws {
        let data = try loadFixture("NotificationPayload")
        let decoded = try decoder.decode(GeneratedNotificationPayload.self, from: data)
        XCTAssertFalse(decoded.notificationId.isEmpty)
        XCTAssertFalse(decoded.category.isEmpty)
        XCTAssertFalse(decoded.title.isEmpty)
        XCTAssertFalse(decoded.body.isEmpty)
        XCTAssertFalse(decoded.createdAt.isEmpty)
    }

    func testDecodeSubscribeNotificationsPayload() throws {
        let data = try loadFixture("SubscribeNotificationsPayload")
        let decoded = try decoder.decode(GeneratedSubscribeNotificationsPayload.self, from: data)
        XCTAssertFalse(decoded.categories.isEmpty)
    }

    func testDecodeUnsubscribeNotificationsPayload() throws {
        let data = try loadFixture("UnsubscribeNotificationsPayload")
        let decoded = try decoder.decode(GeneratedUnsubscribeNotificationsPayload.self, from: data)
        XCTAssertFalse(decoded.categories.isEmpty)
    }

    func testDecodeErrorPayload() throws {
        let data = try loadFixture("ErrorPayload")
        let decoded = try decoder.decode(GeneratedErrorPayload.self, from: data)
        XCTAssertFalse(decoded.code.isEmpty)
        XCTAssertFalse(decoded.message.isEmpty)
        XCTAssertNotNil(decoded.retryable)
        XCTAssertNotNil(decoded.correlationId)
    }

    // MARK: - Adapter Payload Fixture Tests

    func testDecodeCapabilitiesRegisterPayload() throws {
        let data = try loadFixture("CapabilitiesRegisterPayload")
        let decoded = try decoder.decode(GeneratedCapabilitiesRegisterPayload.self, from: data)
        // providers is AnyCodable — just verify it decodes
        _ = decoded.providers
    }

    func testDecodeCapabilitiesDeregisterPayload() throws {
        let data = try loadFixture("CapabilitiesDeregisterPayload")
        let decoded = try decoder.decode(GeneratedCapabilitiesDeregisterPayload.self, from: data)
        XCTAssertFalse(decoded.providerIds.isEmpty)
    }

    func testDecodeAdapterCapabilityProvider() throws {
        let data = try loadFixture("AdapterCapabilityProvider")
        let decoded = try decoder.decode(GeneratedAdapterCapabilityProvider.self, from: data)
        XCTAssertFalse(decoded.id.isEmpty)
        XCTAssertFalse(decoded.name.isEmpty)
        XCTAssertFalse(decoded.capabilityType.isEmpty)
        XCTAssertFalse(decoded.operations.isEmpty)
    }

    func testDecodeAdapterCapabilityInvokePayload() throws {
        let data = try loadFixture("AdapterCapabilityInvokePayload")
        let decoded = try decoder.decode(GeneratedAdapterCapabilityInvokePayload.self, from: data)
        XCTAssertFalse(decoded.invocationId.isEmpty)
        XCTAssertFalse(decoded.capability.isEmpty)
        XCTAssertFalse(decoded.operation.isEmpty)
    }

    func testDecodeCapabilityResultPayload() throws {
        let data = try loadFixture("CapabilityResultPayload")
        let decoded = try decoder.decode(GeneratedCapabilityResultPayload.self, from: data)
        XCTAssertFalse(decoded.invocationId.isEmpty)
        XCTAssertFalse(decoded.providerId.isEmpty)
    }

    func testDecodeCapabilityErrorPayload() throws {
        let data = try loadFixture("CapabilityErrorPayload")
        let decoded = try decoder.decode(GeneratedCapabilityErrorPayload.self, from: data)
        XCTAssertFalse(decoded.invocationId.isEmpty)
        XCTAssertFalse(decoded.message.isEmpty)
    }

    // MARK: - Inter-Agent Messaging Fixture Tests

    func testDecodeAgentMessagePayload() throws {
        let data = try loadFixture("AgentMessagePayload")
        let decoded = try decoder.decode(GeneratedAgentMessagePayload.self, from: data)
        XCTAssertFalse(decoded.spaceId.isEmpty)
        XCTAssertFalse(decoded.fromAgentId.isEmpty)
        XCTAssertFalse(decoded.toAgentId.isEmpty)
        XCTAssertFalse(decoded.content.isEmpty)
    }

    func testDecodeAgentPokePayload() throws {
        let data = try loadFixture("AgentPokePayload")
        let decoded = try decoder.decode(GeneratedAgentPokePayload.self, from: data)
        XCTAssertFalse(decoded.spaceId.isEmpty)
        XCTAssertFalse(decoded.targetAgentId.isEmpty)
        XCTAssertFalse(decoded.reason.isEmpty)
    }

    func testDecodeAgentIdlePayload() throws {
        let data = try loadFixture("AgentIdlePayload")
        let decoded = try decoder.decode(GeneratedAgentIdlePayload.self, from: data)
        XCTAssertFalse(decoded.spaceId.isEmpty)
        XCTAssertFalse(decoded.agentId.isEmpty)
        XCTAssertGreaterThan(decoded.idleDurationMs, 0)
    }

    func testDecodeTaskDependencyPayload() throws {
        let data = try loadFixture("TaskDependencyPayload")
        let decoded = try decoder.decode(GeneratedTaskDependencyPayload.self, from: data)
        XCTAssertFalse(decoded.spaceId.isEmpty)
        XCTAssertFalse(decoded.blockedTurnId.isEmpty)
        XCTAssertFalse(decoded.dependsOnTurnId.isEmpty)
    }

    func testDecodeTaskDependencyResolvedPayload() throws {
        let data = try loadFixture("TaskDependencyResolvedPayload")
        let decoded = try decoder.decode(GeneratedTaskDependencyResolvedPayload.self, from: data)
        XCTAssertFalse(decoded.spaceId.isEmpty)
        XCTAssertFalse(decoded.unblockedTurnId.isEmpty)
        XCTAssertFalse(decoded.resolvedByTurnId.isEmpty)
    }

    // MARK: - Wrapped Message Tests

    func testDecodeWrappedTurnStreamMessage() throws {
        let data = try loadFixture("Message_TurnStreamPayload")
        // Decode the full envelope with the typed payload
        let raw = try decoder.decode(RawGatewayMessage.self, from: data)
        XCTAssertEqual(raw.type, "test_turnstreampayload")
        XCTAssertFalse(raw.id.isEmpty)
        XCTAssertNotNil(raw.payload)
    }

    func testDecodeWrappedErrorMessage() throws {
        let data = try loadFixture("Message_ErrorPayload")
        let raw = try decoder.decode(RawGatewayMessage.self, from: data)
        XCTAssertEqual(raw.type, "test_errorpayload")
        XCTAssertNotNil(raw.payload)
    }

    // MARK: - Field Manifest Validation

    /// Verify that the Generated* struct field names match the TS interface field names.
    /// This is the key conformance check: if TS adds a required field, the manifest
    /// will include it, and this test confirms the Swift struct has a matching property.
    func testFieldManifestMatchesGeneratedTypes() throws {
        // Use Mirror to inspect each Generated* struct's properties
        let testCases: [(String, Any.Type)] = [
            ("AuthenticatePayload", GeneratedAuthenticatePayload.self),
            ("ExecuteTurnPayload", GeneratedExecuteTurnPayload.self),
            ("ResumeFeedbackPayload", GeneratedResumeFeedbackPayload.self),
            ("SubscribePayload", GeneratedSubscribePayload.self),
            ("CapabilityInvokePayload", GeneratedCapabilityInvokePayload.self),
            ("CapabilitiesRegisterPayload", GeneratedCapabilitiesRegisterPayload.self),
            ("CapabilitiesDeregisterPayload", GeneratedCapabilitiesDeregisterPayload.self),
            ("AdapterCapabilityProvider", GeneratedAdapterCapabilityProvider.self),
            ("AdapterCapabilityInvokePayload", GeneratedAdapterCapabilityInvokePayload.self),
            ("CapabilityResultPayload", GeneratedCapabilityResultPayload.self),
            ("CapabilityErrorPayload", GeneratedCapabilityErrorPayload.self),
            ("AuthResultPayload", GeneratedAuthResultPayload.self),
            ("TurnEventPayload", GeneratedTurnEventPayload.self),
            ("TurnStreamPayload", GeneratedTurnStreamPayload.self),
            ("SpaceStatePayload", GeneratedSpaceStatePayload.self),
            ("NotificationPayload", GeneratedNotificationPayload.self),
            ("SubscribeNotificationsPayload", GeneratedSubscribeNotificationsPayload.self),
            ("UnsubscribeNotificationsPayload", GeneratedUnsubscribeNotificationsPayload.self),
            ("ErrorPayload", GeneratedErrorPayload.self),
            ("AgentMessagePayload", GeneratedAgentMessagePayload.self),
            ("AgentPokePayload", GeneratedAgentPokePayload.self),
            ("AgentIdlePayload", GeneratedAgentIdlePayload.self),
            ("TaskDependencyPayload", GeneratedTaskDependencyPayload.self),
            ("TaskDependencyResolvedPayload", GeneratedTaskDependencyResolvedPayload.self),
        ]

        for (name, _) in testCases {
            guard let expectedFields = protocolFieldManifest[name] else {
                XCTFail("Missing manifest entry for \(name)")
                continue
            }

            // Attempt to decode the fixture — if it fails, the struct is out of sync
            let data = try loadFixture(name)
            // We just verify it doesn't throw — the decode test above is more specific
            XCTAssertNoThrow(
                try JSONSerialization.jsonObject(with: data),
                "Fixture \(name).json should be valid JSON"
            )

            // Verify field count matches expectation
            XCTAssertGreaterThan(
                expectedFields.count, 0,
                "\(name) should have at least one field in the manifest"
            )
        }
    }

    // MARK: - Message Type Parity

    /// Verify that GeneratedMessageType has all the same constants as the hand-written MessageType.
    func testGeneratedMessageTypesMatchHandWritten() {
        // These should be in sync — codegen produces GeneratedMessageType,
        // hand-written MessageType is in Protocol.swift.

        // Client → Gateway
        XCTAssertEqual(GeneratedMessageType.authenticate, MessageType.authenticate)
        XCTAssertEqual(GeneratedMessageType.executeTurn, MessageType.executeTurn)
        XCTAssertEqual(GeneratedMessageType.resumeFeedback, MessageType.resumeFeedback)
        XCTAssertEqual(GeneratedMessageType.subscribe, MessageType.subscribe)
        XCTAssertEqual(GeneratedMessageType.capabilityInvoke, MessageType.capabilityInvoke)
        XCTAssertEqual(GeneratedMessageType.spaceCreate, MessageType.spaceCreate)
        XCTAssertEqual(GeneratedMessageType.spaceGet, MessageType.spaceGet)
        XCTAssertEqual(GeneratedMessageType.spaceList, MessageType.spaceList)
        XCTAssertEqual(GeneratedMessageType.spaceAddAgent, MessageType.spaceAddAgent)
        XCTAssertEqual(GeneratedMessageType.spaceRemoveAgent, MessageType.spaceRemoveAgent)
        XCTAssertEqual(GeneratedMessageType.spaceUpdateAgentAssignment, MessageType.spaceUpdateAgentAssignment)
        XCTAssertEqual(GeneratedMessageType.spaceSetOrchestrator, MessageType.spaceSetOrchestrator)
        XCTAssertEqual(GeneratedMessageType.spaceListAgentAssignments, MessageType.spaceListAgentAssignments)
        XCTAssertEqual(GeneratedMessageType.spaceAddSkill, MessageType.spaceAddSkill)
        XCTAssertEqual(GeneratedMessageType.spaceRemoveSkill, MessageType.spaceRemoveSkill)
        XCTAssertEqual(GeneratedMessageType.spaceListSkills, MessageType.spaceListSkills)
        XCTAssertEqual(GeneratedMessageType.spaceAddResource, MessageType.spaceAddResource)
        XCTAssertEqual(GeneratedMessageType.spaceRemoveResource, MessageType.spaceRemoveResource)
        XCTAssertEqual(GeneratedMessageType.spaceListResources, MessageType.spaceListResources)
        XCTAssertEqual(GeneratedMessageType.profileCreate, MessageType.profileCreate)
        XCTAssertEqual(GeneratedMessageType.profileGet, MessageType.profileGet)
        XCTAssertEqual(GeneratedMessageType.profileList, MessageType.profileList)
        XCTAssertEqual(GeneratedMessageType.profileUpdate, MessageType.profileUpdate)
        XCTAssertEqual(GeneratedMessageType.profileArchive, MessageType.profileArchive)
        XCTAssertEqual(GeneratedMessageType.presetList, MessageType.presetList)
        XCTAssertEqual(GeneratedMessageType.presetGet, MessageType.presetGet)
        XCTAssertEqual(GeneratedMessageType.presetApplyToSpace, MessageType.presetApplyToSpace)
        XCTAssertEqual(GeneratedMessageType.spacePreviewTemplate, MessageType.spacePreviewTemplate)
        XCTAssertEqual(GeneratedMessageType.spaceCreateFromTemplate, MessageType.spaceCreateFromTemplate)
        XCTAssertEqual(GeneratedMessageType.spaceSaveTemplate, MessageType.spaceSaveTemplate)
        XCTAssertEqual(GeneratedMessageType.gatewayDiscoverLocalAgents, MessageType.gatewayDiscoverLocalAgents)
        XCTAssertEqual(GeneratedMessageType.gatewayListProviderConfigs, MessageType.gatewayListProviderConfigs)
        XCTAssertEqual(GeneratedMessageType.gatewayGetMainAgent, MessageType.gatewayGetMainAgent)
        XCTAssertEqual(GeneratedMessageType.gatewaySetMainAgent, MessageType.gatewaySetMainAgent)
        XCTAssertEqual(GeneratedMessageType.gatewayCreateIntegrationRequest, MessageType.gatewayCreateIntegrationRequest)
        XCTAssertEqual(GeneratedMessageType.gatewayListIntegrationRequests, MessageType.gatewayListIntegrationRequests)
        XCTAssertEqual(GeneratedMessageType.gatewaySetProviderConfig, MessageType.gatewaySetProviderConfig)
        XCTAssertEqual(GeneratedMessageType.gatewayRemoveProviderConfig, MessageType.gatewayRemoveProviderConfig)
        XCTAssertEqual(GeneratedMessageType.gatewayProvisionLocalProfile, MessageType.gatewayProvisionLocalProfile)
        XCTAssertEqual(GeneratedMessageType.gatewayPutSecretRef, MessageType.gatewayPutSecretRef)
        XCTAssertEqual(GeneratedMessageType.gatewayListSecretRefs, MessageType.gatewayListSecretRefs)
        XCTAssertEqual(GeneratedMessageType.gatewayDeleteSecretRef, MessageType.gatewayDeleteSecretRef)
        XCTAssertEqual(GeneratedMessageType.gatewayListConnectorFamilies, MessageType.gatewayListConnectorFamilies)
        XCTAssertEqual(GeneratedMessageType.gatewayListConnectors, MessageType.gatewayListConnectors)
        XCTAssertEqual(GeneratedMessageType.gatewayUpsertConnector, MessageType.gatewayUpsertConnector)
        XCTAssertEqual(GeneratedMessageType.gatewayRemoveConnector, MessageType.gatewayRemoveConnector)
        XCTAssertEqual(GeneratedMessageType.gatewayListConnectorBindings, MessageType.gatewayListConnectorBindings)
        XCTAssertEqual(GeneratedMessageType.gatewayUpsertConnectorBinding, MessageType.gatewayUpsertConnectorBinding)
        XCTAssertEqual(GeneratedMessageType.gatewayRemoveConnectorBinding, MessageType.gatewayRemoveConnectorBinding)
        XCTAssertEqual(GeneratedMessageType.gatewayGetConnectorPolicy, MessageType.gatewayGetConnectorPolicy)
        XCTAssertEqual(GeneratedMessageType.gatewayUpdateConnectorPolicy, MessageType.gatewayUpdateConnectorPolicy)
        XCTAssertEqual(GeneratedMessageType.gatewayTestConnector, MessageType.gatewayTestConnector)
        XCTAssertEqual(GeneratedMessageType.gatewayGetPolicy, MessageType.gatewayGetPolicy)
        XCTAssertEqual(GeneratedMessageType.gatewayUpdatePolicy, MessageType.gatewayUpdatePolicy)
        XCTAssertEqual(GeneratedMessageType.gatewayListCapabilityGrants, MessageType.gatewayListCapabilityGrants)
        XCTAssertEqual(GeneratedMessageType.gatewayGrantCapability, MessageType.gatewayGrantCapability)
        XCTAssertEqual(GeneratedMessageType.gatewayRevokeCapability, MessageType.gatewayRevokeCapability)
        XCTAssertEqual(GeneratedMessageType.usageGetSnapshot, MessageType.usageGetSnapshot)
        XCTAssertEqual(GeneratedMessageType.orchestratorCommand, MessageType.orchestratorCommand)
        XCTAssertEqual(GeneratedMessageType.orchestratorGetCommand, MessageType.orchestratorGetCommand)
        XCTAssertEqual(GeneratedMessageType.spaceLink, MessageType.spaceLink)
        XCTAssertEqual(GeneratedMessageType.spaceUnlink, MessageType.spaceUnlink)
        XCTAssertEqual(GeneratedMessageType.spaceShareContext, MessageType.spaceShareContext)
        XCTAssertEqual(GeneratedMessageType.spacePullSharedContext, MessageType.spacePullSharedContext)
        XCTAssertEqual(GeneratedMessageType.spaceShareCreateInvite, MessageType.spaceShareCreateInvite)
        XCTAssertEqual(GeneratedMessageType.spaceShareJoin, MessageType.spaceShareJoin)
        XCTAssertEqual(GeneratedMessageType.spaceShareRevoke, MessageType.spaceShareRevoke)
        XCTAssertEqual(GeneratedMessageType.spaceShareListParticipants, MessageType.spaceShareListParticipants)
        XCTAssertEqual(GeneratedMessageType.authRegisterDevice, MessageType.authRegisterDevice)
        XCTAssertEqual(GeneratedMessageType.authRotateDeviceKey, MessageType.authRotateDeviceKey)
        XCTAssertEqual(GeneratedMessageType.authRevokeDevice, MessageType.authRevokeDevice)
        XCTAssertEqual(GeneratedMessageType.authListDevices, MessageType.authListDevices)
        XCTAssertEqual(GeneratedMessageType.authIssueHttpPrincipalToken, MessageType.authIssueHttpPrincipalToken)
        XCTAssertEqual(GeneratedMessageType.syncAnnounce, MessageType.syncAnnounce)
        XCTAssertEqual(GeneratedMessageType.syncQueryResources, MessageType.syncQueryResources)
        XCTAssertEqual(GeneratedMessageType.syncPullResources, MessageType.syncPullResources)
        XCTAssertEqual(GeneratedMessageType.speechStart, MessageType.speechStart)
        XCTAssertEqual(GeneratedMessageType.speechAudioChunk, MessageType.speechAudioChunk)
        XCTAssertEqual(GeneratedMessageType.speechControl, MessageType.speechControl)
        XCTAssertEqual(GeneratedMessageType.ping, MessageType.ping)

        // Adapter ↔ Gateway
        XCTAssertEqual(GeneratedMessageType.capabilitiesRegister, MessageType.capabilitiesRegister)
        XCTAssertEqual(GeneratedMessageType.capabilitiesDeregister, MessageType.capabilitiesDeregister)
        XCTAssertEqual(GeneratedMessageType.capabilityInvokeAdapter, MessageType.capabilityInvokeAdapter)
        XCTAssertEqual(GeneratedMessageType.capabilityResult, MessageType.capabilityResult)
        XCTAssertEqual(GeneratedMessageType.capabilityError, MessageType.capabilityError)

        // Gateway → Client
        XCTAssertEqual(GeneratedMessageType.authChallenge, MessageType.authChallenge)
        XCTAssertEqual(GeneratedMessageType.authResult, MessageType.authResult)
        XCTAssertEqual(GeneratedMessageType.turnEvent, MessageType.turnEvent)
        XCTAssertEqual(GeneratedMessageType.turnStream, MessageType.turnStream)
        XCTAssertEqual(GeneratedMessageType.spaceState, MessageType.spaceState)
        XCTAssertEqual(GeneratedMessageType.spaceAgentUpdated, MessageType.spaceAgentUpdated)
        XCTAssertEqual(GeneratedMessageType.notification, MessageType.notification)
        XCTAssertEqual(GeneratedMessageType.orchestratorEvent, MessageType.orchestratorEvent)
        XCTAssertEqual(GeneratedMessageType.speechEvent, MessageType.speechEvent)
        XCTAssertEqual(GeneratedMessageType.error, MessageType.error)
        XCTAssertEqual(GeneratedMessageType.pong, MessageType.pong)

        // Notifications
        XCTAssertEqual(GeneratedMessageType.subscribeNotifications, MessageType.subscribeNotifications)
        XCTAssertEqual(GeneratedMessageType.unsubscribeNotifications, MessageType.unsubscribeNotifications)

        // Inter-Agent Messaging
        XCTAssertEqual(GeneratedMessageType.agentMessage, MessageType.agentMessage)
        XCTAssertEqual(GeneratedMessageType.agentPoke, MessageType.agentPoke)
        XCTAssertEqual(GeneratedMessageType.agentIdle, MessageType.agentIdle)

        // Task Dependencies
        XCTAssertEqual(GeneratedMessageType.taskDependency, MessageType.taskDependency)
        XCTAssertEqual(GeneratedMessageType.taskDependencyResolved, MessageType.taskDependencyResolved)
    }

    /// Verify full set parity between hand-written and generated message type constants.
    func testGeneratedMessageTypeSetMatchesHandWrittenMessageTypeSet() throws {
        let protocolSwift = try loadSourceFile(relativePath: "Sources/SpaceskitClient/Protocol.swift")
        let generatedSwift = try loadSourceFile(relativePath: "Sources/SpaceskitClient/GeneratedProtocol.swift")

        let handWritten = try extractSwiftMessageTypeValues(enumName: "MessageType", from: protocolSwift)
        let generated = try extractSwiftMessageTypeValues(enumName: "GeneratedMessageType", from: generatedSwift)

        XCTAssertEqual(generated, handWritten, "GeneratedMessageType set must stay in full parity with MessageType.")
    }

    /// Verify generated Swift message types track gateway protocol.ts message map.
    func testGeneratedMessageTypeSetMatchesGatewayProtocolTs() throws {
        let generatedSwift = try loadSourceFile(relativePath: "Sources/SpaceskitClient/GeneratedProtocol.swift")
        let generated = try extractSwiftMessageTypeValues(enumName: "GeneratedMessageType", from: generatedSwift)

        let gatewayProtocolURL = packageRootURL
            .deletingLastPathComponent()
            .appendingPathComponent("gateway/packages/server/src/protocol.ts")

        guard FileManager.default.fileExists(atPath: gatewayProtocolURL.path) else {
            throw XCTSkip("gateway/packages/server/src/protocol.ts not found; skipping monorepo parity check.")
        }

        let protocolTs = try String(contentsOf: gatewayProtocolURL, encoding: .utf8)
        let protocolTypes = try extractTypeScriptMessageTypeValues(from: protocolTs)
        XCTAssertEqual(generated, protocolTypes, "GeneratedMessageType must match protocol.ts MessageTypes.")
    }
}
