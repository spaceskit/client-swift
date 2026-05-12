// Space usage, experience, artifact, and policy GatewayClient APIs.

import Foundation

extension GatewayClient {
    /// Read space usage snapshot, including optional per-agent sessions and global lifetime totals.
    public func getSpaceUsage(_ payload: SpaceGetUsagePayload) async throws -> SpaceGetUsageResult {
        let data = try await sendAndWait(type: MessageType.spaceGetUsage, payload: payload)
        return try decoder.decode(SpaceGetUsageResult.self, from: data)
    }

    /// Read merged activity-log entries for one space, optionally scoped to one turn.
    public func listActivityLog(_ payload: SpaceListActivityLogPayload) async throws -> SpaceListActivityLogResult {
        let data = try await sendAndWait(type: MessageType.spaceListActivityLog, payload: payload)
        return try decoder.decode(SpaceListActivityLogResult.self, from: data)
    }

    /// Read sanitized turn trace for one turn.
    public func getTurnTrace(_ payload: SpaceGetTurnTracePayload) async throws -> SpaceTurnTrace {
        let data = try await sendAndWait(type: MessageType.spaceGetTurnTrace, payload: payload)
        let response = try decoder.decode(SpaceGetTurnTraceResult.self, from: data)
        return response.trace
    }

    public func listExperiences(_ payload: SpaceListExperiencesPayload) async throws -> SpaceListExperiencesResult {
        let data = try await sendAndWait(type: MessageType.spaceListExperiences, payload: payload)
        return try decoder.decode(SpaceListExperiencesResult.self, from: data)
    }

    public func getExperience(_ payload: SpaceGetExperiencePayload) async throws -> SpaceExperienceRecord {
        let data = try await sendAndWait(type: MessageType.spaceGetExperience, payload: payload)
        let response = try decoder.decode(SpaceGetExperienceResult.self, from: data)
        return response.experience
    }

    public func listInsights(_ payload: SpaceListInsightsPayload) async throws -> SpaceListInsightsResult {
        let data = try await sendAndWait(type: MessageType.spaceListInsights, payload: payload)
        return try decoder.decode(SpaceListInsightsResult.self, from: data)
    }

    public func getInsight(_ payload: SpaceGetInsightPayload) async throws -> SpacePersonalityInsightRecord {
        let data = try await sendAndWait(type: MessageType.spaceGetInsight, payload: payload)
        let response = try decoder.decode(SpaceGetInsightResult.self, from: data)
        return response.insight
    }

    public func acceptInsight(_ payload: SpaceAcceptInsightPayload) async throws -> SpacePersonalityInsightRecord {
        let data = try await sendAndWait(type: MessageType.spaceAcceptInsight, payload: payload)
        let response = try decoder.decode(SpaceInsightActionResult.self, from: data)
        return response.insight
    }

    public func rejectInsight(_ payload: SpaceRejectInsightPayload) async throws -> SpacePersonalityInsightRecord {
        let data = try await sendAndWait(type: MessageType.spaceRejectInsight, payload: payload)
        let response = try decoder.decode(SpaceInsightActionResult.self, from: data)
        return response.insight
    }

    public func dismissInsight(_ payload: SpaceDismissInsightPayload) async throws -> SpacePersonalityInsightRecord {
        let data = try await sendAndWait(type: MessageType.spaceDismissInsight, payload: payload)
        let response = try decoder.decode(SpaceInsightActionResult.self, from: data)
        return response.insight
    }

    public func getSpaceAgentNotes(_ payload: SpaceGetSpaceAgentNotesPayload) async throws -> SpaceAgentNotesRecord? {
        let data = try await sendAndWait(type: MessageType.spaceGetSpaceAgentNotes, payload: payload)
        let response = try decoder.decode(SpaceAgentNotesResult.self, from: data)
        return response.notes
    }

    public func updateSpaceAgentNotes(_ payload: SpaceUpdateSpaceAgentNotesPayload) async throws -> SpaceAgentNotesRecord? {
        let data = try await sendAndWait(type: MessageType.spaceUpdateSpaceAgentNotes, payload: payload)
        let response = try decoder.decode(SpaceAgentNotesResult.self, from: data)
        return response.notes
    }

    public func getUserProfile(_ payload: SpaceGetUserProfilePayload = SpaceGetUserProfilePayload()) async throws -> SpaceUserProfileRecord? {
        let data = try await sendAndWait(type: MessageType.spaceGetUserProfile, payload: payload)
        let response = try decoder.decode(SpaceUserProfileResult.self, from: data)
        return response.profile
    }

    public func updateUserProfile(_ payload: SpaceUpdateUserProfilePayload) async throws -> SpaceUserProfileRecord? {
        let data = try await sendAndWait(type: MessageType.spaceUpdateUserProfile, payload: payload)
        let response = try decoder.decode(SpaceUserProfileResult.self, from: data)
        return response.profile
    }

    public func listMemories(_ payload: SpaceListMemoriesPayload) async throws -> SpaceListMemoriesResult {
        let data = try await sendAndWait(type: MessageType.spaceListMemories, payload: payload)
        return try decoder.decode(SpaceListMemoriesResult.self, from: data)
    }

