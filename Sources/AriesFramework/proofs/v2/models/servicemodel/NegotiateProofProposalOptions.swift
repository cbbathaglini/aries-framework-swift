//
//  NegotiateProofProposalOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

import Foundation
import AnyCodable

public struct NegotiateProofProposalOptions {
    let proofRecord: ProofExchangeRecord
    let proofFormats: [String: AnyCodable]
    let autoAcceptProof: AutoAcceptProof
    let comment: String?
    let goalCode: String?
    let goal: String?
    let willConfirm: Bool

    enum CodingKeys: String, CodingKey {
        case proofRecord
        case proofFormats
        case autoAcceptProof
        case comment
        case goalCode
        case goal
        case willConfirm
    }

    init(
        proofRecord: ProofExchangeRecord,
        proofFormats: [String: AnyCodable] = [:],
        autoAcceptProof: AutoAcceptProof,
        comment: String? = nil,
        goalCode: String? = nil,
        goal: String? = nil,
        willConfirm: Bool
    ) {
        self.proofRecord = proofRecord
        self.proofFormats = proofFormats
        self.autoAcceptProof = autoAcceptProof
        self.comment = comment
        self.goalCode = goalCode
        self.goal = goal
        self.willConfirm = willConfirm
    }
}
