import Foundation

public enum ContentPartKind: String, Codable, Sendable, Equatable {
    case text
    case data
    case file
}

public struct ContentPart: Codable, Sendable, Equatable {
    public let type: ContentPartKind
    public let mimeType: String?
    public let text: String?
    public let data: String?
    public let uri: String?
    public let title: String?
    public let previewText: String?
    public let metadata: [String: AnyCodable]?
}

public struct ContentEnvelope: Codable, Sendable, Equatable {
    public let schemaVersion: Int
    public let kind: String
    public let primaryMimeType: String
    public let previewText: String?
    public let supportsInline: Bool
    public let parts: [ContentPart]
    public let metadata: [String: AnyCodable]?

    public var inlineText: String? {
        let combined = parts.compactMap { part in
            switch part.type {
            case .text:
                return part.text
            case .data:
                return part.data
            case .file:
                return part.previewText
            }
        }.joined(separator: "\n")

        let normalized = combined.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.isEmpty {
            return normalized
        }

        let preview = previewText?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (preview?.isEmpty == false) ? preview : nil
    }

    public var isMarkdown: Bool {
        normalizeMimeType(primaryMimeType) == "text/markdown"
    }

    public var prefersMonospacedPresentation: Bool {
        let mime = normalizeMimeType(primaryMimeType)
        if mime == "application/json" || mime == "application/sql" || mime == "application/toml" || mime == "application/xml" {
            return true
        }
        return mime.hasPrefix("text/x-")
            || mime == "text/typescript"
            || mime == "text/tsx"
            || mime == "text/javascript"
            || mime == "text/jsx"
    }

    public static func markdown(_ markdown: String) -> ContentEnvelope {
        textEnvelope(markdown, mimeType: "text/markdown")
    }

    public static func plainText(_ text: String) -> ContentEnvelope {
        textEnvelope(text, mimeType: "text/plain")
    }

    fileprivate static func dataEnvelope(_ data: String, mimeType: String) -> ContentEnvelope {
        let normalizedMimeType = normalizeMimeType(mimeType)
        let safeMimeType = normalizedMimeType.isEmpty ? "application/json" : normalizedMimeType
        return ContentEnvelope(
            schemaVersion: 1,
            kind: "rich_content",
            primaryMimeType: safeMimeType,
            previewText: truncatePreview(data),
            supportsInline: supportsInlineMimeType(safeMimeType),
            parts: [
                ContentPart(
                    type: .data,
                    mimeType: safeMimeType,
                    text: nil,
                    data: data,
                    uri: nil,
                    title: nil,
                    previewText: truncatePreview(data),
                    metadata: nil
                )
            ],
            metadata: nil
        )
    }
}

public extension SpaceTurn {
    var resolvedInputContent: ContentEnvelope? {
        if let inputContent {
            return inputContent
        }
        guard let inputText else { return nil }
        return .plainText(inputText)
    }

    var resolvedOutputContent: ContentEnvelope? {
        if let outputContent {
            return outputContent
        }
        guard let outputText else { return nil }
        return .plainText(outputText)
    }
}

public extension SpaceArtifactDetail {
    var resolvedContentEnvelope: ContentEnvelope {
        if let contentEnvelope {
            return contentEnvelope
        }
        return adaptedContentEnvelope(from: content, mimeType: primaryMimeType ?? mimeType, title: title)
    }
}

public extension LibraryEntry {
    var resolvedRichContent: ContentEnvelope? {
        guard let contentMarkdown, !contentMarkdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return .markdown(contentMarkdown)
    }
}

public extension SkillDraft {
    var resolvedRichContent: ContentEnvelope {
        .markdown(contentMarkdown)
    }
}

private func decodeContentEnvelope(from value: Any) -> ContentEnvelope? {
    guard JSONSerialization.isValidJSONObject(value),
          let data = try? JSONSerialization.data(withJSONObject: value),
          let decoded = try? JSONDecoder().decode(ContentEnvelope.self, from: data) else {
        return nil
    }
    return decoded
}

private func textEnvelope(_ text: String, mimeType: String) -> ContentEnvelope {
    let normalizedMimeType = normalizeMimeType(mimeType)
    let safeMimeType = normalizedMimeType == "text/html" ? "text/plain" : normalizedMimeType
    return ContentEnvelope(
        schemaVersion: 1,
        kind: "rich_content",
        primaryMimeType: safeMimeType,
        previewText: truncatePreview(text),
        supportsInline: supportsInlineMimeType(safeMimeType),
        parts: [
            ContentPart(
                type: .text,
                mimeType: safeMimeType,
                text: text,
                data: nil,
                uri: nil,
                title: nil,
                previewText: truncatePreview(text),
                metadata: nil
            )
        ],
        metadata: nil
    )
}

private func adaptedContentEnvelope(
    from value: AnyCodable,
    mimeType: String? = nil,
    title: String? = nil
) -> ContentEnvelope {
    if let envelope = decodeContentEnvelope(from: value.value) {
        return envelope
    }

    if let record = value.value as? [String: Any] {
        if let kind = record["kind"] as? String,
           kind == "space.basic_md",
           let markdown = record["markdown"] as? String {
            return .markdown(markdown)
        }
        let json = prettyPrintedJSON(from: record) ?? String(describing: record)
        return ContentEnvelope.dataEnvelope(json, mimeType: mimeType ?? "application/json")
    }

    if let array = value.value as? [Any] {
        let json = prettyPrintedJSON(from: array) ?? String(describing: array)
        return ContentEnvelope.dataEnvelope(json, mimeType: mimeType ?? "application/json")
    }

    if let string = value.value as? String {
        let normalizedMimeType = normalizedMimeTypeForTextContent(mimeType: mimeType, title: title)
        return textEnvelope(string, mimeType: normalizedMimeType)
    }

    return textEnvelope(
        String(describing: value.value),
        mimeType: normalizedMimeTypeForTextContent(mimeType: mimeType, title: title)
    )
}

private func prettyPrintedJSON(from value: Any) -> String? {
    guard JSONSerialization.isValidJSONObject(value),
          let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]),
          let output = String(data: data, encoding: .utf8) else {
        return nil
    }
    return output
}

private func normalizedMimeTypeForTextContent(mimeType: String?, title: String?) -> String {
    if let mimeType {
        let normalized = normalizeMimeType(mimeType)
        if !normalized.isEmpty {
            return normalized
        }
    }

    if let title {
        let lowered = title.lowercased()
        if lowered.hasSuffix(".md") || lowered.hasSuffix(".markdown") {
            return "text/markdown"
        }
    }

    return "text/plain"
}

private func normalizeMimeType(_ value: String) -> String {
    value
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
        .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: true)
        .first
        .map(String.init) ?? "text/plain"
}

private func truncatePreview(_ value: String, limit: Int = 4_000) -> String {
    guard value.count > limit else { return value }
    return String(value.prefix(limit)).trimmingCharacters(in: .whitespacesAndNewlines)
        + "\n\n… [truncated — \(value.count) chars total]"
}

private func supportsInlineMimeType(_ mimeType: String) -> Bool {
    if mimeType.hasPrefix("text/") {
        return mimeType != "text/html"
    }

    return [
        "application/json",
        "application/sql",
        "application/toml",
        "application/xml",
        "application/x-sh",
        "application/x-yaml",
        "application/yaml",
    ].contains(mimeType)
}
