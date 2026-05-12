// Scheduler and workbench protocol payloads for Spaceskit Client SDK.

import Foundation

// MARK: - Scheduler Payloads
public struct SchedulerCreateJobPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let name: String
    public let timezone: String
    public let schedulePreset: SchedulerSchedulePreset
    public let action: SchedulerAction
    public let primarySpaceId: String
    public let relatedSpaceIds: [String]?
    public let executionTarget: SchedulerExecutionTarget?
    public let calendarBinding: SchedulerCalendarBinding?
    public let evalConfig: SchedulerEvalConfig??

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        name: String,
        timezone: String,
        schedulePreset: SchedulerSchedulePreset,
        action: SchedulerAction,
        primarySpaceId: String,
        relatedSpaceIds: [String]? = nil,
        executionTarget: SchedulerExecutionTarget? = nil,
        calendarBinding: SchedulerCalendarBinding? = nil,
        evalConfig: SchedulerEvalConfig?? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.name = name
        self.timezone = timezone
        self.schedulePreset = schedulePreset
        self.action = action
        self.primarySpaceId = primarySpaceId
        self.relatedSpaceIds = relatedSpaceIds
        self.executionTarget = executionTarget
        self.calendarBinding = calendarBinding
        self.evalConfig = evalConfig
    }
}

public struct SchedulerCreateJobResponsePayload: Codable, Sendable {
    public let job: SchedulerJob
}

public struct SchedulerGetJobPayload: Codable, Sendable {
    public let apiVersion: String?
    public let jobId: String

    public init(apiVersion: String? = nil, jobId: String) {
        self.apiVersion = apiVersion
        self.jobId = jobId
    }
}

public struct SchedulerGetJobResponsePayload: Codable, Sendable {
    public let job: SchedulerJob
}

public struct SchedulerListJobsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let statuses: [SchedulerJobStatus]?
    public let gatewayId: String?
    public let limit: Int?

    public init(
        apiVersion: String? = nil,
        statuses: [SchedulerJobStatus]? = nil,
        gatewayId: String? = nil,
        limit: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.statuses = statuses
        self.gatewayId = gatewayId
        self.limit = limit
    }
}

public struct SchedulerListJobsResponsePayload: Codable, Sendable {
    public let jobs: [SchedulerJob]
}

public struct SchedulerListEvalDefinitionsPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct SchedulerListEvalDefinitionsResponsePayload: Codable, Sendable {
    public let definitions: [SchedulerEvalDefinition]
}

public struct SchedulerUpdateJobPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let jobId: String
    public let name: String?
    public let status: SchedulerJobStatus?
    public let timezone: String?
    public let schedulePreset: SchedulerSchedulePreset?
    public let action: SchedulerAction?
    public let primarySpaceId: String?
    public let relatedSpaceIds: [String]?
    public let executionTarget: SchedulerExecutionTarget?
    public let calendarBinding: SchedulerCalendarBinding?
    public let evalConfig: SchedulerEvalConfig??

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        jobId: String,
        name: String? = nil,
        status: SchedulerJobStatus? = nil,
        timezone: String? = nil,
        schedulePreset: SchedulerSchedulePreset? = nil,
        action: SchedulerAction? = nil,
        primarySpaceId: String? = nil,
        relatedSpaceIds: [String]? = nil,
        executionTarget: SchedulerExecutionTarget? = nil,
        calendarBinding: SchedulerCalendarBinding? = nil,
        evalConfig: SchedulerEvalConfig?? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.jobId = jobId
        self.name = name
        self.status = status
        self.timezone = timezone
        self.schedulePreset = schedulePreset
        self.action = action
        self.primarySpaceId = primarySpaceId
        self.relatedSpaceIds = relatedSpaceIds
        self.executionTarget = executionTarget
        self.calendarBinding = calendarBinding
        self.evalConfig = evalConfig
    }
}

public struct SchedulerUpdateJobResponsePayload: Codable, Sendable {
    public let job: SchedulerJob
}

public struct SchedulerDeleteJobPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let jobId: String

    public init(apiVersion: String? = nil, idempotencyKey: String? = nil, jobId: String) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.jobId = jobId
    }
}

public struct SchedulerDeleteJobResponsePayload: Codable, Sendable {
    public let jobId: String
    public let deleted: Bool
}

public struct SchedulerLinkSpacePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let jobId: String
    public let spaceId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        jobId: String,
        spaceId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.jobId = jobId
        self.spaceId = spaceId
    }
}

public struct SchedulerLinkSpaceResponsePayload: Codable, Sendable {
    public let job: SchedulerJob
}

public struct SchedulerUnlinkSpacePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let jobId: String
    public let spaceId: String

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        jobId: String,
        spaceId: String
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.jobId = jobId
        self.spaceId = spaceId
    }
}

public struct SchedulerUnlinkSpaceResponsePayload: Codable, Sendable {
    public let job: SchedulerJob
}

public struct SchedulerListRunsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let jobId: String
    public let limit: Int?
    public let offset: Int?

    public init(
        apiVersion: String? = nil,
        jobId: String,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.jobId = jobId
        self.limit = limit
        self.offset = offset
    }
}

public struct SchedulerListRunsResponsePayload: Codable, Sendable {
    public let runs: [SchedulerJobRun]
    public let total: Int
    public let nextOffset: Int?
}

public struct SchedulerRunNowPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let jobId: String

    public init(apiVersion: String? = nil, idempotencyKey: String? = nil, jobId: String) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.jobId = jobId
    }
}

public struct SchedulerRunNowResponsePayload: Codable, Sendable {
    public let run: SchedulerJobRun
    public let job: SchedulerJob
}
