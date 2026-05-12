// WorkbenchTypes.swift - Workbench domain types.

import Foundation

public enum WorkbenchExecutionMode: String, Codable, Sendable {
    case supervised
    case autonomous
}

public enum WorkbenchBatchStatus: String, Codable, Sendable {
    case draft
    case queued
    case running
    case completed
    case cancelled
}

public enum WorkbenchRunStatus: String, Codable, Sendable {
    case queued
    case awaitingReview = "awaiting_review"
    case running
    case completed
    case failed
    case cancelled
}

public enum WorkbenchRunStage: String, Codable, Sendable {
    case intake
    case plan
    case execute
    case verify
    case reviewGate = "review_gate"
    case land
    case report
}

public enum WorkbenchApprovalState: String, Codable, Sendable {
    case pending
    case approved
    case rejected
    case notRequired = "not_required"
}

public enum WorkbenchVerificationMode: String, Codable, Sendable {
    case machineReadable = "machine_readable"
    case reviewOnly = "review_only"
}

public enum WorkbenchVerificationSuiteStatus: String, Codable, Sendable {
    case pending
    case running
    case passed
    case failed
    case skipped
}

public enum WorkbenchVerificationResultStatus: String, Codable, Sendable {
    case pending
    case passed
    case failed
}

public enum WorkbenchLandingStatus: String, Codable, Sendable {
    case notStarted = "not_started"
    case blocked
    case landed
}

public struct WorkbenchExecutionModeEligibility: Codable, Sendable {
    public let supervised: Bool
    public let autonomous: Bool
}

public struct WorkbenchQueueItem: Codable, Sendable {
    public let queueItemId: String
    public let queueIndex: Int
    public let title: String
    public let type: String
    public let status: String
    public let nextAction: String
    public let taskFilePath: String
    public let delegation: String
    public let parallelKeys: [String]
    public let aiShippable: Bool
    public let executionModeEligibility: WorkbenchExecutionModeEligibility
    public let verificationMode: WorkbenchVerificationMode
    public let executionModeBlockers: [String]
    public let products: [String]
    public let verificationCommands: [String]
}

public struct WorkbenchBatch: Codable, Sendable {
    public let batchId: String
    public let name: String
    public let status: WorkbenchBatchStatus
    public let executionMode: WorkbenchExecutionMode
    public let queueItemIds: [String]
    public let createdByPrincipalId: String
    public let createdAt: String
    public let updatedAt: String
}

public struct WorkbenchWorktreeRef: Codable, Sendable {
    public let path: String
    public let branchName: String
    public let baseBranchName: String
    public let createdAt: String
}

public struct WorkbenchRepoTouch: Codable, Sendable {
    public let repoId: String
    public let repoPath: String
    public let kind: String
    public let committed: Bool
}

public struct WorkbenchVerificationSuite: Codable, Sendable {
    public let suiteId: String
    public let name: String
    public let command: String
    public let status: WorkbenchVerificationSuiteStatus
    public let startedAt: String?
    public let completedAt: String?
    public let exitCode: Int?
    public let durationMs: Int?
    public let logArtifactId: String?
    public let summary: String?
}

public struct WorkbenchVerificationResult: Codable, Sendable {
    public let status: WorkbenchVerificationResultStatus
    public let summary: String?
    public let completedAt: String?
}

public struct WorkbenchLandingResult: Codable, Sendable {
    public let status: WorkbenchLandingStatus
    public let merged: Bool?
    public let summary: String?
    public let completedAt: String?
}

public enum WorkbenchExecutionContextStage: String, Codable, Sendable {
    case planning
    case implementation
    case verification
    case completed
    case failed
    case paused
}

public struct WorkbenchExecutionContext: Codable, Sendable {
    public let spaceId: String
    public let spaceUid: String?
    public let spaceName: String
    public let planningTurnId: String?
    public let implementationTurnId: String?
    public let stage: WorkbenchExecutionContextStage
}

public struct WorkbenchRun: Codable, Sendable {
    public let runId: String
    public let batchId: String?
    public let queueItemId: String
    public let queueItemPath: String
    public let status: WorkbenchRunStatus
    public let currentStage: WorkbenchRunStage
    public let executionMode: WorkbenchExecutionMode
    public let approvalState: WorkbenchApprovalState
    public let worktree: WorkbenchWorktreeRef?
    public let touchedRepos: [WorkbenchRepoTouch]
    public let verificationMode: WorkbenchVerificationMode
    public let executionModeBlockers: [String]
    public let verificationSuites: [WorkbenchVerificationSuite]
    public let verificationResult: WorkbenchVerificationResult?
    public let landingResult: WorkbenchLandingResult?
    public let executionContext: WorkbenchExecutionContext?
    public let createdByPrincipalId: String
    public let createdAt: String
    public let updatedAt: String
    public let startedAt: String?
    public let finishedAt: String?
    public let lastErrorCode: String?
    public let lastErrorMessage: String?
}

public struct WorkbenchArtifact: Codable, Sendable {
    public let artifactId: String
    public let runId: String
    public let kind: String
    public let title: String
    public let contentType: String
    public let contentText: String
    public let createdAt: String
}

public struct WorkbenchPolicy: Codable, Sendable {
    public let defaultExecutionMode: WorkbenchExecutionMode
    public let autonomousEnabled: Bool
    public let maxParallelRuns: Int
    public let requireExplicitAutonomousOptIn: Bool
    public let requireAiShippableForAutonomous: Bool
    public let updatedAt: String
}

public struct WorkbenchSetModeResult: Codable, Sendable {
    public let run: WorkbenchRun?
    public let batch: WorkbenchBatch?
}
