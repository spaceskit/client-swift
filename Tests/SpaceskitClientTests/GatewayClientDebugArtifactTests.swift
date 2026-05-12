import XCTest
@testable import SpaceskitClient

final class GatewayClientDebugArtifactTests: GatewayClientTestCase {

    func testSpaceTurnTraceDecodingDefaultsExecutionRunsWhenMissing() throws {
        let json = """
        {
            "spaceId": "space-1",
            "turnId": "turn-1",
            "total": 0,
            "events": [],
            "toolCalls": [],
            "activities": [],
            "artifactIds": []
        }
        """

        let trace = try JSONDecoder().decode(SpaceTurnTrace.self, from: Data(json.utf8))

        XCTAssertEqual(trace.spaceId, "space-1")
        XCTAssertEqual(trace.turnId, "turn-1")
        XCTAssertTrue(trace.executionRuns.isEmpty)
    }

    func testSpaceTurnTraceDecodingIncludesExecutionRunsWhenPresent() throws {
        let json = """
        {
            "spaceId": "space-1",
            "turnId": "turn-1",
            "total": 2,
            "events": [],
            "toolCalls": [],
            "activities": [],
            "executionRuns": [
                {
                    "executionId": "exec-1",
                    "stepIndex": 0,
                    "agentId": "agent-1",
                    "providerId": "claude",
                    "modelId": "sonnet",
                    "status": "completed",
                    "startedAt": "2026-03-29T10:00:00Z",
                    "completedAt": "2026-03-29T10:00:03Z",
                    "durationMs": 3000,
                    "workingDirectory": "/tmp/workspace",
                    "exitCode": 0,
                    "commandPreview": "claude --output-format stream-json",
                    "transcriptArtifactId": "artifact-debug-1",
                    "transcriptTruncated": false
                }
            ],
            "artifactIds": ["artifact-debug-1"]
        }
        """

        let trace = try JSONDecoder().decode(SpaceTurnTrace.self, from: Data(json.utf8))

        XCTAssertEqual(trace.executionRuns.count, 1)
        XCTAssertEqual(trace.executionRuns.first?.executionId, "exec-1")
        XCTAssertEqual(trace.executionRuns.first?.workingDirectory, "/tmp/workspace")
        XCTAssertEqual(trace.executionRuns.first?.transcriptArtifactId, "artifact-debug-1")
    }

    func testSpaceGetDebugArtifactPayloadEncodingAndResultDecoding() throws {
        let payload = try encodeJSONObject(
            SpaceGetDebugArtifactPayload(
                spaceId: "space-1",
                artifactId: "artifact-debug-1"
            )
        )
        XCTAssertEqual(payload["spaceId"] as? String, "space-1")
        XCTAssertEqual(payload["artifactId"] as? String, "artifact-debug-1")

        let json = """
        {
            "artifact": {
                "artifactId": "artifact-debug-1",
                "spaceId": "space-1",
                "turnId": "turn-1",
                "agentId": "agent-1",
                "type": "cli_execution_transcript",
                "title": "CLI transcript",
                "mimeType": "application/x-ndjson",
                "sizeBytes": 24,
                "tags": ["debug", "cli_execution", "transcript"],
                "visibility": "private",
                "createdAt": "2026-03-29T10:00:00Z",
                "updatedAt": "2026-03-29T10:00:04Z",
                "content": "{\\"event\\":\\"started\\"}\\n"
            }
        }
        """

        let result = try JSONDecoder().decode(SpaceGetDebugArtifactResult.self, from: Data(json.utf8))

        XCTAssertEqual(result.artifact.artifactId, "artifact-debug-1")
        XCTAssertEqual(result.artifact.type, "cli_execution_transcript")
        XCTAssertEqual(result.artifact.content.value as? String, "{\"event\":\"started\"}\n")
    }
}