    public func deleteMemory(_ payload: SpaceDeleteMemoryPayload) async throws -> SpaceDeleteMemoryResult {
        let data = try await sendAndWait(type: MessageType.spaceDeleteMemory, payload: payload)
        return try decoder.decode(SpaceDeleteMemoryResult.self, from: data)
    }

    public func updateMemoryImportance(_ payload: SpaceUpdateMemoryImportancePayload) async throws -> SpaceMemoryRecord {
        let data = try await sendAndWait(type: MessageType.spaceUpdateMemoryImportance, payload: payload)
        let response = try decoder.decode(SpaceUpdateMemoryImportanceResult.self, from: data)
        return response.memory
    }

    /// List artifacts in a space, optionally scoped to one turn.
    public func listSpaceArtifacts(_ payload: SpaceListArtifactsPayload) async throws -> SpaceListArtifactsResult {
        let data = try await sendAndWait(type: MessageType.spaceListArtifacts, payload: payload)
        return try decoder.decode(SpaceListArtifactsResult.self, from: data)
    }

    /// Fetch one artifact in a space.
    public func getSpaceArtifact(_ payload: SpaceGetArtifactPayload) async throws -> SpaceArtifactDetail {
        let data = try await sendAndWait(type: MessageType.spaceGetArtifact, payload: payload)
        let response = try decoder.decode(SpaceGetArtifactResult.self, from: data)
        return response.artifact
    }

    /// Fetch one debug-only artifact in a space, bypassing the normal preview cap.
    public func getSpaceDebugArtifact(_ payload: SpaceGetDebugArtifactPayload) async throws -> SpaceArtifactDetail {
        let data = try await sendAndWait(type: MessageType.spaceGetDebugArtifact, payload: payload)
        let response = try decoder.decode(SpaceGetDebugArtifactResult.self, from: data)
        return response.artifact
    }

    /// Reset one space's scoped state via gateway transport.
    public func resetSpace(_ payload: SpaceResetPayload) async throws -> SpaceResetResult {
        // Space reset can also be expensive on large persisted datasets.
        let data = try await sendAndWait(
            type: MessageType.spaceReset,
            payload: payload,
            timeoutSec: max(options.requestTimeoutSec, 180)
        )
        return try decoder.decode(SpaceResetResult.self, from: data)
    }

    /// Reset the active usage session for one agent in a space.
    public func resetAgentUsageSession(_ payload: SpaceResetAgentUsageSessionPayload) async throws -> SpaceResetAgentUsageSessionResult {
        let data = try await sendAndWait(type: MessageType.spaceResetAgentUsageSession, payload: payload)
        return try decoder.decode(SpaceResetAgentUsageSessionResult.self, from: data)
    }

    /// Read the effective tool matrix for one space/agent.
    public func getEffectiveTools(_ payload: SpaceGetEffectiveToolsPayload) async throws -> EffectiveToolMatrix {
        let data = try await sendAndWait(type: MessageType.spaceGetEffectiveTools, payload: payload)
        let response = try decoder.decode(SpaceGetEffectiveToolsResponsePayload.self, from: data)
        return response.matrix
    }

    /// Read the unified effective tool access matrix for one space/agent.
    public func getEffectiveToolAccess(_ payload: SpaceGetEffectiveToolAccessPayload) async throws -> EffectiveToolAccess {
        let data = try await sendAndWait(type: MessageType.spaceGetEffectiveToolAccess, payload: payload)
        let response = try decoder.decode(SpaceGetEffectiveToolAccessResponsePayload.self, from: data)
        return response.access
    }

    /// Read the unified tool policy for one space.
    public func getToolPolicy(_ payload: SpaceGetToolPolicyPayload) async throws -> ToolAccessPolicy {
        let data = try await sendAndWait(type: MessageType.spaceGetToolPolicy, payload: payload)
        let response = try decoder.decode(SpaceGetToolPolicyResponsePayload.self, from: data)
        return response.policy
    }

    /// Update the unified tool policy for one space.
    public func updateToolPolicy(_ payload: SpaceUpdateToolPolicyPayload) async throws -> ToolAccessPolicy {
        let data = try await sendAndWait(type: MessageType.spaceUpdateToolPolicy, payload: payload)
        let response = try decoder.decode(SpaceUpdateToolPolicyResponsePayload.self, from: data)
        return response.policy
    }

    /// Read the connector policy for one space.
    public func getConnectorPolicy(_ payload: SpaceGetConnectorPolicyPayload) async throws -> SpaceConnectorPolicy {
        let data = try await sendAndWait(type: MessageType.spaceGetConnectorPolicy, payload: payload)
        let response = try decoder.decode(SpaceGetConnectorPolicyResponsePayload.self, from: data)
        return response.policy
    }

    /// Update the connector policy for one space.
    public func updateConnectorPolicy(_ payload: SpaceUpdateConnectorPolicyPayload) async throws -> SpaceConnectorPolicy {
        let data = try await sendAndWait(type: MessageType.spaceUpdateConnectorPolicy, payload: payload)
        let response = try decoder.decode(SpaceUpdateConnectorPolicyResponsePayload.self, from: data)
        return response.policy
    }
}
