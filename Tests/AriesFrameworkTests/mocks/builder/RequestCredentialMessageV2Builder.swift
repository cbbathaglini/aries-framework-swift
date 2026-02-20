//
//  RequestCredentialMessageV2Builder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//
@testable import AriesFramework

public final class RequestCredentialMessageV2Builder {

    private var id: String?
    private var formats: [Format] = []
    private var attachments: [Attachment] = []
    private var requestAttachments: [Attachment] = []
    private var goalCode: String?
    private var goal: String?
    private var comment: String?

    public init() {}

    // MARK: - Fluent API

    public func withId(_ id: String) -> Self {
        self.id = id
        return self
    }

    public func withFormat(_ format: Format) -> Self {
        self.formats.append(format)
        return self
    }

    public func withFormats(_ formats: [Format]) -> Self {
        self.formats = formats
        return self
    }

    public func withAttachment(_ attachment: Attachment) -> Self {
        self.attachments.append(attachment)
        return self
    }

    public func withAttachments(_ attachments: [Attachment]) -> Self {
        self.attachments = attachments
        return self
    }

    public func withRequestAttachment(_ attachment: Attachment) -> Self {
        self.requestAttachments.append(attachment)
        return self
    }

    public func withRequestAttachments(_ attachments: [Attachment]) -> Self {
        self.requestAttachments = attachments
        return self
    }

    public func withGoalCode(_ goalCode: String?) -> Self {
        self.goalCode = goalCode
        return self
    }

    public func withGoal(_ goal: String?) -> Self {
        self.goal = goal
        return self
    }

    public func withComment(_ comment: String?) -> Self {
        self.comment = comment
        return self
    }

    // MARK: - Build

    public func build() -> RequestCredentialMessageV2 {
        precondition(!formats.isEmpty, "RequestCredentialMessageV2 requires at least one format")
        precondition(!requestAttachments.isEmpty, "RequestCredentialMessageV2 requires requestAttachments")

        return RequestCredentialMessageV2(
            id: id,
            formats: formats,
            attachments: attachments,
            requestAttachments: requestAttachments,
            goalCode: goalCode,
            goal: goal,
            comment: comment
        )
    }
}
