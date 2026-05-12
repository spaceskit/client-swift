// SchedulerWorkbenchTypes.swift - Scheduler and Workbench domain types.

import Foundation

public enum SchedulerJobStatus: String, Codable, Sendable {
    case active
    case paused
    case invalid
}

public enum SchedulerRunStatus: String, Codable, Sendable {
    case running
    case completed
    case failed
    case skipped
}

public enum SchedulerRunTrigger: String, Codable, Sendable {
    case scheduled
    case manual
}

public enum SchedulerScheduleKind: String, Codable, Sendable {
    case hourly
    case daily
    case weekly
}

public enum SchedulerActionType: String, Codable, Sendable {
    case spacePrompt = "space_prompt"
}

public enum SchedulerExecutionTargetMode: String, Codable, Sendable {
    case existingSpace = "existing_space"
    case newSpace = "new_space"
}

public enum SchedulerCalendarSyncStatus: String, Codable, Sendable {
    case pending
    case synced
    case error
}

public enum SchedulerCalendarDriftStatus: String, Codable, Sendable {
    case none
    case drifted
}

public enum SchedulerEvalSummaryMode: String, Codable, Sendable {
    case checkpoints
    case finalSummary = "final_summary"
}

public enum SchedulerEvalRecommendationStatus: String, Codable, Sendable {
    case suggested
    case applied
}

public enum SchedulerEvalRecommendationKind: String, Codable, Sendable {
    case flowVariant = "flow_variant"
    case promptPack = "prompt_pack"
    case summaryMode = "summary_mode"
}

public enum SchedulerEvalScenarioStatus: String, Codable, Sendable {
    case pass
    case fail
    case skip
}

public enum SchedulerEvalCheckpointStatus: String, Codable, Sendable {
    case completed
    case failed
    case observed
}

public struct SchedulerSchedulePreset: Codable, Sendable {
    public let kind: SchedulerScheduleKind
    public let intervalHours: Int?
    public let minute: Int
    public let hour: Int?
    public let daysOfWeek: [Int]?

    public init(
        kind: SchedulerScheduleKind,
        intervalHours: Int? = nil,
        minute: Int,
        hour: Int? = nil,
        daysOfWeek: [Int]? = nil
    ) {
        self.kind = kind
        self.intervalHours = intervalHours
        self.minute = minute
        self.hour = hour
        self.daysOfWeek = daysOfWeek
    }
}

public struct SchedulerEvalConfig: Codable, Sendable {
    public let evalDefinitionId: String
    public let scenarioIds: [String]?
    public let promptVariantId: String?
    public let promptPackId: String?
    public let flowVariantId: String?
    public let summaryMode: SchedulerEvalSummaryMode?
    public let selfImproveEnabled: Bool?

    public init(
        evalDefinitionId: String,
        scenarioIds: [String]? = nil,
        promptVariantId: String? = nil,
        promptPackId: String? = nil,
        flowVariantId: String? = nil,
        summaryMode: SchedulerEvalSummaryMode? = nil,
        selfImproveEnabled: Bool? = nil
    ) {
        self.evalDefinitionId = evalDefinitionId
        self.scenarioIds = scenarioIds
        self.promptVariantId = promptVariantId
        self.promptPackId = promptPackId
        self.flowVariantId = flowVariantId
        self.summaryMode = summaryMode
        self.selfImproveEnabled = selfImproveEnabled
    }
}

public struct SchedulerEvalSelfImproveState: Codable, Sendable {
    public let enabled: Bool
    public let appliedRevisionIds: [String]
    public let lastAppliedRunId: String?

    public init(
        enabled: Bool,
        appliedRevisionIds: [String],
        lastAppliedRunId: String? = nil
    ) {
        self.enabled = enabled
        self.appliedRevisionIds = appliedRevisionIds
        self.lastAppliedRunId = lastAppliedRunId
    }
}

public struct SchedulerEvalCheckpoint: Codable, Sendable {
    public let checkpointId: String
    public let kind: String
    public let status: SchedulerEvalCheckpointStatus
    public let actorId: String?
    public let createdAt: String
    public let detail: [String: AnyCodable]?

    public init(
        checkpointId: String,
        kind: String,
        status: SchedulerEvalCheckpointStatus,
        actorId: String? = nil,
        createdAt: String,
        detail: [String: AnyCodable]? = nil
    ) {
        self.checkpointId = checkpointId
        self.kind = kind
        self.status = status
        self.actorId = actorId
        self.createdAt = createdAt
        self.detail = detail
    }
}

