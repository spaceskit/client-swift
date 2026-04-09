import XCTest
@testable import SpaceskitClient

final class RichContentTests: XCTestCase {
    func testSpaceTurnFallsBackToPlainTextEnvelope() throws {
        let json = """
        {
          "turnId": "turn-1",
          "agentId": "agent-1",
          "status": "completed",
          "inputText": "hello",
          "outputText": "world",
          "createdAt": "2026-03-13T10:00:00Z"
        }
        """

        let turn = try JSONDecoder().decode(SpaceTurn.self, from: Data(json.utf8))

        XCTAssertEqual(turn.resolvedInputContent?.primaryMimeType, "text/plain")
        XCTAssertEqual(turn.resolvedInputContent?.inlineText, "hello")
        XCTAssertEqual(turn.resolvedOutputContent?.inlineText, "world")
    }

    func testSpaceTurnDecodesAdditiveEnvelopeFields() throws {
        let json = """
        {
          "turnId": "turn-1",
          "agentId": "agent-1",
          "status": "completed",
          "inputText": "ignored",
          "inputContent": {
            "schemaVersion": 1,
            "kind": "rich_content",
            "primaryMimeType": "text/markdown",
            "supportsInline": true,
            "parts": [
              { "type": "text", "mimeType": "text/markdown", "text": "# Heading" }
            ]
          },
          "createdAt": "2026-03-13T10:00:00Z"
        }
        """

        let turn = try JSONDecoder().decode(SpaceTurn.self, from: Data(json.utf8))

        XCTAssertEqual(turn.inputContent?.primaryMimeType, "text/markdown")
        XCTAssertEqual(turn.resolvedInputContent?.inlineText, "# Heading")
    }

    func testArtifactDetailFallsBackToLegacyObjectContent() {
        let detail = SpaceArtifactDetail(
            artifactId: "artifact-1",
            spaceId: "space-1",
            turnId: nil,
            agentId: nil,
            type: "space.basic_md",
            title: "basic.md",
            mimeType: nil,
            sizeBytes: 10,
            tags: [],
            visibility: "shared",
            createdAt: "2026-03-13T10:00:00Z",
            updatedAt: "2026-03-13T10:00:00Z",
            content: AnyCodable([
                "kind": "space.basic_md",
                "markdown": "# basic.md\nhello"
            ]),
            contentEnvelope: nil,
            previewText: nil,
            primaryMimeType: nil
        )

        XCTAssertEqual(detail.resolvedContentEnvelope.primaryMimeType, "text/markdown")
        XCTAssertEqual(detail.resolvedContentEnvelope.inlineText, "# basic.md\nhello")
    }

    func testLibraryDraftAdaptsMarkdownIntoSharedRichContent() {
        let draft = SkillDraft(
            draftId: "draft-1",
            name: "Draft",
            description: nil,
            requestPrompt: "prompt",
            contentMarkdown: "# Draft",
            createdAt: "2026-03-13T10:00:00Z",
            updatedAt: "2026-03-13T10:00:00Z"
        )

        XCTAssertEqual(draft.resolvedRichContent.primaryMimeType, "text/markdown")
        XCTAssertEqual(draft.resolvedRichContent.inlineText, "# Draft")
    }
}
