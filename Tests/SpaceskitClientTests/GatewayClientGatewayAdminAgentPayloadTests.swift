import XCTest
@testable import SpaceskitClient

final class GatewayClientGatewayAdminAgentPayloadTests: GatewayClientTestCase {

    func testMainAgentPayloadEncodingAndResponseDecoding() throws {
        let getPayload = GatewayGetMainAgentPayload(
            apiVersion: "v1",
            spaceId: "main-space",
            repairIfMissing: true
        )
        let getJSON = try encodeJSONObject(getPayload)
        XCTAssertEqual(getJSON["apiVersion"] as? String, "v1")
        XCTAssertEqual(getJSON["spaceId"] as? String, "main-space")
        XCTAssertEqual(getJSON["repairIfMissing"] as? Bool, true)

        let setPayload = GatewaySetMainAgentPayload(
            apiVersion: "v1",
            spaceId: "main-space",
            selectionMode: .providerModel,
            providerId: "openai",
            modelId: "gpt-4.1",
            sourceAgentDefinitionId: nil,
            applyPersonaInstructions: nil
        )
        let setJSON = try encodeJSONObject(setPayload)
        XCTAssertEqual(setJSON["selectionMode"] as? String, "provider_model")
        XCTAssertEqual(setJSON["providerId"] as? String, "openai")
        XCTAssertEqual(setJSON["modelId"] as? String, "gpt-4.1")

        let responseJSON = """
        {
            "state": {
                "spaceId": "main-space",
                "spaceUid": "11111111-2222-3333-4444-555555555555",
                "mainAgentId": "main-agent",
                "mainAgentDefinitionId": "main-agent-definition",
                "mainProfileId": "main-profile",
                "assignedAgentDefinitionId": "main-agent-definition",
                "assignedProfileId": "main-profile",
                "providerHint": "openai",
                "modelConfig": { "preferredModels": ["openai/gpt-4.1"] },
                "status": "degraded",
                "repaired": false,
                "fallbackApplied": false,
                "runtimeIssueReason": "Configured provider unavailable: missing-provider",
                "updatedAt": "2026-03-02T12:00:00.000Z"
            }
        }
        """
        let decoded = try JSONDecoder().decode(
            GatewayGetMainAgentResponsePayload.self,
            from: Data(responseJSON.utf8)
        )
        XCTAssertEqual(decoded.state.mainAgentId, "main-agent")
        XCTAssertEqual(decoded.state.mainAgentDefinitionId, "main-agent-definition")
        XCTAssertEqual(decoded.state.assignedAgentDefinitionId, "main-agent-definition")
        XCTAssertEqual(decoded.state.preferredModelId, "openai/gpt-4.1")
        XCTAssertEqual(decoded.state.status, .degraded)
        XCTAssertEqual(decoded.state.fallbackApplied, false)
        XCTAssertEqual(decoded.state.runtimeIssueReason, "Configured provider unavailable: missing-provider")
    }

