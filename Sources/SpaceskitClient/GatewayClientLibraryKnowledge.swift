// Library, knowledge base, and capability GatewayClient APIs.

import Foundation

extension GatewayClient {
    public func listLibraryEntries(
        apiVersion: String? = nil,
        query: String? = nil,
        tags: [String]? = nil,
        status: LibraryEntryStatus? = nil,
        sourceKinds: [LibrarySourceKind]? = nil,
        includeArchived: Bool? = nil,
        includeContent: Bool? = nil,
        limit: Int? = nil
    ) async throws -> [LibraryEntry] {
        let payload = LibraryListEntriesPayload(
            apiVersion: apiVersion,
            query: query,
            tags: tags,
            status: status,
            sourceKinds: sourceKinds,
            includeArchived: includeArchived,
            includeContent: includeContent,
            limit: limit
        )
        let data = try await sendAndWait(type: MessageType.libraryListEntries, payload: payload)
        let response = try decoder.decode(LibraryListEntriesResponsePayload.self, from: data)
        return response.entries
    }

    public func getLibraryEntry(
        entryId: String,
        apiVersion: String? = nil,
        includeContent: Bool? = nil
    ) async throws -> LibraryEntry {
        let payload = LibraryGetEntryPayload(
            apiVersion: apiVersion,
            entryId: entryId,
            includeContent: includeContent
        )
        let data = try await sendAndWait(type: MessageType.libraryGetEntry, payload: payload)
        let response = try decoder.decode(LibraryGetEntryResponsePayload.self, from: data)
        return response.entry
    }

    public func saveLibrarySkill(_ payload: LibrarySaveSkillPayload) async throws -> LibrarySaveSkillResult {
        let data = try await sendAndWait(type: MessageType.librarySaveSkill, payload: payload)
        let response = try decoder.decode(LibrarySaveSkillResponsePayload.self, from: data)
        return LibrarySaveSkillResult(entry: response.entry, created: response.created)
    }

    public func importLibraryEntry(_ payload: LibraryImportEntryPayload) async throws -> LibraryImportEntryResult {
        let data = try await sendAndWait(type: MessageType.libraryImportEntry, payload: payload)
        let response = try decoder.decode(LibraryImportEntryResponsePayload.self, from: data)
        return LibraryImportEntryResult(entry: response.entry, created: response.created)
    }

    public func archiveLibraryEntry(_ payload: LibraryArchiveEntryPayload) async throws -> LibraryArchiveEntryResult {
        let data = try await sendAndWait(type: MessageType.libraryArchiveEntry, payload: payload)
        let response = try decoder.decode(LibraryArchiveEntryResponsePayload.self, from: data)
        return LibraryArchiveEntryResult(entry: response.entry, archived: response.archived)
    }

    public func setLibraryEntryEnabled(_ payload: LibrarySetEntryEnabledPayload) async throws -> LibraryEntry {
        let data = try await sendAndWait(type: MessageType.librarySetEntryEnabled, payload: payload)
        let response = try decoder.decode(LibrarySetEntryEnabledResponsePayload.self, from: data)
        return response.entry
    }

    public func deleteLibraryEntry(_ payload: LibraryDeleteEntryPayload) async throws -> LibraryDeleteEntryResult {
        let data = try await sendAndWait(type: MessageType.libraryDeleteEntry, payload: payload)
        let response = try decoder.decode(LibraryDeleteEntryResponsePayload.self, from: data)
        return LibraryDeleteEntryResult(entryId: response.entryId, deleted: response.deleted)
    }

