// Gateway client REST helper payloads.

import Foundation

// MARK: - Empty Payload

struct EmptyPayload: Codable {}

struct EmptyRequestBody: Codable {}

struct ApplePushDeviceRegistrationResponse: Codable {
    let registration: ApplePushDeviceRegistration
}

struct DeleteApplePushDeviceResponse: Codable {
    let deleted: Bool
}

struct AppleNotificationPreferencesResponse: Codable {
    let preferences: AppleNotificationPreferences
}

struct AppleNotificationDeliveryResponse: Codable {
    let delivery: AppleNotificationDelivery
}

struct BackgroundFeedbackActionResponse: Codable {
    let result: BackgroundFeedbackActionResult
}