    func testConciergeAgentPayloadEncodingAndResponseDecoding() throws {
        let getPayload = GatewayGetConciergeAgentPayload(
            apiVersion: "v1",
            spaceId: "concierge-space",
            repairIfMissing: true
        )
        let getJSON = try encodeJSONObject(getPayload)
        XCTAssertEqual(getJSON["apiVersion"] as? String, "v1")
        XCTAssertEqual(getJSON["spaceId"] as? String, "concierge-space")
        XCTAssertEqual(getJSON["repairIfMissing"] as? Bool, true)

        let setPayload = GatewaySetConciergeAgentPayload(
            apiVersion: "v1",
            spaceId: "concierge-space",
            selectionMode: .providerModel,
            providerId: "openai",
            modelId: "gpt-4.1",
            sourceAgentDefinitionId: nil,
            applyPersonaInstructions: nil
        )
        let setJSON = try encodeJSONObject(setPayload)
        XCTAssertEqual(setJSON["selectionMode"] as? String, "provider_model")
        XCTAssertEqual(setJSON["providerId"] as? String, "openai")
        XCTAssertEqual(setJSON["modelId"] as? String, "gpt-4.1")

        let responseJSON = """
        {
            "state": {
                "spaceId": "concierge-space",
                "spaceUid": "aaaa1111-2222-3333-4444-555555555555",
                "conciergeAgentId": "concierge-agent",
                "conciergeAgentDefinitionId": "concierge-profile",
                "conciergeProfileId": "concierge-profile",
                "assignedAgentDefinitionId": "concierge-profile",
                "assignedProfileId": "concierge-profile",
                "providerHint": "openai",
                "modelConfig": { "preferredModels": ["openai/gpt-4.1"] },
                "status": "fallback",
                "repaired": true,
                "fallbackApplied": true,
                "fallbackReason": "Configured provider unavailable: missing-provider",
                "runtimeIssueReason": "Configured provider unavailable: missing-provider",
                "updatedAt": "2026-03-29T12:00:00.000Z"
            }
        }
        """
        let decoded = try JSONDecoder().decode(
            GatewayGetConciergeAgentResponsePayload.self,
            from: Data(responseJSON.utf8)
        )
        XCTAssertEqual(decoded.state.conciergeAgentId, "concierge-agent")
        XCTAssertEqual(decoded.state.conciergeAgentDefinitionId, "concierge-profile")
        XCTAssertEqual(decoded.state.assignedAgentDefinitionId, "concierge-profile")
        XCTAssertEqual(decoded.state.preferredModelId, "openai/gpt-4.1")
        XCTAssertEqual(decoded.state.status, .fallback)
        XCTAssertTrue(decoded.state.fallbackApplied)
        XCTAssertEqual(decoded.state.runtimeIssueReason, "Configured provider unavailable: missing-provider")
    }

    func testAssignmentAndTemplateAliasesRoundTrip() throws {
        let assignmentJSON = """
        {
            "spaceId": "space-1",
            "agentId": "agent-1",
            "agentDefinitionId": "agent-definition-1",
            "role": "participant",
            "turnOrder": 1,
            "isPrimary": true,
            "assignedAt": "2026-03-07T12:00:00.000Z"
        }
        """
        let decodedAssignment = try JSONDecoder().decode(
            SpaceAgentAssignment.self,
            from: Data(assignmentJSON.utf8)
        )
        XCTAssertEqual(decodedAssignment.agentDefinitionId, "agent-definition-1")
        XCTAssertEqual(decodedAssignment.profileId, "agent-definition-1")

        let templateAgent = TemplateAgentDefinition(
            agentId: "agent-1",
            agentDefinitionId: "agent-definition-1",
            profileBinding: .explicit,
            role: .participant,
            turnOrder: 1,
            isPrimary: true
        )
        let templateJSON = try encodeJSONObject(templateAgent)
        XCTAssertEqual(templateJSON["agentDefinitionId"] as? String, "agent-definition-1")
        XCTAssertEqual(templateJSON["profileId"] as? String, "agent-definition-1")
        XCTAssertEqual(templateJSON["profileBinding"] as? String, "explicit")

        let updatePayload = SpaceUpdateAgentAssignmentPayload(
            apiVersion: "v1",
            idempotencyKey: "idem-1",
            spaceId: "space-1",
            agentId: "agent-1",
            agentDefinitionId: "agent-definition-1",
            profileId: nil,
            role: "participant",
            turnOrder: 1,
            isPrimary: true,
            resetSession: true
        )
        let updateJSON = try encodeJSONObject(updatePayload)
        XCTAssertEqual(updateJSON["agentDefinitionId"] as? String, "agent-definition-1")
        XCTAssertEqual(updateJSON["profileId"] as? String, "agent-definition-1")
    }

    func testSpaceConfigDecodesOrchestratorAgentDefinitionAlias() throws {
        let json = """
        {
            "id": "space-1",
            "spaceUid": "space-uid-1",
            "resourceId": "resource:space-1",
            "name": "Space One",
            "orchestratorAgentDefinitionId": "agent-definition-1",
            "turnModel": "primary_only",
            "agents": [],
            "capabilities": [],
            "capabilityOverrides": {},
            "visibility": "shared",
            "createdAt": "2026-03-07T12:00:00.000Z",
            "updatedAt": "2026-03-07T12:05:00.000Z"
        }
        """

        let decoded = try JSONDecoder().decode(SpaceConfig.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.orchestratorAgentDefinitionId, "agent-definition-1")
        XCTAssertEqual(decoded.orchestratorProfileId, "agent-definition-1")
    }
}
