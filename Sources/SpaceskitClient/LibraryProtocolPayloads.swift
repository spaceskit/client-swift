// LibraryProtocolPayloads.swift - Gateway skill and library payloads.

import Foundation

public struct GatewaySkillListPayload: Codable, Sendable {
    public let apiVersion: String?
    public let query: String?
    public let tags: [String]?
    public let status: String?
    public let limit: Int?

    public init(
        apiVersion: String? = nil,
        query: String? = nil,
        tags: [String]? = nil,
        status: String? = nil,
        limit: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.query = query
        self.tags = tags
        self.status = status
        self.limit = limit
    }
}

public struct GatewaySkillEntry: Codable, Sendable, Identifiable {
    public let skillId: String
    public let name: String
    public let description: String?
    public let contentMarkdown: String?
    public let sourceRef: String?
    public let tags: [String]
    public let status: String
    public let createdAt: String
    public let updatedAt: String

    public var id: String { skillId }
}

public struct GatewaySkillListResponsePayload: Codable, Sendable {
    public let skills: [GatewaySkillEntry]
}

// MARK: - Library

public struct LibraryListEntriesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let query: String?
    public let tags: [String]?
    public let status: LibraryEntryStatus?
    public let sourceKinds: [LibrarySourceKind]?
    public let includeArchived: Bool?
    public let includeContent: Bool?
    public let limit: Int?

    public init(
        apiVersion: String? = nil,
        query: String? = nil,
        tags: [String]? = nil,
        status: LibraryEntryStatus? = nil,
        sourceKinds: [LibrarySourceKind]? = nil,
        includeArchived: Bool? = nil,
        includeContent: Bool? = nil,
        limit: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.query = query
        self.tags = tags
        self.status = status
        self.sourceKinds = sourceKinds
        self.includeArchived = includeArchived
        self.includeContent = includeContent
        self.limit = limit
    }
}

public struct LibraryGetEntryPayload: Codable, Sendable {
    public let apiVersion: String?
    public let entryId: String
    public let includeContent: Bool?

    public init(apiVersion: String? = nil, entryId: String, includeContent: Bool? = nil) {
        self.apiVersion = apiVersion
        self.entryId = entryId
        self.includeContent = includeContent
    }
}

public struct LibrarySaveSkillPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let entryId: String?
    public let skillId: String?
    public let name: String
    public let description: String?
    public let contentMarkdown: String
    public let tags: [String]?
    public let sourceKind: LibrarySourceKind?
    public let sourceRef: String?
    public let status: LibraryEntryStatus?
    public let enabled: Bool?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        entryId: String? = nil,
        skillId: String? = nil,
        name: String,
        description: String? = nil,
        contentMarkdown: String,
        tags: [String]? = nil,
        sourceKind: LibrarySourceKind? = nil,
        sourceRef: String? = nil,
        status: LibraryEntryStatus? = nil,
        enabled: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.entryId = entryId
        self.skillId = skillId
        self.name = name
        self.description = description
        self.contentMarkdown = contentMarkdown
        self.tags = tags
        self.sourceKind = sourceKind
        self.sourceRef = sourceRef
        self.status = status
        self.enabled = enabled
    }
}

public struct LibraryImportEntryPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let entryId: String
    public let skillId: String?
    public let name: String?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        entryId: String,
        skillId: String? = nil,
        name: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.entryId = entryId
        self.skillId = skillId
        self.name = name
    }
}

public struct LibraryArchiveEntryPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let entryId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        entryId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.entryId = entryId
    }
}

public struct LibrarySetEntryEnabledPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let entryId: String
    public let enabled: Bool

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        entryId: String,
        enabled: Bool
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.entryId = entryId
        self.enabled = enabled
    }
}

public struct LibraryDeleteEntryPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let entryId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        entryId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.entryId = entryId
    }
}

public struct LibraryScanEntriesPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct LibraryListSkillDraftsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct LibraryGetSkillDraftPayload: Codable, Sendable {
    public let apiVersion: String?
    public let draftId: String

    public init(apiVersion: String? = nil, draftId: String) {
        self.apiVersion = apiVersion
        self.draftId = draftId
    }
}

public struct LibraryCreateSkillDraftPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let draftId: String?
    public let name: String?
    public let description: String?
    public let requestPrompt: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        draftId: String? = nil,
        name: String? = nil,
        description: String? = nil,
        requestPrompt: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.draftId = draftId
        self.name = name
        self.description = description
        self.requestPrompt = requestPrompt
    }
}

public struct LibraryDeleteSkillDraftPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let draftId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        draftId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.draftId = draftId
    }
}
