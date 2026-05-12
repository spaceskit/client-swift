// Types.swift — Shared data types for Spaceskit Client SDK
// Zero external dependencies. Codable for JSON serialization.

import Foundation

// MARK: - Notifications

public struct GatewayNotification: Codable, Sendable {
    public let notificationId: String
    public let category: String
    public let severity: String
    public let title: String
    public let body: String
    public let spaceId: String?
    public let spaceUid: String?
    public let agentId: String?
    public let data: [String: AnyCodable]?
    public let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case notificationId
        case category
        case severity
        case title
        case body
        case spaceId
        case spaceUid
        case agentId
        case data
        case createdAt
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case message
    }

    public init(
        notificationId: String,
        category: String,
        severity: String,
        title: String,
        body: String,
        spaceId: String? = nil,
        spaceUid: String? = nil,
        agentId: String? = nil,
        data: [String: AnyCodable]? = nil,
        createdAt: String
    ) {
        self.notificationId = notificationId
        self.category = category
        self.severity = severity
        self.title = title
        self.body = body
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.agentId = agentId
        self.data = data
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notificationId = try container.decode(String.self, forKey: .notificationId)
        category = try container.decode(String.self, forKey: .category)
        severity = try container.decode(String.self, forKey: .severity)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decodeIfPresent(String.self, forKey: .body)
            ?? {
                let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)
                return try legacyContainer.decode(String.self, forKey: .message)
            }()
        spaceId = try container.decodeIfPresent(String.self, forKey: .spaceId)
        spaceUid = try container.decodeIfPresent(String.self, forKey: .spaceUid)
        agentId = try container.decodeIfPresent(String.self, forKey: .agentId)
        data = try container.decodeIfPresent([String: AnyCodable].self, forKey: .data)
        createdAt = try container.decode(String.self, forKey: .createdAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(notificationId, forKey: .notificationId)
        try container.encode(category, forKey: .category)
        try container.encode(severity, forKey: .severity)
        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)
        try container.encodeIfPresent(spaceId, forKey: .spaceId)
        try container.encodeIfPresent(spaceUid, forKey: .spaceUid)
        try container.encodeIfPresent(agentId, forKey: .agentId)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

public enum ApplePushPlatform: String, Codable, Sendable {
    case ios
    case macos
}

public enum ApplePushTokenKind: String, Codable, Sendable {
    case alert
    case voip
}

public enum ApplePushEnvironment: String, Codable, Sendable {
    case sandbox
    case production
}

public enum NotificationActionIdentifier: String, Codable, Sendable {
    case approve
    case reject
    case deferAction = "defer"
    case revise
    case openApp = "open_app"
}

public struct ApplePushDeviceRegistrationRequest: Codable, Sendable {
    public let registrationId: String?
    public let deviceId: String?
    public let platform: ApplePushPlatform
    public let tokenKind: ApplePushTokenKind
    public let pushToken: String
    public let topic: String?
    public let environment: ApplePushEnvironment
    public let appBundleId: String?
    public let deviceName: String?
    public let metadata: [String: AnyCodable]?

    public init(
        registrationId: String? = nil,
        deviceId: String? = nil,
        platform: ApplePushPlatform,
        tokenKind: ApplePushTokenKind = .alert,
        pushToken: String,
        topic: String? = nil,
        environment: ApplePushEnvironment = .sandbox,
        appBundleId: String? = nil,
        deviceName: String? = nil,
        metadata: [String: AnyCodable]? = nil
    ) {
        self.registrationId = registrationId
        self.deviceId = deviceId
        self.platform = platform
        self.tokenKind = tokenKind
        self.pushToken = pushToken
        self.topic = topic
        self.environment = environment
        self.appBundleId = appBundleId
        self.deviceName = deviceName
        self.metadata = metadata
    }
}

public struct ApplePushDeviceRegistration: Codable, Sendable {
    public let registrationId: String
    public let principalId: String
    public let deviceId: String
    public let platform: ApplePushPlatform
    public let tokenKind: ApplePushTokenKind
    public let pushToken: String
    public let topic: String
    public let environment: ApplePushEnvironment
    public let appBundleId: String?
    public let deviceName: String?
    public let enabled: Bool
    public let createdAt: String
    public let updatedAt: String
    public let lastSeenAt: String
    public let staleAt: String?
    public let metadata: [String: AnyCodable]
}

