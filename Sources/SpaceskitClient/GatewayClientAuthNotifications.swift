// Auth and notification GatewayClient APIs.

import Foundation

extension GatewayClient {
    public func registerDevice(_ payload: AuthRegisterDevicePayload) async throws -> AuthRegisterDeviceResult {
        let data = try await sendAndWait(type: MessageType.authRegisterDevice, payload: payload)
        return try decoder.decode(AuthRegisterDeviceResult.self, from: data)
    }

    public func rotateDeviceKey(_ payload: AuthRotateDeviceKeyPayload) async throws -> AuthRotateDeviceKeyResult {
        let data = try await sendAndWait(type: MessageType.authRotateDeviceKey, payload: payload)
        return try decoder.decode(AuthRotateDeviceKeyResult.self, from: data)
    }

    public func revokeDevice(_ payload: AuthRevokeDevicePayload) async throws -> AuthRevokeDeviceResult {
        let data = try await sendAndWait(type: MessageType.authRevokeDevice, payload: payload)
        return try decoder.decode(AuthRevokeDeviceResult.self, from: data)
    }

    public func listDevices(
        apiVersion: String? = nil,
        includeRevoked: Bool? = nil
    ) async throws -> [DeviceIdentity] {
        let payload = AuthListDevicesPayload(apiVersion: apiVersion, includeRevoked: includeRevoked)
        let data = try await sendAndWait(type: MessageType.authListDevices, payload: payload)
        let response = try decoder.decode(AuthListDevicesResponsePayload.self, from: data)
        return response.devices
    }

    public func issueHttpPrincipalToken(
        apiVersion: String? = nil,
        ttlSeconds: Int? = nil
    ) async throws -> AuthIssueHttpPrincipalTokenResponsePayload {
        let payload = AuthIssueHttpPrincipalTokenPayload(
            apiVersion: apiVersion,
            ttlSeconds: ttlSeconds
        )
        let data = try await sendAndWait(type: MessageType.authIssueHttpPrincipalToken, payload: payload)
        return try decoder.decode(AuthIssueHttpPrincipalTokenResponsePayload.self, from: data)
    }

    public func registerApplePushDevice(
        _ request: ApplePushDeviceRegistrationRequest,
        tokenTTLSeconds: Int? = 300
    ) async throws -> ApplePushDeviceRegistration {
        let response = try await sendNotificationRestRequest(
            path: "/v1/notifications/devices",
            method: "POST",
            body: request,
            responseType: ApplePushDeviceRegistrationResponse.self,
            tokenTTLSeconds: tokenTTLSeconds
        )
        return response.registration
    }

    public func deleteApplePushDevice(
        registrationId: String,
        tokenTTLSeconds: Int? = 300
    ) async throws -> Bool {
        let response = try await sendNotificationRestRequest(
            path: "/v1/notifications/devices/\(registrationId)",
            method: "DELETE",
            body: Optional<EmptyRequestBody>.none,
            responseType: DeleteApplePushDeviceResponse.self,
            tokenTTLSeconds: tokenTTLSeconds
        )
        return response.deleted
    }

    public func getAppleNotificationPreferences(
        tokenTTLSeconds: Int? = 300
    ) async throws -> AppleNotificationPreferences {
        let response = try await sendNotificationRestRequest(
            path: "/v1/notifications/preferences",
            method: "GET",
            body: Optional<EmptyRequestBody>.none,
            responseType: AppleNotificationPreferencesResponse.self,
            tokenTTLSeconds: tokenTTLSeconds
        )
        return response.preferences
    }

    public func patchAppleNotificationPreferences(
        _ patch: AppleNotificationPreferencesPatch,
        tokenTTLSeconds: Int? = 300
    ) async throws -> AppleNotificationPreferences {
        let response = try await sendNotificationRestRequest(
            path: "/v1/notifications/preferences",
            method: "PATCH",
            body: patch,
            responseType: AppleNotificationPreferencesResponse.self,
            tokenTTLSeconds: tokenTTLSeconds
        )
        return response.preferences
    }

    public func markNotificationDeliveryOpened(
        deliveryId: String,
        tokenTTLSeconds: Int? = 300
    ) async throws -> AppleNotificationDelivery {
        let response = try await sendNotificationRestRequest(
            path: "/v1/notifications/deliveries/\(deliveryId)/opened",
            method: "POST",
            body: Optional<EmptyRequestBody>.none,
            responseType: AppleNotificationDeliveryResponse.self,
            tokenTTLSeconds: tokenTTLSeconds
        )
        return response.delivery
    }

    public func resolveBackgroundFeedback(
        feedbackId: String,
        request: BackgroundFeedbackResolveRequest,
        tokenTTLSeconds: Int? = 300
    ) async throws -> BackgroundFeedbackActionResult {
        let response = try await sendNotificationRestRequest(
            path: "/v1/notifications/feedback/\(feedbackId)/resolve",
            method: "POST",
            body: request,
            responseType: BackgroundFeedbackActionResponse.self,
            tokenTTLSeconds: tokenTTLSeconds
        )
        return response.result
    }
}
