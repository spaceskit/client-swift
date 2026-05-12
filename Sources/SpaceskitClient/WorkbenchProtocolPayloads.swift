// WorkbenchProtocolPayloads.swift - Workbench queue, batch, run, artifact, and policy payloads.

import Foundation

public struct WorkbenchListQueuePayload: Codable, Sendable {
    public let apiVersion: String?
    public let limit: Int?

    public init(apiVersion: String? = nil, limit: Int? = nil) {
        self.apiVersion = apiVersion
        self.limit = limit
    }
}

public struct WorkbenchListQueueResponsePayload: Codable, Sendable {
    public let items: [WorkbenchQueueItem]
}

public struct WorkbenchGetQueueItemPayload: Codable, Sendable {
    public let apiVersion: String?
    public let queueItemId: String

    public init(apiVersion: String? = nil, queueItemId: String) {
        self.apiVersion = apiVersion
        self.queueItemId = queueItemId
    }
}

public struct WorkbenchGetQueueItemResponsePayload: Codable, Sendable {
    public let item: WorkbenchQueueItem
}

public struct WorkbenchCreateBatchPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let name: String
    public let queueItemIds: [String]
    public let executionMode: WorkbenchExecutionMode?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        name: String,
        queueItemIds: [String],
        executionMode: WorkbenchExecutionMode? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.name = name
        self.queueItemIds = queueItemIds
        self.executionMode = executionMode
    }
}

public struct WorkbenchCreateBatchResponsePayload: Codable, Sendable {
    public let batch: WorkbenchBatch
}

public struct WorkbenchListBatchesPayload: Codable, Sendable {
    public let apiVersion: String?
    public let limit: Int?

    public init(apiVersion: String? = nil, limit: Int? = nil) {
        self.apiVersion = apiVersion
        self.limit = limit
    }
}

public struct WorkbenchListBatchesResponsePayload: Codable, Sendable {
    public let batches: [WorkbenchBatch]
}

public struct WorkbenchUpdateBatchPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let batchId: String
    public let name: String?
    public let queueItemIds: [String]?
    public let executionMode: WorkbenchExecutionMode?
    public let status: WorkbenchBatchStatus?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        batchId: String,
        name: String? = nil,
        queueItemIds: [String]? = nil,
        executionMode: WorkbenchExecutionMode? = nil,
        status: WorkbenchBatchStatus? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.batchId = batchId
        self.name = name
        self.queueItemIds = queueItemIds
        self.executionMode = executionMode
        self.status = status
    }
}

public struct WorkbenchUpdateBatchResponsePayload: Codable, Sendable {
    public let batch: WorkbenchBatch
}

public struct WorkbenchStartRunPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let queueItemId: String
    public let batchId: String?
    public let executionMode: WorkbenchExecutionMode?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        queueItemId: String,
        batchId: String? = nil,
        executionMode: WorkbenchExecutionMode? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.queueItemId = queueItemId
        self.batchId = batchId
        self.executionMode = executionMode
    }
}

public struct WorkbenchStartRunResponsePayload: Codable, Sendable {
    public let run: WorkbenchRun
}

public struct WorkbenchRetryRunPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let runId: String

    public init(apiVersion: String? = nil, idempotencyKey: String? = nil, runId: String) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.runId = runId
    }
}

public struct WorkbenchRetryRunResponsePayload: Codable, Sendable {
    public let run: WorkbenchRun
}

public struct WorkbenchCancelRunPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let runId: String

    public init(apiVersion: String? = nil, idempotencyKey: String? = nil, runId: String) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.runId = runId
    }
}

public struct WorkbenchCancelRunResponsePayload: Codable, Sendable {
    public let run: WorkbenchRun
}

public struct WorkbenchListRunsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let batchId: String?
    public let queueItemId: String?
    public let limit: Int?

    public init(
        apiVersion: String? = nil,
        batchId: String? = nil,
        queueItemId: String? = nil,
        limit: Int? = nil
    ) {
        self.apiVersion = apiVersion
        self.batchId = batchId
        self.queueItemId = queueItemId
        self.limit = limit
    }
}

