//
//  OfferCredentialMessageV2Builder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework
import Foundation

final class OfferCredentialMessageV2Builder {

    // MARK: - Stored properties

    private var id: String = UUID().uuidString
    private var threadId: String?
    private var formats: [Format] = []
    private var offerAttachments: [Attachment] = []
    private var comment: String?
    private var goalCode: String?
    private var goal: String?
    private var credentialPreview: CredentialPreviewV2?
    private var replacementId: String?

    // MARK: - Fluent API

    func withId(_ id: String) -> Self {
        self.id = id
        return self
    }

    func withThreadId(_ threadId: String) -> Self {
        self.threadId = threadId
        return self
    }

    func withComment(_ comment: String) -> Self {
        self.comment = comment
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

    func withCredentialPreview(_ preview: CredentialPreviewV2) -> Self {
        self.credentialPreview = preview
        return self
    }

    func withReplacementId(_ replacementId: String) -> Self {
        self.replacementId = replacementId
        return self
    }

    func withFormat(_ format: Format) -> Self {
        self.formats.append(format)
        return self
    }

    func withOfferAttachment(_ attachment: Attachment) -> Self {
        self.offerAttachments.append(attachment)
        return self
    }

    // MARK: - Convenience presets (🔥 ouro para testes)

    /// Oferta AnonCreds mínima e válida
    func withAnoncredsOffer() -> Self {
        let attachId = OfferCredentialMessageV2.ANONCREDS_CREDENTIAL_OFFER_ATTACHMENT_ID

        self.formats = [
            Format(
                attachId: attachId,
                format: "anoncreds/credential-offer@v1.0"
            )
        ]

        self.offerAttachments = [
            AttachmentTestFactory.json(
                id: attachId,
                jsonString: "{}"
            )
        ]

        return self
    }

    /// Oferta Indy mínima
    func withIndyOffer() -> Self {
        let attachId = OfferCredentialMessageV2.INDY_CREDENTIAL_OFFER_ATTACHMENT_ID

        self.formats = [
            Format(
                attachId: attachId,
                format: "hlindy/credential-offer@v2.0"
            )
        ]

        self.offerAttachments = [
            AttachmentTestFactory.json(
                id: attachId,
                jsonString: "{}"
            )
        ]

        return self
    }

    // MARK: - Build

    func build() -> OfferCredentialMessageV2 {
        let offer = OfferCredentialMessageV2(
            id: id,
            formats: formats,
            offerAttachments: offerAttachments,
            goalCode: goalCode,
            goal: goal,
            comment: comment,
            credentialPreview: credentialPreview,
            replacementId: replacementId
        )

        if let threadId {
            offer.setThread(threadId: threadId)
        }

        return offer
    }
}
