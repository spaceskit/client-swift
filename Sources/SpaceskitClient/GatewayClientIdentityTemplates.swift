// Identity and template GatewayClient APIs.

import Foundation

extension GatewayClient {
    public func listAgentDefinitions(
        apiVersion: String? = nil,
        includeArchived: Bool? = nil
    ) async throws -> [AgentDefinitionSummary] {
        let payload = IdentityListAgentDefinitionsPayload(
            apiVersion: apiVersion,
            includeArchived: includeArchived
        )
        let data = try await sendAndWait(type: MessageType.identityListAgentDefinitions, payload: payload)
        let response = try decoder.decode(IdentityListAgentDefinitionsResponsePayload.self, from: data)
        return response.agentDefinitions
    }

    public func getAgentDefinition(
        agentDefinitionId: String,
        apiVersion: String? = nil
    ) async throws -> AgentDefinitionSummary {
        let payload = IdentityGetAgentDefinitionPayload(
            apiVersion: apiVersion,
            agentDefinitionId: agentDefinitionId
        )
        let data = try await sendAndWait(type: MessageType.identityGetAgentDefinition, payload: payload)
        let response = try decoder.decode(IdentityGetAgentDefinitionResponsePayload.self, from: data)
        return response.agentDefinition
    }

    public func createAgentDefinition(
        _ payload: IdentityCreateAgentDefinitionPayload
    ) async throws -> AgentDefinitionCreateResult {
        let data = try await sendAndWait(type: MessageType.identityCreateAgentDefinition, payload: payload)
        let response = try decoder.decode(IdentityCreateAgentDefinitionResponsePayload.self, from: data)
        return AgentDefinitionCreateResult(
            agentDefinition: response.agentDefinition,
            created: response.created
        )
    }

    public func updateAgentDefinition(
        _ payload: IdentityUpdateAgentDefinitionPayload
    ) async throws -> AgentDefinitionUpdateResult {
        let data = try await sendAndWait(type: MessageType.identityUpdateAgentDefinition, payload: payload)
        let response = try decoder.decode(IdentityUpdateAgentDefinitionResponsePayload.self, from: data)
        return AgentDefinitionUpdateResult(
            agentDefinition: response.agentDefinition,
            newRevision: response.newRevision
        )
    }

    public func archiveAgentDefinition(
        _ payload: IdentityArchiveAgentDefinitionPayload
    ) async throws -> AgentDefinitionArchiveResult {
        let data = try await sendAndWait(type: MessageType.identityArchiveAgentDefinition, payload: payload)
        let response = try decoder.decode(IdentityArchiveAgentDefinitionResponsePayload.self, from: data)
        return AgentDefinitionArchiveResult(
            agentDefinition: response.agentDefinition,
            archived: response.archived
        )
    }

    public func listPersonas(
        apiVersion: String? = nil,
        includeArchived: Bool? = nil
    ) async throws -> [PersonaSummary] {
        let payload = IdentityListPersonasPayload(apiVersion: apiVersion, includeArchived: includeArchived)
        let data = try await sendAndWait(type: MessageType.identityListPersonas, payload: payload)
        let response = try decoder.decode(IdentityListPersonasResponsePayload.self, from: data)
        return response.personas
    }

    public func getPersona(personaId: String, apiVersion: String? = nil) async throws -> PersonaSummary {
        let payload = IdentityGetPersonaPayload(apiVersion: apiVersion, personaId: personaId)
        let data = try await sendAndWait(type: MessageType.identityGetPersona, payload: payload)
        let response = try decoder.decode(IdentityGetPersonaResponsePayload.self, from: data)
        return response.persona
    }

    public func createPersona(_ payload: IdentityCreatePersonaPayload) async throws -> PersonaCreateResult {
        let data = try await sendAndWait(type: MessageType.identityCreatePersona, payload: payload)
        let response = try decoder.decode(IdentityCreatePersonaResponsePayload.self, from: data)
        return PersonaCreateResult(persona: response.persona, created: response.created)
    }

