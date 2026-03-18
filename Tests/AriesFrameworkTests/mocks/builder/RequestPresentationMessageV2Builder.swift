//
//  RequestPresentationMessageV2Builder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

import Foundation
@testable import AriesFramework

final class RequestPresentationMessageV2Builder {

    private var id: String? = nil
    private var comment: String? = nil
    private var goal: String? = nil
    private var goalCode: String? = nil
    private var willConfirm: Bool? = true
    private var presentMultiple: Bool? = false
    private var formats: [ProofFormatSpec] = []
    private var requestPresentationAttachments: [Attachment] = []

    @discardableResult
    func setId(_ value: String?) -> Self {
        self.id = value
        return self
    }

    @discardableResult
    func setComment(_ value: String?) -> Self {
        self.comment = value
        return self
    }

    @discardableResult
    func setGoal(_ value: String?) -> Self {
        self.goal = value
        return self
    }

    @discardableResult
    func setGoalCode(_ value: String?) -> Self {
        self.goalCode = value
        return self
    }

    @discardableResult
    func setWillConfirm(_ value: Bool?) -> Self {
        self.willConfirm = value
        return self
    }

    @discardableResult
    func setPresentMultiple(_ value: Bool?) -> Self {
        self.presentMultiple = value
        return self
    }

    @discardableResult
    func setFormats(_ value: [ProofFormatSpec]) -> Self {
        self.formats = value
        return self
    }

    @discardableResult
    func setRequestPresentationAttachments(_ value: [Attachment]) -> Self {
        self.requestPresentationAttachments = value
        return self
    }

    @discardableResult
    func addRequestPresentationAttachment(_ value: Attachment) -> Self {
        self.requestPresentationAttachments.append(value)
        return self
    }

    func build() -> RequestPresentationMessageV2 {
        RequestPresentationMessageV2(
            id: id,
            comment: comment,
            goal: goal,
            goalCode: goalCode,
            willConfirm: willConfirm,
            presentMultiple: presentMultiple,
            formats: formats,
            requestPresentationAttachments: requestPresentationAttachments
        )
    }
}
