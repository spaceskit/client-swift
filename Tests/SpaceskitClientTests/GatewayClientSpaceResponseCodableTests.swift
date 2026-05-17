import XCTest
@testable import SpaceskitClient

final class GatewayClientSpaceResponseCodableTests: GatewayClientTestCase {

    func testSpaceCreateResponsePayloadDecodesWrappedShape() throws {
        let wrapped = """
        {
            "space": {
                "id": "space-1",
                "spaceUid": "space-uid-1",
                "workspace": {
                    "spaceId": "space-1",
                    "spaceUid": "space-uid-1",
                    "mode": "managed",
                    "effectiveWorkspaceRoot": "/tmp/spaces/space-uid-1",
                    "metaPath": "/tmp/spaces/space-uid-1/.space",
                    "logsPath": "/tmp/spaces/space-uid-1/.space/logs",
                    "workPath": "/tmp/spaces/space-uid-1/.space/work",
                    "sharedContextPath": "/tmp/spaces/space-uid-1/.space/shared-context",
                    "scratchpadsPath": "/tmp/spaces/space-uid-1/.space/scratchpads",
                    "artifactsPath": "/tmp/spaces/space-uid-1/.space/artifacts",
                    "layoutVersion": 3,
                    "updatedAt": "2026-03-14T17:00:00.000Z"
                },
                "resourceId": "resource:main",
                "name": "Main",
                "turnModel": "primary_only",
                "createdAt": "2026-03-14T17:00:00.000Z",
                "updatedAt": "2026-03-14T17:00:00.000Z"
            }
        }
        """

        let wrappedDecoded = try JSONDecoder().decode(
            SpaceCreateResponsePayload.self,
            from: Data(wrapped.utf8)
        )
        XCTAssertEqual(wrappedDecoded.space.id, "space-1")
        XCTAssertEqual(wrappedDecoded.space.name, "Main")
        XCTAssertEqual(
            wrappedDecoded.space.workspace?.artifactsPath,
            "/tmp/spaces/space-uid-1/.space/artifacts"
        )
    }

    func testSpaceGetResponsePayloadDecodesWrappedShape() throws {
        let wrapped = """
        {
            "space": {
                "id": "space-3",
                "spaceUid": "space-uid-3",
                "resourceId": "resource:main",
                "name": "Wrapped",
                "turnModel": "primary_only",
                "createdAt": "2026-03-14T17:00:00.000Z",
                "updatedAt": "2026-03-14T17:00:00.000Z"
            }
        }
        """

        let wrappedDecoded = try JSONDecoder().decode(
            SpaceGetResponsePayload.self,
            from: Data(wrapped.utf8)
        )
        XCTAssertEqual(wrappedDecoded.space.id, "space-3")
    }

    func testSpaceListResponsePayloadDecodesWrappedShape() throws {
        let wrapped = """
        {
            "spaces": [
                {
                    "id": "space-5",
                    "spaceUid": "space-uid-5",
                    "workspace": {
                        "spaceId": "space-5",
                        "spaceUid": "space-uid-5",
                        "mode": "managed",
                        "effectiveWorkspaceRoot": "/tmp/spaces/space-uid-5",
                        "metaPath": "/tmp/spaces/space-uid-5/.space",
                        "logsPath": "/tmp/spaces/space-uid-5/.space/logs",
                        "workPath": "/tmp/spaces/space-uid-5/.space/work",
                        "scratchpadsPath": "/tmp/spaces/space-uid-5/.space/scratchpads",
                        "sharedContextPath": "/tmp/spaces/space-uid-5/.space/shared-context",
                        "artifactsPath": "/tmp/spaces/space-uid-5/.space/artifacts",
                        "layoutVersion": 3,
                        "updatedAt": "2026-03-14T17:00:00.000Z"
                    },
                    "resourceId": "resource:main",
                    "name": "Wrapped List",
                    "turnModel": "primary_only",
                    "createdAt": "2026-03-14T17:00:00.000Z",
                    "updatedAt": "2026-03-14T17:00:00.000Z"
                }
            ]
        }
        """

        let wrappedDecoded = try JSONDecoder().decode(
            SpaceListResponsePayload.self,
            from: Data(wrapped.utf8)
        )
        XCTAssertEqual(wrappedDecoded.spaces.count, 1)
        XCTAssertEqual(wrappedDecoded.spaces.first?.id, "space-5")
        XCTAssertEqual(
            wrappedDecoded.spaces.first?.workspace?.sharedContextPath,
            "/tmp/spaces/space-uid-5/.space/shared-context"
        )
    }
}