    public func updatePersona(_ payload: IdentityUpdatePersonaPayload) async throws -> PersonaUpdateResult {
        let data = try await sendAndWait(type: MessageType.identityUpdatePersona, payload: payload)
        let response = try decoder.decode(IdentityUpdatePersonaResponsePayload.self, from: data)
        return PersonaUpdateResult(persona: response.persona, newRevision: response.newRevision)
    }

    public func archivePersona(_ payload: IdentityArchivePersonaPayload) async throws -> PersonaArchiveResult {
        let data = try await sendAndWait(type: MessageType.identityArchivePersona, payload: payload)
        let response = try decoder.decode(IdentityArchivePersonaResponsePayload.self, from: data)
        return PersonaArchiveResult(persona: response.persona, archived: response.archived)
    }

    public func previewCompiledInstructions(
        agentDefinitionId: String,
        apiVersion: String? = nil,
        workspaceContext: String? = nil
    ) async throws -> CompiledInstructionsPreview {
        let payload = IdentityPreviewCompiledInstructionsPayload(
            apiVersion: apiVersion,
            agentDefinitionId: agentDefinitionId,
            workspaceContext: workspaceContext
        )
        let data = try await sendAndWait(
            type: MessageType.identityPreviewCompiledInstructions,
            payload: payload
        )
        let response = try decoder.decode(IdentityPreviewCompiledInstructionsResponsePayload.self, from: data)
        return response.preview
    }

    public func previewRuntimeSystemPrompt(
        _ payload: IdentityPreviewRuntimeSystemPromptPayload
    ) async throws -> RuntimeSystemPromptPreview {
        let data = try await sendAndWait(
            type: MessageType.identityPreviewRuntimeSystemPrompt,
            payload: payload
        )
        let response = try decoder.decode(IdentityPreviewRuntimeSystemPromptResponsePayload.self, from: data)
        return response.preview
    }

    /// Preview the composed system prompt across all budget classes for an agent definition.
    public func previewSystemPromptMatrix(
        agentDefinitionId: String,
        spaceId: String? = nil,
        agentId: String? = nil,
        apiVersion: String? = nil
    ) async throws -> SystemPromptMatrix {
        let payload = IdentityPreviewSystemPromptMatrixPayload(
            apiVersion: apiVersion,
            agentDefinitionId: agentDefinitionId,
            spaceId: spaceId,
            agentId: agentId
        )
        let data = try await sendAndWait(
            type: MessageType.identityPreviewSystemPromptMatrix,
            payload: payload
        )
        let response = try decoder.decode(IdentityPreviewSystemPromptMatrixResponsePayload.self, from: data)
        return response.matrix
    }

    public func previewTemplate(_ payload: SpacePreviewTemplatePayload) async throws -> SpacePreviewTemplateResult {
        let data = try await sendAndWait(type: MessageType.spacePreviewTemplate, payload: payload)
        let response = try decoder.decode(SpacePreviewTemplateResponsePayload.self, from: data)
        return SpacePreviewTemplateResult(
            template: response.template,
            resolved: response.resolved,
            warnings: response.warnings
        )
    }

    public func createSpaceFromTemplate(_ payload: SpaceCreateFromTemplatePayload) async throws -> SpaceCreateFromTemplateResult {
        let data = try await sendAndWait(type: MessageType.spaceCreateFromTemplate, payload: payload)
        return try decoder.decode(SpaceCreateFromTemplateResult.self, from: data)
    }

    public func saveSpaceTemplate(_ payload: SpaceSaveTemplatePayload) async throws -> SpaceSaveTemplateResult {
        let data = try await sendAndWait(type: MessageType.spaceSaveTemplate, payload: payload)
        return try decoder.decode(SpaceSaveTemplateResult.self, from: data)
    }

