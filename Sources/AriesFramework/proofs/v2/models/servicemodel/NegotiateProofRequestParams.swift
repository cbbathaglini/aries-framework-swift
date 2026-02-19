//
//  NegotiateProofRequestParams.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

import Foundation
import AnyCodable

struct NegotiateProofRequestParams: Codable {
    let proofRecord: ProofExchangeRecord
    let proofFormats: [String: AnyCodable]
    let comment: String?
    let goalCode: String?
    let goal: String?
    let autoAcceptProof: AutoAcceptProof?

    init(
        proofRecord: ProofExchangeRecord,
        proofFormats: [String: AnyCodable] = [:],
        comment: String? = nil,
        goalCode: String? = nil,
        goal: String? = nil,
        autoAcceptProof: AutoAcceptProof? = nil
    ) {
        self.proofRecord = proofRecord
        self.proofFormats = proofFormats
        self.comment = comment
        self.goalCode = goalCode
        self.goal = goal
        self.autoAcceptProof = autoAcceptProof
    }
}