public struct WorkbenchListRunsResponsePayload: Codable, Sendable {
    public let runs: [WorkbenchRun]
}

public struct WorkbenchGetRunPayload: Codable, Sendable {
    public let apiVersion: String?
    public let runId: String

    public init(apiVersion: String? = nil, runId: String) {
        self.apiVersion = apiVersion
        self.runId = runId
    }
}

public struct WorkbenchGetRunResponsePayload: Codable, Sendable {
    public let run: WorkbenchRun
}

public struct WorkbenchApproveStagePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let runId: String
    public let stage: WorkbenchRunStage?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        runId: String,
        stage: WorkbenchRunStage? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.runId = runId
        self.stage = stage
    }
}

public struct WorkbenchApproveStageResponsePayload: Codable, Sendable {
    public let run: WorkbenchRun
}

public struct WorkbenchRejectStagePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let runId: String
    public let stage: WorkbenchRunStage?
    public let reason: String?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        runId: String,
        stage: WorkbenchRunStage? = nil,
        reason: String? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.runId = runId
        self.stage = stage
        self.reason = reason
    }
}

public struct WorkbenchRejectStageResponsePayload: Codable, Sendable {
    public let run: WorkbenchRun
}

public struct WorkbenchSetModePayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let runId: String?
    public let batchId: String?
    public let executionMode: WorkbenchExecutionMode

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        runId: String? = nil,
        batchId: String? = nil,
        executionMode: WorkbenchExecutionMode
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.runId = runId
        self.batchId = batchId
        self.executionMode = executionMode
    }
}

public struct WorkbenchSetModeResponsePayload: Codable, Sendable {
    public let run: WorkbenchRun?
    public let batch: WorkbenchBatch?
}

public struct WorkbenchListArtifactsPayload: Codable, Sendable {
    public let apiVersion: String?
    public let runId: String

    public init(apiVersion: String? = nil, runId: String) {
        self.apiVersion = apiVersion
        self.runId = runId
    }
}

public struct WorkbenchListArtifactsResponsePayload: Codable, Sendable {
    public let artifacts: [WorkbenchArtifact]
}

public struct WorkbenchGetPolicyPayload: Codable, Sendable {
    public let apiVersion: String?

    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

public struct WorkbenchGetPolicyResponsePayload: Codable, Sendable {
    public let policy: WorkbenchPolicy
}

public struct WorkbenchUpdatePolicyPayload: Codable, Sendable {
    public let apiVersion: String?
    public let idempotencyKey: String?
    public let defaultExecutionMode: WorkbenchExecutionMode?
    public let autonomousEnabled: Bool?
    public let maxParallelRuns: Int?
    public let requireExplicitAutonomousOptIn: Bool?
    public let requireAiShippableForAutonomous: Bool?

    public init(
        apiVersion: String? = nil,
        idempotencyKey: String? = nil,
        defaultExecutionMode: WorkbenchExecutionMode? = nil,
        autonomousEnabled: Bool? = nil,
        maxParallelRuns: Int? = nil,
        requireExplicitAutonomousOptIn: Bool? = nil,
        requireAiShippableForAutonomous: Bool? = nil
    ) {
        self.apiVersion = apiVersion
        self.idempotencyKey = idempotencyKey
        self.defaultExecutionMode = defaultExecutionMode
        self.autonomousEnabled = autonomousEnabled
        self.maxParallelRuns = maxParallelRuns
        self.requireExplicitAutonomousOptIn = requireExplicitAutonomousOptIn
        self.requireAiShippableForAutonomous = requireAiShippableForAutonomous
    }
}

public struct WorkbenchUpdatePolicyResponsePayload: Codable, Sendable {
    public let policy: WorkbenchPolicy
}