    public func scanLibraryEntries(apiVersion: String? = nil) async throws -> LibraryScanEntriesResult {
        let payload = LibraryScanEntriesPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.libraryScanEntries, payload: payload)
        let response = try decoder.decode(LibraryScanEntriesResponsePayload.self, from: data)
        return LibraryScanEntriesResult(entries: response.entries, scannedAt: response.scannedAt)
    }

    public func listSkillDrafts(apiVersion: String? = nil) async throws -> [SkillDraft] {
        let payload = LibraryListSkillDraftsPayload(apiVersion: apiVersion)
        let data = try await sendAndWait(type: MessageType.libraryListSkillDrafts, payload: payload)
        let response = try decoder.decode(LibraryListSkillDraftsResponsePayload.self, from: data)
        return response.drafts
    }

    public func getSkillDraft(draftId: String, apiVersion: String? = nil) async throws -> SkillDraft {
        let payload = LibraryGetSkillDraftPayload(apiVersion: apiVersion, draftId: draftId)
        let data = try await sendAndWait(type: MessageType.libraryGetSkillDraft, payload: payload)
        let response = try decoder.decode(LibraryGetSkillDraftResponsePayload.self, from: data)
        return response.draft
    }

    public func createSkillDraft(
        _ payload: LibraryCreateSkillDraftPayload
    ) async throws -> LibraryCreateSkillDraftResult {
        let data = try await sendAndWait(type: MessageType.libraryCreateSkillDraft, payload: payload)
        let response = try decoder.decode(LibraryCreateSkillDraftResponsePayload.self, from: data)
        return LibraryCreateSkillDraftResult(draft: response.draft, created: response.created)
    }

    public func deleteSkillDraft(
        _ payload: LibraryDeleteSkillDraftPayload
    ) async throws -> LibraryDeleteSkillDraftResult {
        let data = try await sendAndWait(type: MessageType.libraryDeleteSkillDraft, payload: payload)
        let response = try decoder.decode(LibraryDeleteSkillDraftResponsePayload.self, from: data)
        return LibraryDeleteSkillDraftResult(draftId: response.draftId, deleted: response.deleted)
    }

    /// List gateway knowledge base entries (global + optional space-scoped).
    public func listKnowledgeBaseEntries(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        query: String? = nil,
        tags: [String]? = nil,
        kinds: [GatewayKnowledgeBaseEntryKind]? = nil,
        limit: Int? = nil
    ) async throws -> [GatewayKnowledgeBaseEntry] {
        let payload = GatewayListKnowledgeBaseEntriesPayload(
            apiVersion: apiVersion,
            spaceId: spaceId,
            query: query,
            tags: tags,
            kinds: kinds,
            limit: limit
        )
        let data = try await sendAndWait(type: MessageType.gatewayKbListEntries, payload: payload)
        let response = try decoder.decode(GatewayListKnowledgeBaseEntriesResponsePayload.self, from: data)
        return response.entries
    }

    /// Create or update one gateway knowledge base entry.
    public func upsertKnowledgeBaseEntry(
        _ payload: GatewayUpsertKnowledgeBaseEntryPayload
    ) async throws -> GatewayKnowledgeBaseEntry {
        let data = try await sendAndWait(type: MessageType.gatewayKbUpsertEntry, payload: payload)
        let response = try decoder.decode(GatewayUpsertKnowledgeBaseEntryResponsePayload.self, from: data)
        return response.entry
    }

    /// Delete one gateway knowledge base entry by ID.
    public func deleteKnowledgeBaseEntry(
        entryId: String,
        apiVersion: String? = nil
    ) async throws -> Bool {
        let payload = GatewayDeleteKnowledgeBaseEntryPayload(apiVersion: apiVersion, entryId: entryId)
        let data = try await sendAndWait(type: MessageType.gatewayKbDeleteEntry, payload: payload)
        let response = try decoder.decode(GatewayDeleteKnowledgeBaseEntryResponsePayload.self, from: data)
        return response.deleted
    }

    /// List capability grants, optionally filtered by principal/device and grant status.
    public func listCapabilityGrants(
        apiVersion: String? = nil,
        principalId: String? = nil,
        deviceId: String? = nil,
        includeRevoked: Bool? = nil,
        includeExpired: Bool? = nil
    ) async throws -> [GatewayCapabilityGrant] {
        let payload = GatewayListCapabilityGrantsPayload(
            apiVersion: apiVersion,
            principalId: principalId,
            deviceId: deviceId,
            includeRevoked: includeRevoked,
            includeExpired: includeExpired
        )
        let data = try await sendAndWait(type: MessageType.gatewayListCapabilityGrants, payload: payload)
        let response = try decoder.decode(GatewayListCapabilityGrantsResponsePayload.self, from: data)
        return response.grants
    }

    /// Grant capability access for a principal/device scope.
    public func grantCapability(_ payload: GatewayGrantCapabilityPayload) async throws -> GatewayCapabilityGrant {
        let data = try await sendAndWait(type: MessageType.gatewayGrantCapability, payload: payload)
        let response = try decoder.decode(GatewayGrantCapabilityResponsePayload.self, from: data)
        return response.grant
    }

    /// Revoke capability access for a principal/device scope.
    public func revokeCapability(_ payload: GatewayRevokeCapabilityPayload) async throws -> GatewayRevokeCapabilityResult {
        let data = try await sendAndWait(type: MessageType.gatewayRevokeCapability, payload: payload)
        let response = try decoder.decode(GatewayRevokeCapabilityResponsePayload.self, from: data)
        return GatewayRevokeCapabilityResult(
            revoked: response.revoked,
            capabilityId: response.capabilityId,
            principalId: response.principalId,
            deviceId: response.deviceId,
            grant: response.grant
        )
    }
}
