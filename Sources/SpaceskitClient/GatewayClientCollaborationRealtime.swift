// Collaboration, sync, speech, and concierge-call GatewayClient APIs.

import Foundation

extension GatewayClient {
    public func linkSpaces(
        sourceSpaceId: String,
        targetSpaceId: String,
        mode: String? = nil,
        apiVersion: String? = nil
    ) async throws -> SpaceLinkResult {
        let payload = SpaceLinkPayload(
            apiVersion: apiVersion,
            sourceSpaceId: sourceSpaceId,
            targetSpaceId: targetSpaceId,
            mode: mode
        )
        let data = try await sendAndWait(type: MessageType.spaceLink, payload: payload)
        let response = try decoder.decode(SpaceLinkResponsePayload.self, from: data)
        return response.link
    }

    public func unlinkSpaces(
        sourceSpaceId: String,
        targetSpaceId: String,
        apiVersion: String? = nil
    ) async throws -> Bool {
        let payload = SpaceUnlinkPayload(
            apiVersion: apiVersion,
            sourceSpaceId: sourceSpaceId,
            targetSpaceId: targetSpaceId
        )
        let data = try await sendAndWait(type: MessageType.spaceUnlink, payload: payload)
        let response = try decoder.decode(SpaceUnlinkResponsePayload.self, from: data)
        return response.removed
    }

    public func shareSpaceContext(
        sourceSpaceId: String,
        targetSpaceId: String,
        artifactId: String,
        apiVersion: String? = nil
    ) async throws -> SharedContextRef {
        let payload = SpaceShareContextPayload(
            apiVersion: apiVersion,
            sourceSpaceId: sourceSpaceId,
            targetSpaceId: targetSpaceId,
            artifactId: artifactId
        )
        let data = try await sendAndWait(type: MessageType.spaceShareContext, payload: payload)
        let response = try decoder.decode(SpaceShareContextResponsePayload.self, from: data)
        return response.transfer
    }

    public func pullSharedContext(
        sourceSpaceId: String,
        targetSpaceId: String,
        limit: Int? = nil,
        apiVersion: String? = nil
    ) async throws -> SpacePullSharedContextResult {
        let payload = SpacePullSharedContextPayload(
            apiVersion: apiVersion,
            sourceSpaceId: sourceSpaceId,
            targetSpaceId: targetSpaceId,
            limit: limit
        )
        let data = try await sendAndWait(type: MessageType.spacePullSharedContext, payload: payload)
        return try decoder.decode(SpacePullSharedContextResult.self, from: data)
    }

    public func createSpaceShareInvite(
        spaceId: String,
        mode: SpaceShareAccessMode,
        expiresInSeconds: Int? = nil,
        apiVersion: String? = nil
    ) async throws -> SpaceShareInvite {
        let payload = SpaceShareCreateInvitePayload(
            apiVersion: apiVersion,
            spaceId: spaceId,
            mode: mode,
            expiresInSeconds: expiresInSeconds
        )
        let data = try await sendAndWait(type: MessageType.spaceShareCreateInvite, payload: payload)
        let response = try decoder.decode(SpaceShareCreateInviteResponsePayload.self, from: data)
        return response.invite
    }

    public func joinSpaceShareInvite(
        spaceId: String,
        inviteToken: String,
        deviceId: String? = nil,
        devicePublicKey: String? = nil,
        identityModeHint: SpaceShareIdentityModeHint? = nil,
        appleIdAssertion: String? = nil,
        joinRoute: SpaceShareJoinRoute? = nil,
        relaySessionToken: String? = nil,
        apiVersion: String? = nil
    ) async throws -> SpaceParticipant {
        let payload = SpaceShareJoinPayload(
            apiVersion: apiVersion,
            spaceId: spaceId,
            inviteToken: inviteToken,
            deviceId: deviceId,
            devicePublicKey: devicePublicKey,
            identityModeHint: identityModeHint,
            appleIdAssertion: appleIdAssertion,
            joinRoute: joinRoute,
            relaySessionToken: relaySessionToken
        )
        let data = try await sendAndWait(type: MessageType.spaceShareJoin, payload: payload)
        let response = try decoder.decode(SpaceShareJoinResponsePayload.self, from: data)
        return response.participant
    }

