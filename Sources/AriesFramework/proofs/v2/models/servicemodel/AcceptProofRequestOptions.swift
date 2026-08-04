//
//  AcceptProofRequestOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

import Foundation
import AnyCodable

public struct AcceptProofRequestOptions {
    let proofRecord: ProofExchangeRecord
    let proofFormats: [ProofFormatSpec]
    let comment: String?
    let goalCode: String?
    let goal: String?
    let autoAcceptProof: AutoAcceptProof?
    let requestedCredentials: [String: AnyCodable]?
    let chosenCredentialId: String?

    public init(
        proofRecord: ProofExchangeRecord,
        proofFormats: [ProofFormatSpec] = [],
        comment: String? = nil,
        goalCode: String? = nil,
        goal: String? = nil,
        autoAcceptProof: AutoAcceptProof? = nil,
        requestedCredentials: [String: AnyCodable]? = [:],
        chosenCredentialId: String? = nil
    ) {
        self.proofRecord = proofRecord
        self.proofFormats = proofFormats
        self.comment = comment
        self.goalCode = goalCode
        self.goal = goal
        self.autoAcceptProof = autoAcceptProof
        self.requestedCredentials = requestedCredentials
        self.chosenCredentialId = chosenCredentialId
    }
}
