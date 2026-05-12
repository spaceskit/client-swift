// Scheduler and workbench GatewayClient APIs.

import Foundation

extension GatewayClient {
    public func createSchedulerJob(_ payload: SchedulerCreateJobPayload) async throws -> SchedulerJob {
        let data = try await sendAndWait(type: MessageType.schedulerCreateJob, payload: payload)
        let response = try decoder.decode(SchedulerCreateJobResponsePayload.self, from: data)
        return response.job
    }

    public func getSchedulerJob(
        jobId: String,
        apiVersion: String? = nil
    ) async throws -> SchedulerJob {
        let payload = SchedulerGetJobPayload(apiVersion: apiVersion, jobId: jobId)
        let data = try await sendAndWait(type: MessageType.schedulerGetJob, payload: payload)
        let response = try decoder.decode(SchedulerGetJobResponsePayload.self, from: data)
        return response.job
    }

    public func listSchedulerJobs(payload: SchedulerListJobsPayload = .init(
        apiVersion: nil,
        statuses: nil,
        gatewayId: nil,
        limit: nil
    )) async throws -> [SchedulerJob] {
        let data = try await sendAndWait(type: MessageType.schedulerListJobs, payload: payload)
        let response = try decoder.decode(SchedulerListJobsResponsePayload.self, from: data)
        return response.jobs
    }

    public func listSchedulerEvalDefinitions(
        payload: SchedulerListEvalDefinitionsPayload = .init()
    ) async throws -> [SchedulerEvalDefinition] {
        let data = try await sendAndWait(type: MessageType.schedulerListEvalDefinitions, payload: payload)
        let response = try decoder.decode(SchedulerListEvalDefinitionsResponsePayload.self, from: data)
        return response.definitions
    }

    public func updateSchedulerJob(_ payload: SchedulerUpdateJobPayload) async throws -> SchedulerJob {
        let data = try await sendAndWait(type: MessageType.schedulerUpdateJob, payload: payload)
        let response = try decoder.decode(SchedulerUpdateJobResponsePayload.self, from: data)
        return response.job
    }

    public func deleteSchedulerJob(_ payload: SchedulerDeleteJobPayload) async throws -> SchedulerDeleteJobResult {
        let data = try await sendAndWait(type: MessageType.schedulerDeleteJob, payload: payload)
        let response = try decoder.decode(SchedulerDeleteJobResponsePayload.self, from: data)
        return SchedulerDeleteJobResult(jobId: response.jobId, deleted: response.deleted)
    }

    public func linkSchedulerJobSpace(_ payload: SchedulerLinkSpacePayload) async throws -> SchedulerJob {
        let data = try await sendAndWait(type: MessageType.schedulerLinkSpace, payload: payload)
        let response = try decoder.decode(SchedulerLinkSpaceResponsePayload.self, from: data)
        return response.job
    }

    public func unlinkSchedulerJobSpace(_ payload: SchedulerUnlinkSpacePayload) async throws -> SchedulerJob {
        let data = try await sendAndWait(type: MessageType.schedulerUnlinkSpace, payload: payload)
        let response = try decoder.decode(SchedulerUnlinkSpaceResponsePayload.self, from: data)
        return response.job
    }

    public func listSchedulerJobRuns(_ payload: SchedulerListRunsPayload) async throws -> SchedulerListRunsResult {
        let data = try await sendAndWait(type: MessageType.schedulerListRuns, payload: payload)
        let response = try decoder.decode(SchedulerListRunsResponsePayload.self, from: data)
        return SchedulerListRunsResult(runs: response.runs, total: response.total, nextOffset: response.nextOffset)
    }

    public func runSchedulerJobNow(_ payload: SchedulerRunNowPayload) async throws -> SchedulerRunNowResult {
        let data = try await sendAndWait(type: MessageType.schedulerRunNow, payload: payload)
        let response = try decoder.decode(SchedulerRunNowResponsePayload.self, from: data)
        return SchedulerRunNowResult(run: response.run, job: response.job)
    }

    public func listWorkbenchQueue(
        payload: WorkbenchListQueuePayload = .init()
    ) async throws -> [WorkbenchQueueItem] {
        let data = try await sendAndWait(type: MessageType.workbenchListQueue, payload: payload)
        let response = try decoder.decode(WorkbenchListQueueResponsePayload.self, from: data)
        return response.items
    }

    public func getWorkbenchQueueItem(_ payload: WorkbenchGetQueueItemPayload) async throws -> WorkbenchQueueItem {
        let data = try await sendAndWait(type: MessageType.workbenchGetQueueItem, payload: payload)
        let response = try decoder.decode(WorkbenchGetQueueItemResponsePayload.self, from: data)
        return response.item
    }

