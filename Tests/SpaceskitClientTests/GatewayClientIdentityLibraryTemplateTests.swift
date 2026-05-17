import XCTest
@testable import SpaceskitClient

final class GatewayClientIdentityLibraryTemplateTests: GatewayClientTestCase {

    func testSchedulerUpdateJobPayloadEncodesEvalConfigTriState() throws {
        let omitted = SchedulerUpdateJobPayload(jobId: "job-1")
        let omittedJSON = try encodeJSONObject(omitted)
        XCTAssertNil(omittedJSON["evalConfig"])

        let clearedEvalConfig: SchedulerEvalConfig?? = .some(nil)
        let cleared = SchedulerUpdateJobPayload(jobId: "job-1", evalConfig: clearedEvalConfig)
        let clearedJSON = try encodeJSONObject(cleared)
        XCTAssertTrue(clearedJSON.keys.contains("evalConfig"))
        XCTAssertTrue(clearedJSON["evalConfig"] is NSNull)

        let configured = SchedulerUpdateJobPayload(
            jobId: "job-1",
            evalConfig: .some(
                SchedulerEvalConfig(
                    evalDefinitionId: "summarization",
                    scenarioIds: ["scenario-a"],
                    summaryMode: .checkpoints,
                    selfImproveEnabled: false
                )
            )
        )
        let configuredJSON = try encodeJSONObject(configured)
        let evalConfigJSON = try XCTUnwrap(configuredJSON["evalConfig"] as? [String: Any])
        XCTAssertEqual(evalConfigJSON["evalDefinitionId"] as? String, "summarization")
        XCTAssertEqual(evalConfigJSON["scenarioIds"] as? [String], ["scenario-a"])
    }

