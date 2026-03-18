//
//  PresentationMessageV2Builder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

import Foundation
import AriesFramework

final class PresentationMessageV2Builder {

    private var comment: String? = nil
    private var goalCode: String? = nil
    private var goal: String? = nil
    private var lastPresentation: Bool? = true
    private var formats: [ProofFormatSpec] = []
    private var presentationAttachments: [Attachment] = []
    private var pleaseAck: AckDecorator? = nil
    private var createdAt: Date? = nil

    // MARK: - Setters (fluent)

    @discardableResult
    func setComment(_ value: String?) -> Self {
        self.comment = value
        return self
    }

    @discardableResult
    func setGoalCode(_ value: String?) -> Self {
        self.goalCode = value
        return self
    }

    @discardableResult
    func setGoal(_ value: String?) -> Self {
        self.goal = value
        return self
    }

    @discardableResult
    func setLastPresentation(_ value: Bool?) -> Self {
        self.lastPresentation = value
        return self
    }

    @discardableResult
    func setFormats(_ value: [ProofFormatSpec]) -> Self {
        self.formats = value
        return self
    }

    @discardableResult
    func addFormat(_ value: ProofFormatSpec) -> Self {
        self.formats.append(value)
        return self
    }

    @discardableResult
    func setPresentationAttachments(_ value: [Attachment]) -> Self {
        self.presentationAttachments = value
        return self
    }

    @discardableResult
    func addPresentationAttachment(_ value: Attachment) -> Self {
        self.presentationAttachments.append(value)
        return self
    }

    @discardableResult
    func setPleaseAck(_ value: AckDecorator?) -> Self {
        self.pleaseAck = value
        return self
    }

    @discardableResult
    func enablePleaseAck(on values: [AckValues] = [.receipt]) -> Self {
        self.pleaseAck = AckDecorator(on: values)
        return self
    }

    @discardableResult
    func setCreatedAt(_ value: Date?) -> Self {
        self.createdAt = value
        return self
    }

    // MARK: - Build

    func build() -> PresentationMessageV2 {
        let message = PresentationMessageV2(
            comment: comment,
            goalCode: goalCode,
            goal: goal,
            lastPresentation: lastPresentation,
            formats: formats,
            presentationAttachments: presentationAttachments,
            pleaseAck: pleaseAck
        )

        if let createdAt {
            message.createdAt = createdAt
        }

        return message
    }
}