public struct SchedulerEvalRecommendation: Codable, Sendable {
    public let recommendationId: String
    public let status: SchedulerEvalRecommendationStatus
    public let kind: SchedulerEvalRecommendationKind
    public let title: String
    public let summary: String?
    public let originatingRunId: String?
    public let promptVariantId: String?
    public let promptPackId: String?
    public let flowVariantId: String?
    public let appliedRevisionId: String?
    public let createdAt: String
    public let detail: [String: AnyCodable]?

    public init(
        recommendationId: String,
        status: SchedulerEvalRecommendationStatus,
        kind: SchedulerEvalRecommendationKind,
        title: String,
        summary: String? = nil,
        originatingRunId: String? = nil,
        promptVariantId: String? = nil,
        promptPackId: String? = nil,
        flowVariantId: String? = nil,
        appliedRevisionId: String? = nil,
        createdAt: String,
        detail: [String: AnyCodable]? = nil
    ) {
        self.recommendationId = recommendationId
        self.status = status
        self.kind = kind
        self.title = title
        self.summary = summary
        self.originatingRunId = originatingRunId
        self.promptVariantId = promptVariantId
        self.promptPackId = promptPackId
        self.flowVariantId = flowVariantId
        self.appliedRevisionId = appliedRevisionId
        self.createdAt = createdAt
        self.detail = detail
    }
}

public struct SchedulerEvalScenarioResult: Codable, Sendable {
    public let scenarioId: String
    public let status: SchedulerEvalScenarioStatus
    public let checkpointCount: Int
    public let failureReason: String?

    public init(
        scenarioId: String,
        status: SchedulerEvalScenarioStatus,
        checkpointCount: Int,
        failureReason: String? = nil
    ) {
        self.scenarioId = scenarioId
        self.status = status
        self.checkpointCount = checkpointCount
        self.failureReason = failureReason
    }
}

public struct SchedulerEvalArtifactRef: Codable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case space
        case turn
        case schedulerRun = "scheduler_run"
    }

    public let kind: Kind
    public let id: String
    public let label: String?

    public init(
        kind: Kind,
        id: String,
        label: String? = nil
    ) {
        self.kind = kind
        self.id = id
        self.label = label
    }
}

public struct SchedulerEvalRun: Codable, Sendable {
    public let evalRunId: String
    public let evalDefinitionId: String
    public let scenarioIds: [String]
    public let promptVariantId: String?
    public let promptPackId: String?
    public let flowVariantId: String?
    public let summaryMode: SchedulerEvalSummaryMode
    public let selfImproveEnabled: Bool
    public let spaceId: String?
    public let spaceUid: String?
    public let rootTurnId: String?
    public let finalSummaryText: String?
    public let artifactRefs: [SchedulerEvalArtifactRef]
    public let checkpoints: [SchedulerEvalCheckpoint]
    public let scenarioResults: [SchedulerEvalScenarioResult]
    public let recommendations: [SchedulerEvalRecommendation]

    public init(
        evalRunId: String,
        evalDefinitionId: String,
        scenarioIds: [String],
        promptVariantId: String? = nil,
        promptPackId: String? = nil,
        flowVariantId: String? = nil,
        summaryMode: SchedulerEvalSummaryMode,
        selfImproveEnabled: Bool,
        spaceId: String? = nil,
        spaceUid: String? = nil,
        rootTurnId: String? = nil,
        finalSummaryText: String? = nil,
        artifactRefs: [SchedulerEvalArtifactRef],
        checkpoints: [SchedulerEvalCheckpoint],
        scenarioResults: [SchedulerEvalScenarioResult],
        recommendations: [SchedulerEvalRecommendation]
    ) {
        self.evalRunId = evalRunId
        self.evalDefinitionId = evalDefinitionId
        self.scenarioIds = scenarioIds
        self.promptVariantId = promptVariantId
        self.promptPackId = promptPackId
        self.flowVariantId = flowVariantId
        self.summaryMode = summaryMode
        self.selfImproveEnabled = selfImproveEnabled
        self.spaceId = spaceId
        self.spaceUid = spaceUid
        self.rootTurnId = rootTurnId
        self.finalSummaryText = finalSummaryText
        self.artifactRefs = artifactRefs
        self.checkpoints = checkpoints
        self.scenarioResults = scenarioResults
        self.recommendations = recommendations
    }
}