    public func createWorkbenchBatch(_ payload: WorkbenchCreateBatchPayload) async throws -> WorkbenchBatch {
        let data = try await sendAndWait(type: MessageType.workbenchCreateBatch, payload: payload)
        let response = try decoder.decode(WorkbenchCreateBatchResponsePayload.self, from: data)
        return response.batch
    }

    public func listWorkbenchBatches(
        payload: WorkbenchListBatchesPayload = .init()
    ) async throws -> [WorkbenchBatch] {
        let data = try await sendAndWait(type: MessageType.workbenchListBatches, payload: payload)
        let response = try decoder.decode(WorkbenchListBatchesResponsePayload.self, from: data)
        return response.batches
    }

    public func updateWorkbenchBatch(_ payload: WorkbenchUpdateBatchPayload) async throws -> WorkbenchBatch {
        let data = try await sendAndWait(type: MessageType.workbenchUpdateBatch, payload: payload)
        let response = try decoder.decode(WorkbenchUpdateBatchResponsePayload.self, from: data)
        return response.batch
    }

    public func startWorkbenchRun(_ payload: WorkbenchStartRunPayload) async throws -> WorkbenchRun {
        let data = try await sendAndWait(type: MessageType.workbenchStartRun, payload: payload)
        let response = try decoder.decode(WorkbenchStartRunResponsePayload.self, from: data)
        return response.run
    }

    public func retryWorkbenchRun(_ payload: WorkbenchRetryRunPayload) async throws -> WorkbenchRun {
        let data = try await sendAndWait(type: MessageType.workbenchRetryRun, payload: payload)
        let response = try decoder.decode(WorkbenchRetryRunResponsePayload.self, from: data)
        return response.run
    }

    public func cancelWorkbenchRun(_ payload: WorkbenchCancelRunPayload) async throws -> WorkbenchRun {
        let data = try await sendAndWait(type: MessageType.workbenchCancelRun, payload: payload)
        let response = try decoder.decode(WorkbenchCancelRunResponsePayload.self, from: data)
        return response.run
    }

    public func listWorkbenchRuns(
        payload: WorkbenchListRunsPayload = .init()
    ) async throws -> [WorkbenchRun] {
        let data = try await sendAndWait(type: MessageType.workbenchListRuns, payload: payload)
        let response = try decoder.decode(WorkbenchListRunsResponsePayload.self, from: data)
        return response.runs
    }

    public func getWorkbenchRun(_ payload: WorkbenchGetRunPayload) async throws -> WorkbenchRun {
        let data = try await sendAndWait(type: MessageType.workbenchGetRun, payload: payload)
        let response = try decoder.decode(WorkbenchGetRunResponsePayload.self, from: data)
        return response.run
    }

    public func approveWorkbenchStage(_ payload: WorkbenchApproveStagePayload) async throws -> WorkbenchRun {
        let data = try await sendAndWait(type: MessageType.workbenchApproveStage, payload: payload)
        let response = try decoder.decode(WorkbenchApproveStageResponsePayload.self, from: data)
        return response.run
    }

    public func rejectWorkbenchStage(_ payload: WorkbenchRejectStagePayload) async throws -> WorkbenchRun {
        let data = try await sendAndWait(type: MessageType.workbenchRejectStage, payload: payload)
        let response = try decoder.decode(WorkbenchRejectStageResponsePayload.self, from: data)
        return response.run
    }

    public func setWorkbenchMode(_ payload: WorkbenchSetModePayload) async throws -> WorkbenchSetModeResult {
        let data = try await sendAndWait(type: MessageType.workbenchSetMode, payload: payload)
        let response = try decoder.decode(WorkbenchSetModeResponsePayload.self, from: data)
        return WorkbenchSetModeResult(run: response.run, batch: response.batch)
    }

    public func listWorkbenchArtifacts(_ payload: WorkbenchListArtifactsPayload) async throws -> [WorkbenchArtifact] {
        let data = try await sendAndWait(type: MessageType.workbenchListArtifacts, payload: payload)
        let response = try decoder.decode(WorkbenchListArtifactsResponsePayload.self, from: data)
        return response.artifacts
    }

    public func getWorkbenchPolicy(
        payload: WorkbenchGetPolicyPayload = .init()
    ) async throws -> WorkbenchPolicy {
        let data = try await sendAndWait(type: MessageType.workbenchGetPolicy, payload: payload)
        let response = try decoder.decode(WorkbenchGetPolicyResponsePayload.self, from: data)
        return response.policy
    }

    public func updateWorkbenchPolicy(_ payload: WorkbenchUpdatePolicyPayload) async throws -> WorkbenchPolicy {
        let data = try await sendAndWait(type: MessageType.workbenchUpdatePolicy, payload: payload)
        let response = try decoder.decode(WorkbenchUpdatePolicyResponsePayload.self, from: data)
        return response.policy
    }

}
