// Space lifecycle, assignment, workspace, and resource GatewayClient APIs.

import Foundation

extension GatewayClient {
    /// Create a new space on the gateway.
    public func createSpace(_ payload: SpaceCreatePayload) async throws -> SpaceConfig {
        let data = try await sendAndWait(type: MessageType.spaceCreate, payload: payload)
        let response = try decoder.decode(SpaceCreateResponsePayload.self, from: data)
        return response.space
    }

    /// Get a single space by ID.
    public func getSpace(spaceId: String, apiVersion: String? = nil) async throws -> SpaceConfig {
        let payload = SpaceGetPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceGet, payload: payload)
        let response = try decoder.decode(SpaceGetResponsePayload.self, from: data)
        return response.space
    }

    /// List spaces with optional filters.
    public func listSpaces(
        apiVersion: String? = nil,
        statuses: [String]? = nil,
        resourceId: String? = nil,
        limit: Int? = nil
    ) async throws -> [SpaceConfig] {
        let payload = SpaceListPayload(
            apiVersion: apiVersion,
            statuses: statuses,
            resourceId: resourceId,
            limit: limit
        )
        let data = try await sendAndWait(type: MessageType.spaceList, payload: payload)
        let response = try decoder.decode(SpaceListResponsePayload.self, from: data)
        return response.spaces
    }

    /// Archive a space on the gateway.
    public func archiveSpace(_ payload: SpaceArchivePayload) async throws -> SpaceArchiveResponsePayload {
        let data = try await sendAndWait(type: MessageType.spaceArchive, payload: payload)
        return try decoder.decode(SpaceArchiveResponsePayload.self, from: data)
    }

    /// Soft-delete a space on the gateway.
    public func deleteSpace(_ payload: SpaceDeletePayload) async throws -> SpaceDeleteResponsePayload {
        let data = try await sendAndWait(type: MessageType.spaceDelete, payload: payload)
        return try decoder.decode(SpaceDeleteResponsePayload.self, from: data)
    }

    /// Update the editable metadata for a space.
    public func updateSpaceMetadata(_ payload: SpaceUpdateMetadataPayload) async throws -> SpaceConfig {
        let data = try await sendAndWait(type: MessageType.spaceUpdateMetadata, payload: payload)
        let response = try decoder.decode(SpaceUpdateMetadataResponsePayload.self, from: data)
        return response.space
    }

    /// Add an agent assignment to a space.
    public func addAgent(_ payload: SpaceAddAgentPayload) async throws -> SpaceAddAgentResult {
        let data = try await sendAndWait(type: MessageType.spaceAddAgent, payload: payload)
        let response = try decoder.decode(SpaceAddAgentResponsePayload.self, from: data)
        return SpaceAddAgentResult(assignment: response.assignment, space: response.space)
    }

    /// Remove an agent assignment from a space.
    public func removeAgent(_ payload: SpaceRemoveAgentPayload) async throws -> SpaceRemoveAgentResult {
        let data = try await sendAndWait(type: MessageType.spaceRemoveAgent, payload: payload)
        let response = try decoder.decode(SpaceRemoveAgentResponsePayload.self, from: data)
        return SpaceRemoveAgentResult(
            removed: response.removed,
            spaceId: response.spaceId,
            spaceUid: response.spaceUid,
            agentId: response.agentId,
            space: response.space
        )
    }

    /// Update an existing agent assignment in a space.
    public func updateAgentAssignment(
        _ payload: SpaceUpdateAgentAssignmentPayload
    ) async throws -> SpaceUpdateAgentAssignmentResult {
        let data = try await sendAndWait(type: MessageType.spaceUpdateAgentAssignment, payload: payload)
        let response = try decoder.decode(SpaceUpdateAgentAssignmentResponsePayload.self, from: data)
        return SpaceUpdateAgentAssignmentResult(assignment: response.assignment, space: response.space)
    }

    /// Set the orchestrator profile for a space.
    public func setSpaceOrchestrator(_ payload: SpaceSetOrchestratorPayload) async throws -> SpaceConfig {
        let data = try await sendAndWait(type: MessageType.spaceSetOrchestrator, payload: payload)
        let response = try decoder.decode(SpaceGetResponsePayload.self, from: data)
        return response.space
    }

    /// Set the thinking-capture persistence policy for a space.
    public func setThinkingCapturePolicy(_ payload: SpaceSetThinkingCapturePolicyPayload) async throws -> SpaceConfig {
        let data = try await sendAndWait(type: MessageType.spaceSetThinkingCapturePolicy, payload: payload)
        let response = try decoder.decode(SpaceSetThinkingCapturePolicyResponsePayload.self, from: data)
        return response.space
    }

    public func getSpaceMemoryPolicy(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> SpaceMemoryPolicy {
        let payload = SpaceGetMemoryPolicyPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceGetMemoryPolicy, payload: payload)
        let response = try decoder.decode(SpaceGetMemoryPolicyResponsePayload.self, from: data)
        return response.memoryPolicy
    }

    public func setSpaceMemoryPolicy(_ payload: SpaceSetMemoryPolicyPayload) async throws -> SpaceConfig {
        let data = try await sendAndWait(type: MessageType.spaceSetMemoryPolicy, payload: payload)
        let response = try decoder.decode(SpaceSetMemoryPolicyResponsePayload.self, from: data)
        return response.space
    }

    public func endIncognitoSession(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> SpaceEndIncognitoSessionResponsePayload {
        let payload = SpaceEndIncognitoSessionPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceEndIncognitoSession, payload: payload)
        return try decoder.decode(SpaceEndIncognitoSessionResponsePayload.self, from: data)
    }

    /// List all agent assignments for a space.
    public func listAgentAssignments(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> [SpaceAgentAssignment] {
        let payload = SpaceListAgentAssignmentsPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceListAgentAssignments, payload: payload)
        let response = try decoder.decode(SpaceListAgentAssignmentsResponsePayload.self, from: data)
        return response.assignments
    }

    /// Fetch the configured MCP endpoint for one space, if any.
    public func getMcpEndpoint(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> SpaceMcpEndpoint? {
        let payload = SpaceGetMcpEndpointPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceGetMcpEndpoint, payload: payload)
        let response = try decoder.decode(SpaceGetMcpEndpointResponsePayload.self, from: data)
        return response.endpoint
    }

    /// Create or update the MCP endpoint configuration for one space.
    public func setMcpEndpoint(_ payload: SpaceSetMcpEndpointPayload) async throws -> SpaceMcpEndpoint {
        let data = try await sendAndWait(type: MessageType.spaceSetMcpEndpoint, payload: payload)
        let response = try decoder.decode(SpaceSetMcpEndpointResponsePayload.self, from: data)
        return response.endpoint
    }

    /// Remove the MCP endpoint configuration for one space.
    public func clearMcpEndpoint(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> Bool {
        let payload = SpaceClearMcpEndpointPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceClearMcpEndpoint, payload: payload)
        let response = try decoder.decode(SpaceClearMcpEndpointResponsePayload.self, from: data)
        return response.cleared
    }

    /// Add one skill assignment to a space.
    public func addSkillToSpace(_ payload: SpaceAddSkillPayload) async throws -> SpaceAddSkillResponsePayload {
        let data = try await sendAndWait(type: MessageType.spaceAddSkill, payload: payload)
        return try decoder.decode(SpaceAddSkillResponsePayload.self, from: data)
    }

    /// Remove one skill assignment from a space.
    public func removeSkillFromSpace(_ payload: SpaceRemoveSkillPayload) async throws -> SpaceRemoveSkillResponsePayload {
        let data = try await sendAndWait(type: MessageType.spaceRemoveSkill, payload: payload)
        return try decoder.decode(SpaceRemoveSkillResponsePayload.self, from: data)
    }

    /// List all skills assigned to a space.
    public func listSpaceSkills(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> [String] {
        let payload = SpaceListSkillsPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceListSkills, payload: payload)
        let response = try decoder.decode(SpaceListSkillsResponsePayload.self, from: data)
        return response.skills
    }

    /// Fetch effective workspace layout/binding for one space.
    public func getSpaceWorkspace(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> SpaceWorkspace {
        let payload = SpaceGetWorkspacePayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceGetWorkspace, payload: payload)
        let response = try decoder.decode(SpaceGetWorkspaceResponsePayload.self, from: data)
        return response.workspace
    }

    /// Set or clear the folder binding for one space.
    public func setSpaceWorkspace(_ payload: SpaceSetWorkspacePayload) async throws -> SpaceWorkspace {
        let data = try await sendAndWait(type: MessageType.spaceSetWorkspace, payload: payload)
        let response = try decoder.decode(SpaceSetWorkspaceResponsePayload.self, from: data)
        return response.workspace
    }

    /// Open an existing folder/repo on the gateway host and resolve it to a space binding.
    public func openSpaceWorkspace(_ payload: SpaceOpenWorkspacePayload) async throws -> SpaceOpenWorkspaceResult {
        let data = try await sendAndWait(type: MessageType.spaceOpenWorkspace, payload: payload)
        let response = try decoder.decode(SpaceOpenWorkspaceResponsePayload.self, from: data)
        return response.result
    }

    /// Add one resource assignment to a space.
    public func addSpaceResource(_ payload: SpaceAddResourcePayload) async throws -> SpaceResource {
        let data = try await sendAndWait(type: MessageType.spaceAddResource, payload: payload)
        let response = try decoder.decode(SpaceAddResourceResponsePayload.self, from: data)
        return response.resource
    }

    /// Remove one resource assignment from a space.
    public func removeSpaceResource(_ payload: SpaceRemoveResourcePayload) async throws -> Bool {
        let data = try await sendAndWait(type: MessageType.spaceRemoveResource, payload: payload)
        let response = try decoder.decode(SpaceRemoveResourceResponsePayload.self, from: data)
        return response.removed
    }

    /// List all resources assigned to a space.
    public func listSpaceResources(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> [SpaceResource] {
        let payload = SpaceListResourcesPayload(apiVersion: apiVersion, spaceId: spaceId)
        let data = try await sendAndWait(type: MessageType.spaceListResources, payload: payload)
        let response = try decoder.decode(SpaceListResourcesResponsePayload.self, from: data)
        return response.resources
    }

    /// List persisted turns for a space with deterministic pagination.
    public func listSpaceTurns(
        spaceId: String? = nil,
        spaceUid: String? = nil,
        limit: Int = 100,
        offset: Int = 0,
        lastSeenTurnId: String? = nil,
        apiVersion: String? = nil
    ) async throws -> SpaceListTurnsResult {
        let normalizedSpaceIdRaw = spaceId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSpaceUidRaw = spaceUid?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedLastSeenTurnIdRaw = lastSeenTurnId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSpaceId = (normalizedSpaceIdRaw?.isEmpty == false) ? normalizedSpaceIdRaw : nil
        let normalizedSpaceUid = (normalizedSpaceUidRaw?.isEmpty == false) ? normalizedSpaceUidRaw : nil
        let normalizedLastSeenTurnId = (normalizedLastSeenTurnIdRaw?.isEmpty == false) ? normalizedLastSeenTurnIdRaw : nil
        guard normalizedSpaceId != nil || normalizedSpaceUid != nil else {
            throw GatewayError(
                code: "INVALID_ARGUMENT",
                message: "spaceId or spaceUid is required",
                details: nil
            )
        }
        guard limit > 0 else {
            throw GatewayError(
                code: "INVALID_ARGUMENT",
                message: "limit must be greater than 0",
                details: nil
            )
        }
        guard normalizedLastSeenTurnId != nil || offset >= 0 else {
            throw GatewayError(
                code: "INVALID_ARGUMENT",
                message: "offset must be >= 0",
                details: nil
            )
        }

        let payload = SpaceListTurnsPayload(
            apiVersion: apiVersion,
            spaceId: normalizedSpaceId,
            spaceUid: normalizedSpaceUid,
            limit: limit,
            offset: offset,
            lastSeenTurnId: normalizedLastSeenTurnId
        )
        let data = try await sendAndWait(type: MessageType.spaceListTurns, payload: payload)
        let response = try decoder.decode(SpaceListTurnsResponsePayload.self, from: data)
        return SpaceListTurnsResult(
            spaceId: response.spaceId,
            spaceUid: response.spaceUid,
            turns: response.turns,
            total: response.total,
            nextOffset: response.nextOffset
        )
    }

    /// List redacted orchestration journal entries for a space with deterministic pagination.
    public func listOrchestrationJournal(
        spaceId: String? = nil,
        spaceUid: String? = nil,
        turnId: String? = nil,
        limit: Int = 50,
        offset: Int = 0,
        apiVersion: String? = nil
    ) async throws -> SpaceListOrchestrationJournalResult {
        let normalizedSpaceIdRaw = spaceId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSpaceUidRaw = spaceUid?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTurnIdRaw = turnId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSpaceId = (normalizedSpaceIdRaw?.isEmpty == false) ? normalizedSpaceIdRaw : nil
        let normalizedSpaceUid = (normalizedSpaceUidRaw?.isEmpty == false) ? normalizedSpaceUidRaw : nil
        let normalizedTurnId = (normalizedTurnIdRaw?.isEmpty == false) ? normalizedTurnIdRaw : nil

        guard normalizedSpaceId != nil || normalizedSpaceUid != nil else {
            throw GatewayError(
                code: "INVALID_ARGUMENT",
                message: "spaceId or spaceUid is required",
                details: nil
            )
        }
        guard limit > 0 else {
            throw GatewayError(
                code: "INVALID_ARGUMENT",
                message: "limit must be greater than 0",
                details: nil
            )
        }
        guard offset >= 0 else {
            throw GatewayError(
                code: "INVALID_ARGUMENT",
                message: "offset must be >= 0",
                details: nil
            )
        }

        let payload = SpaceListOrchestrationJournalPayload(
            apiVersion: apiVersion,
            spaceId: normalizedSpaceId,
            spaceUid: normalizedSpaceUid,
            turnId: normalizedTurnId,
            limit: limit,
            offset: offset
        )
        let data = try await sendAndWait(type: MessageType.spaceListOrchestrationJournal, payload: payload)
        let response = try decoder.decode(SpaceListOrchestrationJournalResponsePayload.self, from: data)
        return SpaceListOrchestrationJournalResult(
            spaceId: response.spaceId,
            spaceUid: response.spaceUid,
            entries: response.entries,
            total: response.total,
            nextOffset: response.nextOffset
        )
    }
}
