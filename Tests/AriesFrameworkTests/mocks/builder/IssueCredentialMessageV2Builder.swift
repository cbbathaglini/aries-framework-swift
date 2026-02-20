//
//  IssueCredentialMessageV2Builder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework
import Foundation

final class IssueCredentialMessageV2Builder {

    // MARK: - Internal state

    private var id: String = UUID().uuidString
    private var threadId: String?
    private var formats: [Format] = []
    private var credentialAttachments: [Attachment] = []
    private var goalCode: String?
    private var goal: String?
    private var comment: String?
    private var pleaseAck: AckDecorator?

    // MARK: - Fluent API

    func withId(_ id: String) -> Self {
        self.id = id
        return self
    }

    func withThreadId(_ threadId: String) -> Self {
        self.threadId = threadId
        return self
    }

    func withFormat(_ format: Format) -> Self {
        self.formats.append(format)
        return self
    }

    func withCredentialAttachment(_ attachment: Attachment) -> Self {
        self.credentialAttachments.append(attachment)
        return self
    }

    func withGoalCode(_ goalCode: String) -> Self {
        self.goalCode = goalCode
        return self
    }

    func withGoal(_ goal: String) -> Self {
        self.goal = goal
        return self
    }

    func withComment(_ comment: String) -> Self {
        self.comment = comment
        return self
    }

    func withPleaseAck(_ values: [AckValues] = [.receipt]) -> Self {
        self.pleaseAck = AckDecorator(on: values)
        return self
    }

    // MARK: - Convenience presets (tests)

    /// Mínimo válido para testes
    func minimal() -> Self {
        return self
            .withFormat(FormatTestFactory.anoncreds())
            .withCredentialAttachment(
                AttachmentTestFactory.empty(id: IssueCredentialMessageV2.ANONCREDS_CREDENTIAL_ATTACHMENT_ID)
            )
    }

    /// Preset AnonCreds
    func withAnoncredsCredential() -> Self {
        let attachId = IssueCredentialMessageV2.ANONCREDS_CREDENTIAL_ATTACHMENT_ID

        self.formats = [
            Format(
                attachId: attachId,
                format: "anoncreds/credential@v1.0"
            )
        ]

        self.credentialAttachments = [
            AttachmentTestFactory.json(
                id: attachId,
                jsonObject: [
                    "schema_id": "schema:example",
                    "cred_def_id": "creddef:example",
                    "values": [:]
                ]
            )
        ]

        return self
    }

    // MARK: - Build

    func build() -> IssueCredentialMessageV2 {
        let message = IssueCredentialMessageV2(
            id: id,
            formats: formats,
            credentialAttachments: credentialAttachments,
            goalCode: goalCode,
            goal: goal,
            comment: comment,
            pleaseAck: pleaseAck
        )

        if let threadId {
            message.setThread(threadId: threadId)
        }

        return message
    }
}
