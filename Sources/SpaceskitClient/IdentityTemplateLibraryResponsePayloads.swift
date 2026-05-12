// Protocol payload types for Spaceskit Client SDK.

import Foundation

// MARK: - Identity, Template, and Library Response Payloads

public struct IdentityListAgentDefinitionsResponsePayload: Codable, Sendable {
    public let agentDefinitions: [AgentDefinitionSummary]
}

public struct IdentityGetAgentDefinitionResponsePayload: Codable, Sendable {
    public let agentDefinition: AgentDefinitionSummary
}

public struct IdentityCreateAgentDefinitionResponsePayload: Codable, Sendable {
    public let agentDefinition: AgentDefinitionSummary
    public let created: Bool
}

public struct IdentityUpdateAgentDefinitionResponsePayload: Codable, Sendable {
    public let agentDefinition: AgentDefinitionSummary
    public let newRevision: Int
}

public struct IdentityArchiveAgentDefinitionResponsePayload: Codable, Sendable {
    public let agentDefinition: AgentDefinitionSummary
    public let archived: Bool
}

public struct IdentityListPersonasResponsePayload: Codable, Sendable {
    public let personas: [PersonaSummary]
}

public struct IdentityGetPersonaResponsePayload: Codable, Sendable {
    public let persona: PersonaSummary
}

public struct IdentityCreatePersonaResponsePayload: Codable, Sendable {
    public let persona: PersonaSummary
    public let created: Bool
}

public struct IdentityUpdatePersonaResponsePayload: Codable, Sendable {
    public let persona: PersonaSummary
    public let newRevision: Int
}

public struct IdentityArchivePersonaResponsePayload: Codable, Sendable {
    public let persona: PersonaSummary
    public let archived: Bool
}

public struct IdentityPreviewCompiledInstructionsResponsePayload: Codable, Sendable {
    public let preview: CompiledInstructionsPreview
}

public struct IdentityPreviewRuntimeSystemPromptResponsePayload: Codable, Sendable {
    public let preview: RuntimeSystemPromptPreview
}

public struct SpacePreviewTemplateResponsePayload: Codable, Sendable {
    public let template: SpaceTemplateSummary
    public let resolved: SpaceTemplatePreviewResolved
    public let warnings: [String]
}

public typealias SpaceCreateFromTemplateResultPayload = SpaceCreateFromTemplateResult
public typealias SpaceSaveTemplateResultPayload = SpaceSaveTemplateResult

public struct SpaceTemplateListResponsePayload: Codable, Sendable {
    public let templates: [SpaceTemplateRecord]
}

public struct SpaceTemplateGetResponsePayload: Codable, Sendable {
    public let template: SpaceTemplateRecord
}

public struct SpaceTemplatePreviewResponsePayload: Codable, Sendable {
    public let template: SpaceTemplateRecord
    public let resolved: SpaceTemplatePreviewResolved
    public let warnings: [String]
}

public struct SpaceTemplateCreateSpaceResponsePayload: Codable, Sendable {
    public let template: SpaceTemplateRecord
    public let space: SpaceConfig
}

public struct SpaceTemplateSaveResponsePayload: Codable, Sendable {
    public let template: SpaceTemplateRecord
    public let created: Bool
}

public struct SpaceTemplateArchiveResponsePayload: Codable, Sendable {
    public let template: SpaceTemplateRecord
    public let archived: Bool
}

public struct LibraryListEntriesResponsePayload: Codable, Sendable {
    public let entries: [LibraryEntry]
}

public struct LibraryGetEntryResponsePayload: Codable, Sendable {
    public let entry: LibraryEntry
}

public struct LibrarySaveSkillResponsePayload: Codable, Sendable {
    public let entry: LibraryEntry
    public let created: Bool
}

public struct LibraryImportEntryResponsePayload: Codable, Sendable {
    public let entry: LibraryEntry
    public let created: Bool
}

public struct LibraryArchiveEntryResponsePayload: Codable, Sendable {
    public let entry: LibraryEntry
    public let archived: Bool
}

public struct LibrarySetEntryEnabledResponsePayload: Codable, Sendable {
    public let entry: LibraryEntry
}

public struct LibraryDeleteEntryResponsePayload: Codable, Sendable {
    public let entryId: String
    public let deleted: Bool
}

public struct LibraryScanEntriesResponsePayload: Codable, Sendable {
    public let entries: [LibraryEntry]
    public let scannedAt: String
}

public struct LibraryListSkillDraftsResponsePayload: Codable, Sendable {
    public let drafts: [SkillDraft]
}

public struct LibraryGetSkillDraftResponsePayload: Codable, Sendable {
    public let draft: SkillDraft
}

public struct LibraryCreateSkillDraftResponsePayload: Codable, Sendable {
    public let draft: SkillDraft
    public let created: Bool
}

public struct LibraryDeleteSkillDraftResponsePayload: Codable, Sendable {
    public let draftId: String
    public let deleted: Bool
}