    func testHardCutIdentityLibraryAndTemplatePayloads() throws {
        let createAgentDefinitionPayload = IdentityCreateAgentDefinitionPayload(
            apiVersion: "v1",
            idempotencyKey: "idem-1",
            agentDefinitionId: "agent-definition-1",
            personaId: "persona-1",
            name: "Builder",
            description: "Build things",
            instructions: "Be precise.",
            defaultSkillIds: ["skill-1"],
            providerHint: "openai",
            modelConfig: ProfileModelConfig(preferredModels: ["gpt-4.1"]),
            isDefault: true
        )
        let agentDefinitionJSON = try encodeJSONObject(createAgentDefinitionPayload)
        XCTAssertEqual(agentDefinitionJSON["agentDefinitionId"] as? String, "agent-definition-1")
        XCTAssertEqual(agentDefinitionJSON["personaId"] as? String, "persona-1")
        XCTAssertNil(agentDefinitionJSON["modelId"])

        let saveSkillPayload = LibrarySaveSkillPayload(
            apiVersion: "v1",
            idempotencyKey: "idem-2",
            entryId: "entry-1",
            skillId: "skill-1",
            name: "Formatter",
            description: "Format output",
            contentMarkdown: "# Formatter",
            tags: ["formatting"],
            sourceKind: .installed,
            sourceRef: "local",
            enabled: true
        )
        let saveSkillJSON = try encodeJSONObject(saveSkillPayload)
        XCTAssertEqual(saveSkillJSON["entryId"] as? String, "entry-1")
        XCTAssertEqual(saveSkillJSON["sourceKind"] as? String, "installed")
        XCTAssertEqual(saveSkillJSON["enabled"] as? Bool, true)

        let templatePayload = SpaceTemplateSavePayload(
            apiVersion: "v1",
            idempotencyKey: "idem-3",
            templateId: "template-1",
            name: "Research Team",
            description: "Managed template",
            communicationMode: CommunicationMode.chatFirst.rawValue,
            baseAgents: [
                TemplateAgentDefinition(
                    agentId: "agent-1",
                    agentDefinitionId: "agent-definition-1",
                    profileBinding: .explicit,
                    role: .participant,
                    turnOrder: 1,
                    isPrimary: true
                )
            ],
            sourceSpaceId: "space-1"
        )
        let templatePayloadJSON = try encodeJSONObject(templatePayload)
        XCTAssertEqual(templatePayloadJSON["name"] as? String, "Research Team")
        let baseAgents = templatePayloadJSON["baseAgents"] as? [[String: Any]]
        XCTAssertEqual(baseAgents?.first?["agentDefinitionId"] as? String, "agent-definition-1")
        XCTAssertEqual(baseAgents?.first?["profileId"] as? String, "agent-definition-1")
        XCTAssertEqual(baseAgents?.first?["profileBinding"] as? String, "explicit")

        let previewResponseJSON = """
        {
            "preview": {
                "agentDefinitionId": "agent-definition-1",
                "personaId": "persona-1",
                "sections": [
                    {
                        "key": "agent_definition",
                        "title": "Agent Definition",
                        "content": "Be precise."
                    }
                ],
                "compiledText": "Be precise.",
                "generatedAt": "2026-03-07T12:10:00.000Z"
            }
        }
        """
        let preview = try JSONDecoder().decode(
            IdentityPreviewCompiledInstructionsResponsePayload.self,
            from: Data(previewResponseJSON.utf8)
        )
        XCTAssertEqual(preview.preview.sections.first?.key, .agentDefinition)

        let matrixResponseJSON = """
        {
            "matrix": {
                "agentDefinitionId": "agent-definition-1",
                "personaId": "persona-1",
                "generatedAt": "2026-03-14T10:20:00.000Z",
                "variants": [
                    {
                        "budgetClass": "full",
                        "label": "Cloud",
                        "tokenEstimate": 321,
                        "sections": [
                            {
                                "key": "conversation_prompt",
                                "title": "Conversation Prompt",
                                "content": "Keep responses concise."
                            },
                            {
                                "key": "assignment_context",
                                "title": "Assignment Context",
                                "content": "Focus on synthesis."
                            }
                        ],
                        "compiledText": "Keep responses concise. Focus on synthesis."
                    }
                ]
            }
        }
        """
        let matrixResponse = try JSONDecoder().decode(
            IdentityPreviewSystemPromptMatrixResponsePayload.self,
            from: Data(matrixResponseJSON.utf8)
        )
        XCTAssertEqual(matrixResponse.matrix.variants.first?.sections.first?.key, .conversationPrompt)
        XCTAssertEqual(matrixResponse.matrix.variants.first?.sections.last?.key, .assignmentContext)

        let libraryResponseJSON = """
        {
            "entries": [
                {
                    "entryId": "entry-1",
                    "skillId": "skill-1",
                    "name": "Formatter",
                    "description": "Format output",
                    "contentMarkdown": "# Formatter",
                    "sourceKind": "installed",
                    "sourceRef": "local",
                    "provenance": {"publisher": "OpenAI"},
                    "tags": ["formatting"],
                    "status": "enabled",
                    "importable": false,
                    "importedSkillId": "skill-1",
                    "createdAt": "2026-03-07T12:00:00.000Z",
                    "updatedAt": "2026-03-07T12:05:00.000Z"
                }
            ]
        }
        """
        let libraryResponse = try JSONDecoder().decode(
            LibraryListEntriesResponsePayload.self,
            from: Data(libraryResponseJSON.utf8)
        )
        XCTAssertEqual(libraryResponse.entries.first?.sourceKind, .installed)
        XCTAssertEqual(libraryResponse.entries.first?.status, .enabled)

        let managedTemplateResponseJSON = """
        {
            "template": {
                "templateId": "template-1",
                "name": "Research Team",
                "description": "Managed template",
                "status": "active",
                "activeRevision": 2,
                "communicationMode": "chat_first",
                "turnModel": "sequential_all",
                "agentDefinitions": [
                    {
                        "agentId": "agent-1",
                        "agentDefinitionId": "agent-definition-1",
                        "role": "participant",
                        "turnOrder": 1,
                        "isPrimary": true
                    }
                ],
                "createdBy": "principal-1",
                "createdAt": "2026-03-07T12:00:00.000Z",
                "updatedAt": "2026-03-07T12:05:00.000Z"
            },
            "resolved": {
                "templateId": "template-1",
                "templateRevision": 2,
                "name": "Research Team",
                "resourceId": "resource:space-1",
                "communicationMode": "chat_first",
                "turnModel": "sequential_all",
                "initialAgents": [
                    {
                        "agentId": "agent-1",
                        "agentDefinitionId": "agent-definition-1",
                        "role": "participant",
                        "turnOrder": 1,
                        "isPrimary": true
                    }
                ]
            },
            "warnings": []
        }
        """
        let managedTemplateResponse = try JSONDecoder().decode(
            SpaceTemplatePreviewResponsePayload.self,
            from: Data(managedTemplateResponseJSON.utf8)
        )
        XCTAssertEqual(managedTemplateResponse.template.name, "Research Team")
        XCTAssertEqual(managedTemplateResponse.template.agentDefinitions.first?.agentDefinitionId, "agent-definition-1")
    }

