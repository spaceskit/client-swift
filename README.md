# SpaceskitClient

Swift client library for connecting to a Spaceskit Gateway.

## Platforms

- macOS 14+
- iOS 17+
- watchOS 10+
- visionOS 1+

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/spaceskit/client-swift.git", from: "0.1.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "SpaceskitClient", package: "client-swift")
    ]
)
```

## Usage

```swift
import SpaceskitClient

let client = GatewayClient(options: .init(
    url: URL(string: "ws://localhost:9320")!
))
try await client.connect()
```

### Workspace APIs

```swift
let created = try await client.createSpace(
    SpaceCreatePayload(
        resourceId: "resource:\(UUID().uuidString)",
        name: "Workspace demo",
        workspaceRoot: "/absolute/path/on/gateway/host" // optional
    )
)

let workspace = try await client.getSpaceWorkspace(spaceId: created.id)
print(workspace.effectiveWorkspaceRoot)
print(workspace.metadataStatus.rawValue)
print(workspace.metaPath) // all workspace metadata now lives under .space

_ = try await client.setSpaceWorkspace(
    SpaceSetWorkspacePayload(
        spaceId: created.id,
        workspaceRoot: "/another/absolute/path"
    )
)

_ = try await client.setSpaceWorkspace(
    SpaceSetWorkspacePayload(
        spaceId: created.id,
        workspaceRoot: nil // clear the folder binding and return to managed mode
    )
)
```

## Runtime Integration Test (Live Gateway)

Run only the live runtime smoke test:

```bash
SPACESKIT_E2E_RUNTIME=1 SPACESKIT_MAIN_GATEWAY_WS_URL=ws://127.0.0.1:9320 swift test --filter GatewayRuntimeIntegrationTests
```

## License

See [LICENSE](./LICENSE).