public struct SchedulerEvalDomain: Codable, Sendable {
    public let domainId: String
    public let description: String?
    public let scenarioIds: [String]

    public init(
        domainId: String,
        description: String? = nil,
        scenarioIds: [String]
    ) {
        self.domainId = domainId
        self.description = description
        self.scenarioIds = scenarioIds
    }
}

public struct SchedulerEvalDefinition: Codable, Sendable {
    public let evalDefinitionId: String
    public let suiteId: String
    public let description: String?
    public let domainIds: [String]
    public let scenarioIds: [String]
    public let domains: [SchedulerEvalDomain]

    public init(
        evalDefinitionId: String,
        suiteId: String,
        description: String? = nil,
        domainIds: [String],
        scenarioIds: [String],
        domains: [SchedulerEvalDomain]
    ) {
        self.evalDefinitionId = evalDefinitionId
        self.suiteId = suiteId
        self.description = description
        self.domainIds = domainIds
        self.scenarioIds = scenarioIds
        self.domains = domains
    }
}

public struct SchedulerAction: Codable, Sendable {
    public let type: SchedulerActionType
    public let promptText: String
    public let targetAgentId: String?

    public init(
        type: SchedulerActionType,
        promptText: String,
        targetAgentId: String? = nil
    ) {
        self.type = type
        self.promptText = promptText
        self.targetAgentId = targetAgentId
    }
}

public struct SchedulerExecutionTarget: Codable, Sendable {
    public let mode: SchedulerExecutionTargetMode

    public init(mode: SchedulerExecutionTargetMode) {
        self.mode = mode
    }
}

public struct SchedulerCalendarBinding: Codable, Sendable {
    public let providerId: String
    public let calendarId: String
    public let eventId: String?
    public let syncStatus: SchedulerCalendarSyncStatus?
    public let driftStatus: SchedulerCalendarDriftStatus?
    public let driftMessage: String?
    public let lastSyncedAt: String?

    public init(
        providerId: String,
        calendarId: String,
        eventId: String? = nil,
        syncStatus: SchedulerCalendarSyncStatus? = nil,
        driftStatus: SchedulerCalendarDriftStatus? = nil,
        driftMessage: String? = nil,
        lastSyncedAt: String? = nil
    ) {
        self.providerId = providerId
        self.calendarId = calendarId
        self.eventId = eventId
        self.syncStatus = syncStatus
        self.driftStatus = driftStatus
        self.driftMessage = driftMessage
        self.lastSyncedAt = lastSyncedAt
    }
}

public struct SchedulerLinkedSpace: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String
    public let name: String
    public let isPrimary: Bool
    public let linkedAt: String
}

public struct SchedulerJob: Codable, Sendable {
    public let jobId: String
    public let name: String
    public let status: SchedulerJobStatus
    public let enabled: Bool
    public let cronExpression: String
    public let schedulePreset: SchedulerSchedulePreset
    public let timezone: String
    public let action: SchedulerAction
    public let primarySpaceId: String?
    public let invalidReason: String?
    public let nextRunAt: String?
    public let lastRunAt: String?
    public let lastRunStatus: SchedulerRunStatus?
    public let lastErrorCode: String?
    public let lastErrorMessage: String?
    public let createdByPrincipalId: String
    public let createdAt: String
    public let updatedAt: String
    public let linkedSpaces: [SchedulerLinkedSpace]
    public let executionTarget: SchedulerExecutionTarget
    public let calendarBinding: SchedulerCalendarBinding?
    public let evalConfig: SchedulerEvalConfig?
    public let evalSelfImproveState: SchedulerEvalSelfImproveState?
}

public struct SchedulerJobRun: Codable, Sendable {
    public let runId: String
    public let jobId: String
    public let trigger: SchedulerRunTrigger
    public let status: SchedulerRunStatus
    public let commandId: String?
    public let scheduledFor: String?
    public let startedAt: String?
    public let finishedAt: String?
    public let skipReason: String?
    public let errorCode: String?
    public let errorMessage: String?
    public let result: [String: AnyCodable]?
    public let evalRun: SchedulerEvalRun?
}

public struct SchedulerDeleteJobResult: Codable, Sendable {
    public let jobId: String
    public let deleted: Bool
}

public struct SchedulerListRunsResult: Codable, Sendable {
    public let runs: [SchedulerJobRun]
    public let total: Int
    public let nextOffset: Int?
}

public struct SchedulerRunNowResult: Codable, Sendable {
    public let run: SchedulerJobRun
    public let job: SchedulerJob
}
