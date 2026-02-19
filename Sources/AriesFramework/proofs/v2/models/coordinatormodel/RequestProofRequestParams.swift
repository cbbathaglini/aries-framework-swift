//
//  RequestProofRequestParams.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

import Foundation
import AnyCodable

public  struct RequestProofRequestParams {
    let proofRecord: ProofExchangeRecord
    let proofFormats: [String: AnyCodable]
    let formatServices: [any ProofFormatService]

    let comment: String?
    let goalCode: String?
    let goal: String?
    let presentMultiple: Bool?
    let willConfirm: Bool?
    let attachmentId: String?

    init(
        proofRecord: ProofExchangeRecord,
        proofFormats: [String: AnyCodable] = [:],
        formatServices: [any ProofFormatService],
        comment: String? = nil,
        goalCode: String? = nil,
        goal: String? = nil,
        presentMultiple: Bool? = nil,
        willConfirm: Bool? = nil,
        attachmentId: String? = nil
    ) {
        self.proofRecord = proofRecord
        self.proofFormats = proofFormats
        self.formatServices = formatServices
        self.comment = comment
        self.goalCode = goalCode
        self.goal = goal
        self.presentMultiple = presentMultiple
        self.willConfirm = willConfirm
        self.attachmentId = attachmentId
    }
}
