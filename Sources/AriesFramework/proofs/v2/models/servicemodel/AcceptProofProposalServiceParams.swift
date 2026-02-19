//
//  AcceptProofProposalServiceParams.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

import Foundation
import AnyCodable

struct AcceptProofProposalServiceParams: Codable {
    let proofRecord: ProofExchangeRecord
    let proofFormats: [String: AnyCodable]
    let comment: String?
    let goalCode: String?
    let goal: String?
    let autoAcceptProof: AutoAcceptProof
    let willConfirm: Bool?

    init(
        proofRecord: ProofExchangeRecord,
        proofFormats: [String: AnyCodable] = [:],
        comment: String? = nil,
        goalCode: String? = nil,
        goal: String? = nil,
        autoAcceptProof: AutoAcceptProof,
        willConfirm: Bool? = nil
    ) {
        self.proofRecord = proofRecord
        self.proofFormats = proofFormats
        self.comment = comment
        self.goalCode = goalCode
        self.goal = goal
        self.autoAcceptProof = autoAcceptProof
        self.willConfirm = willConfirm
    }
}