    public func listSpaceTemplates(
        apiVersion: String? = nil,
        includeArchived: Bool? = nil,
        includeSystem: Bool? = nil
    ) async throws -> [SpaceTemplateRecord] {
        let payload = SpaceTemplateListPayload(apiVersion: apiVersion, includeArchived: includeArchived, includeSystem: includeSystem)
        let data = try await sendAndWait(type: MessageType.spaceListTemplates, payload: payload)
        let response = try decoder.decode(SpaceTemplateListResponsePayload.self, from: data)
        return response.templates
    }

    public func getSpaceTemplate(
        templateId: String,
        apiVersion: String? = nil
    ) async throws -> SpaceTemplateRecord {
        let payload = SpaceTemplateGetPayload(apiVersion: apiVersion, templateId: templateId)
        let data = try await sendAndWait(type: MessageType.spaceGetTemplate, payload: payload)
        let response = try decoder.decode(SpaceTemplateGetResponsePayload.self, from: data)
        return response.template
    }

    public func previewSpaceTemplateRecord(
        _ payload: SpaceTemplatePreviewPayload
    ) async throws -> SpaceTemplatePreviewResult {
        async let template = getSpaceTemplate(
            templateId: payload.templateId,
            apiVersion: payload.apiVersion
        )
        async let preview = previewTemplate(
            SpacePreviewTemplatePayload(
                apiVersion: payload.apiVersion,
                templateId: payload.templateId,
                resourceId: payload.resourceId,
                name: payload.name,
                goal: payload.goal
            )
        )
        let (record, resolvedPreview) = try await (template, preview)
        return SpaceTemplatePreviewResult(
            template: record,
            resolved: resolvedPreview.resolved,
            warnings: resolvedPreview.warnings
        )
    }

    public func createSpaceFromManagedTemplate(
        _ payload: SpaceTemplateCreateSpacePayload
    ) async throws -> SpaceTemplateCreateSpaceResult {
        async let template = getSpaceTemplate(
            templateId: payload.templateId,
            apiVersion: payload.apiVersion
        )
        async let created = createSpaceFromTemplate(
            SpaceCreateFromTemplatePayload(
                apiVersion: payload.apiVersion,
                idempotencyKey: payload.idempotencyKey,
                templateId: payload.templateId,
                spaceId: payload.spaceId,
                resourceId: payload.resourceId,
                name: payload.name,
                goal: payload.goal,
                workspaceRoot: payload.workspaceRoot,
                visibility: payload.visibility
            )
        )
        let (record, result) = try await (template, created)
        return SpaceTemplateCreateSpaceResult(template: record, space: result.space)
    }

    public func saveManagedSpaceTemplate(
        _ payload: SpaceTemplateSavePayload
    ) async throws -> SpaceTemplateSaveResult {
        let result = try await saveSpaceTemplate(
            SpaceSaveTemplatePayload(
                apiVersion: payload.apiVersion,
                templateId: payload.templateId,
                title: payload.name,
                description: payload.description,
                communicationMode: payload.communicationMode,
                conversationTopology: payload.conversationTopology,
                promptPackId: payload.promptPackId,
                baseAgents: payload.baseAgents,
                sourceSpaceId: payload.sourceSpaceId
            )
        )
        let template = try await getSpaceTemplate(
            templateId: result.template.templateId,
            apiVersion: payload.apiVersion
        )
        return SpaceTemplateSaveResult(template: template, created: result.created)
    }

    public func archiveSpaceTemplate(
        _ payload: SpaceTemplateArchivePayload
    ) async throws -> SpaceTemplateArchiveResult {
        let data = try await sendAndWait(type: MessageType.spaceArchiveTemplate, payload: payload)
        let response = try decoder.decode(SpaceTemplateArchiveResponsePayload.self, from: data)
        return SpaceTemplateArchiveResult(template: response.template, archived: response.archived)
    }
}