    func testAdminFixturesRemainLoadable() throws {
        let fixtureNames = [
            "GatewayGetMainAgentPayload",
            "GatewaySetMainAgentPayload",
            "GatewayGetMainAgentResponsePayload",
            "GatewaySetMainAgentResponsePayload",
            "GatewayGetConciergeAgentPayload",
            "GatewaySetConciergeAgentPayload",
            "GatewayGetConciergeAgentResponsePayload",
            "GatewaySetConciergeAgentResponsePayload",
            "GatewayListAvailableModelsPayload",
            "GatewayListAvailableModelsResponsePayload",
            "GatewayFactoryResetPayload",
            "GatewayFactoryResetResponsePayload",
            "SpaceResetPayload",
            "GatewayPutSecretRefPayload",
            "GatewayListSecretRefsPayload",
            "GatewayListSecretRefsResponsePayload",
            "GatewayDeleteSecretRefPayload",
            "GatewayListConnectorFamiliesPayload",
            "GatewayListConnectorFamiliesResponsePayload",
            "GatewayListConnectorsPayload",
            "GatewayListConnectorsResponsePayload",
            "GatewayUpsertConnectorPayload",
            "GatewayUpsertConnectorResponsePayload",
            "GatewayRemoveConnectorPayload",
            "GatewayRemoveConnectorResponsePayload",
            "GatewayListConnectorBindingsPayload",
            "GatewayListConnectorBindingsResponsePayload",
            "GatewayUpsertConnectorBindingPayload",
            "GatewayUpsertConnectorBindingResponsePayload",
            "GatewayRemoveConnectorBindingPayload",
            "GatewayRemoveConnectorBindingResponsePayload",
            "GatewayGetConnectorPolicyPayload",
            "GatewayGetConnectorPolicyResponsePayload",
            "GatewayUpdateConnectorPolicyPayload",
            "GatewayUpdateConnectorPolicyResponsePayload",
            "GatewayTestConnectorPayload",
            "GatewayTestConnectorResponsePayload",
            "GatewayListCapabilityGrantsPayload",
            "GatewayListCapabilityGrantsResponsePayload",
            "GatewayGrantCapabilityPayload",
            "GatewayGrantCapabilityResponsePayload",
            "GatewayRevokeCapabilityPayload",
            "GatewayRevokeCapabilityResponsePayload",
            "GatewayGetWorkspaceDefaultsPayload",
            "GatewayGetWorkspaceDefaultsResponsePayload",
            "GatewaySetWorkspaceDefaultsPayload",
            "GatewaySetWorkspaceDefaultsResponsePayload",
            "GatewayGetMemoryDefaultsPayload",
            "GatewayGetMemoryDefaultsResponsePayload",
            "GatewaySetMemoryDefaultsPayload",
            "GatewaySetMemoryDefaultsResponsePayload",
            "GatewayGetExternalConnectivityPayload",
            "GatewayGetExternalConnectivityResponsePayload",
            "GatewaySetExternalConnectivityPayload",
            "GatewaySetExternalConnectivityResponsePayload",
            "SpaceGetMemoryPolicyPayload",
            "SpaceGetMemoryPolicyResponsePayload",
            "SpaceSetMemoryPolicyPayload",
            "SpaceSetMemoryPolicyResponsePayload",
            "SpaceEndIncognitoSessionPayload",
            "SpaceEndIncognitoSessionResponsePayload",
            "SpaceListActivityLogPayload",
            "SpaceListActivityLogResult",
            "SpaceListExperiencesPayload",
            "SpaceListExperiencesResult",
            "SpaceListInsightsPayload",
            "SpaceListInsightsResult",
            "SpaceGetUserProfilePayload",
            "SpaceUserProfileResult",
            "SpaceListMemoriesPayload",
            "SpaceListMemoriesResult",
        ]

        for name in fixtureNames {
            let data = try loadFixture(name)
            XCTAssertNoThrow(
                try JSONSerialization.jsonObject(with: data),
                "Fixture \(name).json should be valid JSON"
            )
        }
    }
}