public struct AppleNotificationQuietHours: Codable, Sendable, Equatable {
    public let enabled: Bool
    public let startMinute: Int
    public let endMinute: Int
    public let timeZone: String?

    public init(
        enabled: Bool,
        startMinute: Int,
        endMinute: Int,
        timeZone: String? = nil
    ) {
        self.enabled = enabled
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.timeZone = timeZone
    }
}

public struct AppleNotificationPreferences: Codable, Sendable {
    public let principalId: String
    public let enabled: Bool
    public let quietHours: AppleNotificationQuietHours
    public let cooldownSeconds: Int
    public let allowCritical: Bool
    public let updatedAt: String
}

public struct AppleNotificationPreferencesPatch: Codable, Sendable {
    public struct QuietHoursPatch: Codable, Sendable {
        public let enabled: Bool?
        public let startMinute: Int?
        public let endMinute: Int?
        public let timeZone: String?

        public init(
            enabled: Bool? = nil,
            startMinute: Int? = nil,
            endMinute: Int? = nil,
            timeZone: String? = nil
        ) {
            self.enabled = enabled
            self.startMinute = startMinute
            self.endMinute = endMinute
            self.timeZone = timeZone
        }
    }

    public let enabled: Bool?
    public let quietHours: QuietHoursPatch?
    public let cooldownSeconds: Int?
    public let allowCritical: Bool?

    public init(
        enabled: Bool? = nil,
        quietHours: QuietHoursPatch? = nil,
        cooldownSeconds: Int? = nil,
        allowCritical: Bool? = nil
    ) {
        self.enabled = enabled
        self.quietHours = quietHours
        self.cooldownSeconds = cooldownSeconds
        self.allowCritical = allowCritical
    }
}

public struct NotificationActionContext: Codable, Sendable {
    public let gatewayId: String?
    public let deliveryId: String?
    public let feedbackId: String?
    public let action: NotificationActionIdentifier
    public let deepLink: String?
    public let payload: [String: AnyCodable]?

    public init(
        gatewayId: String? = nil,
        deliveryId: String? = nil,
        feedbackId: String? = nil,
        action: NotificationActionIdentifier,
        deepLink: String? = nil,
        payload: [String: AnyCodable]? = nil
    ) {
        self.gatewayId = gatewayId
        self.deliveryId = deliveryId
        self.feedbackId = feedbackId
        self.action = action
        self.deepLink = deepLink
        self.payload = payload
    }
}

public struct BackgroundFeedbackResolveRequest: Codable, Sendable {
    public let deliveryId: String?
    public let action: NotificationActionIdentifier
    public let message: String?
    public let payload: [String: AnyCodable]?

    public init(
        deliveryId: String? = nil,
        action: NotificationActionIdentifier,
        message: String? = nil,
        payload: [String: AnyCodable]? = nil
    ) {
        self.deliveryId = deliveryId
        self.action = action
        self.message = message
        self.payload = payload
    }
}

public struct BackgroundFeedbackActionResult: Codable, Sendable {
    public let feedbackId: String
    public let action: NotificationActionIdentifier
    public let status: String
    public let result: [String: AnyCodable]?
}

public struct AppleNotificationDelivery: Codable, Sendable {
    public let deliveryId: String
    public let principalId: String
    public let registrationId: String?
    public let notificationId: String?
    public let feedbackId: String?
    public let callId: String?
    public let gatewayId: String?
    public let channel: String
    public let status: String
    public let action: NotificationActionIdentifier?
    public let deepLink: String?
    public let errorMessage: String?
    public let createdAt: String
    public let sentAt: String?
    public let openedAt: String?
    public let actionedAt: String?
    public let payload: [String: AnyCodable]
}

public struct AppNavigateEvent: Codable, Sendable {
    public let destination: String
    public let gatewayId: String?
    public let spaceId: String?
    public let jobId: String?
    public let promptText: String?
}
