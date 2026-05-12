// SpaceResourceTurnProtocolPayloads.swift - Space resource, workspace, and turn payloads.

import Foundation

public struct SpaceListAgentAssignmentsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceGetMcpEndpointPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceSetMcpEndpointPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let transport: SpaceMcpTransport
    public let endpoint: String
    public let args: [String]?
    public let secretRef: String?
    public let enabled: Bool?

    public init(
        apiVersion: String? = nil,
        spaceId: String,
        transport: SpaceMcpTransport,
        endpoint: String,
        args: [String]? = nil,
        secretRef: String? = nil,
        enabled: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.transport = transport
        self.endpoint = endpoint
        self.args = args
        self.secretRef = secretRef
        self.enabled = enabled
    }
}

public struct SpaceClearMcpEndpointPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceAddSkillPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let skillId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        skillId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.skillId = skillId
    }
}

public struct SpaceRemoveSkillPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let skillId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        skillId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.skillId = skillId
    }
}

public struct SpaceListSkillsPayload: Codable, Sendable {
  public let apiVersion: String?
  public let spaceId: String

  public init(apiVersion: String? = nil, spaceId: String) {
    self.apiVersion = apiVersion
    self.spaceId = spaceId
  }
}

public struct SpaceGetWorkspacePayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceSetWorkspacePayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String
    public let workspaceRoot: String?

    public init(apiVersion: String? = nil, spaceId: String, workspaceRoot: String? = nil) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.workspaceRoot = workspaceRoot
    }
}

public struct SpaceOpenWorkspacePayload: Codable, Sendable {
    public let apiVersion: String?
    public let workspaceRoot: String

    public init(apiVersion: String? = nil, workspaceRoot: String) {
        self.apiVersion = apiVersion
        self.workspaceRoot = workspaceRoot
    }
}

public struct SpaceAddResourcePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let resourceId: String?
    public let spaceId: String
    public let uri: String
    public let type: String
    public let label: String?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        resourceId: String? = nil,
        spaceId: String,
        uri: String,
        type: String,
        label: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.resourceId = resourceId
        self.spaceId = spaceId
        self.uri = uri
        self.type = type
        self.label = label
    }
}

public struct SpaceRemoveResourcePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let spaceId: String
    public let resourceId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        spaceId: String,
        resourceId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.spaceId = spaceId
        self.resourceId = resourceId
    }
}

public struct SpaceListResourcesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String

    public init(apiVersion: String? = nil, spaceId: String) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
    }
}

public struct SpaceListTurnsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String?
    public let spaceUid: String?
    public let limit: Int
    public let offset: Int
    public let lastSeenTurnId: String?

    public init(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        spaceUid: String? = nil,
        limit: Int,
        offset: Int,
        lastSeenTurnId: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.limit = limit
        self.offset = offset
        self.lastSeenTurnId = lastSeenTurnId
    }
}

public struct SpaceListOrchestrationJournalPayload: Codable, Sendable {
    public let apiVersion: String?
    public let spaceId: String?
    public let spaceUid: String?
    public let turnId: String?
    public let limit: Int
    public let offset: Int

    public init(
        apiVersion: String? = nil,
        spaceId: String? = nil,
        spaceUid: String? = nil,
        turnId: String? = nil,
        limit: Int,
        offset: Int
    ) {
        self.apiVersion = apiVersion
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.turnId = turnId
        self.limit = limit
        self.offset = offset
    }
}