    public func revokeSpaceShareAccess(
        spaceId: String,
        inviteId: String? = nil,
        participantId: String? = nil,
        apiVersion: String? = nil
    ) async throws -> SpaceShareRevokeResult {
        let payload = SpaceShareRevokePayload(
            apiVersion: apiVersion,
            spaceId: spaceId,
            inviteId: inviteId,
            participantId: participantId
        )
        let data = try await sendAndWait(type: MessageType.spaceShareRevoke, payload: payload)
        return try decoder.decode(SpaceShareRevokeResult.self, from: data)
    }

    public func listSpaceParticipants(
        spaceId: String,
        apiVersion: String? = nil
    ) async throws -> [SpaceParticipant] {
        let payload = SpaceShareListParticipantsPayload(
            apiVersion: apiVersion,
            spaceId: spaceId
        )
        let data = try await sendAndWait(type: MessageType.spaceShareListParticipants, payload: payload)
        let response = try decoder.decode(SpaceShareListParticipantsResponsePayload.self, from: data)
        return response.participants
    }

    /// Announce sync peer/resource capability without constructing payloads in callers.
    public func announceSyncPeer(
        apiVersion: String? = nil,
        peerId: String,
        resourceId: String,
        gatewayVersion: String,
        endpointUrl: String? = nil,
        authSecretHash: String? = nil,
        skillCount: Int? = nil,
        actionCount: Int? = nil,
        experienceCount: Int? = nil,
        profileCount: Int? = nil
    ) async throws -> SyncAnnounceResult {
        let payload = SyncAnnouncePayload(
            apiVersion: apiVersion,
            peerId: peerId,
            resourceId: resourceId,
            gatewayVersion: gatewayVersion,
            endpointUrl: endpointUrl,
            authSecretHash: authSecretHash,
            skillCount: skillCount,
            actionCount: actionCount,
            experienceCount: experienceCount,
            profileCount: profileCount
        )
        return try await announceSyncPeer(payload)
    }

    /// Query sync resources without constructing payloads in callers.
    public func querySyncResources(
        apiVersion: String? = nil,
        peerId: String,
        resourceId: String? = nil,
        types: [String]? = nil,
        tags: [String]? = nil,
        updatedAfter: String? = nil,
        cursor: String? = nil,
        limit: Int? = nil
    ) async throws -> SyncQueryResourcesResult {
        let payload = SyncQueryResourcesPayload(
            apiVersion: apiVersion,
            peerId: peerId,
            resourceId: resourceId,
            types: types,
            tags: tags,
            updatedAfter: updatedAfter,
            cursor: cursor,
            limit: limit
        )
        return try await querySyncResources(payload)
    }

    /// Pull sync resources without constructing payloads in callers.
    public func pullSyncResources(
        apiVersion: String? = nil,
        peerId: String,
        idempotencyKey: String,
        refs: [SyncResourceRef]
    ) async throws -> SyncPullResourcesResult {
        let payload = SyncPullResourcesPayload(
            apiVersion: apiVersion,
            peerId: peerId,
            idempotencyKey: idempotencyKey,
            refs: refs
        )
        return try await pullSyncResources(payload)
    }

    public func announceSyncPeer(_ payload: SyncAnnouncePayload) async throws -> SyncAnnounceResult {
        let data = try await sendAndWait(type: MessageType.syncAnnounce, payload: payload)
        return try decoder.decode(SyncAnnounceResult.self, from: data)
    }

    public func querySyncResources(_ payload: SyncQueryResourcesPayload) async throws -> SyncQueryResourcesResult {
        let data = try await sendAndWait(type: MessageType.syncQueryResources, payload: payload)
        return try decoder.decode(SyncQueryResourcesResult.self, from: data)
    }

    public func pullSyncResources(_ payload: SyncPullResourcesPayload) async throws -> SyncPullResourcesResult {
        let data = try await sendAndWait(type: MessageType.syncPullResources, payload: payload)
        return try decoder.decode(SyncPullResourcesResult.self, from: data)
    }
}
