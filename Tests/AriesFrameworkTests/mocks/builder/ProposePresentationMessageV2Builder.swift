//
//  ProposePresentationMessageV2Builder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

import Foundation
@testable import AriesFramework

final class ProposePresentationMessageV2Builder {

    private var comment: String? = nil
    private var goalCode: String? = nil
    private var goal: String? = nil
    private var proposalAttachments: [Attachment] = []
    private var formats: [ProofFormatSpec] = []

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
    func setProposalAttachments(_ value: [Attachment]) -> Self {
        self.proposalAttachments = value
        return self
    }

    @discardableResult
    func setFormats(_ value: [ProofFormatSpec]) -> Self {
        self.formats = value
        return self
    }

    func build() -> ProposePresentationMessageV2 {
        ProposePresentationMessageV2(
            comment: comment,
            goalCode: goalCode,
            goal: goal,
            proposalAttachments: proposalAttachments,
            formats: formats
        )
    }
}
