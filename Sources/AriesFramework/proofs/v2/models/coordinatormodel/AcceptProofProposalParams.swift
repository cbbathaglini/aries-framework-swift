//
//  AcceptProofProposalParams.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

import Foundation
import AnyCodable

public struct AcceptProofProposalParams: CustomStringConvertible {
    let proofRecord: ProofExchangeRecord
    let proofFormats: [String: AnyCodable]
    let formatServices: [any ProofFormatService]
    let comment: String?
    let goalCode: String?
    let goal: String?
    let presentMultiple: Bool?
    let willConfirm: Bool?

    public var description: String {
        return """
        AcceptProofProposalParams(
            proofRecord: \(proofRecord),
            proofFormats: \(proofFormats),
            formatServices: \(formatServices),
            comment: \(comment ?? "nil"),
            goalCode: \(goalCode ?? "nil"),
            goal: \(goal ?? "nil"),
            presentMultiple: \(String(describing: presentMultiple)),
            willConfirm: \(String(describing: willConfirm))
        )
        """
    }

    init(
        proofRecord: ProofExchangeRecord,
        proofFormats: [String: AnyCodable] = [:],
        formatServices: [any ProofFormatService],
        comment: String? = nil,
        goalCode: String? = nil,
        goal: String? = nil,
        presentMultiple: Bool? = nil,
        willConfirm: Bool? = nil
    ) {
        self.proofRecord = proofRecord
        self.proofFormats = proofFormats
        self.formatServices = formatServices
        self.comment = comment
        self.goalCode = goalCode
        self.goal = goal
        self.presentMultiple = presentMultiple
        self.willConfirm = willConfirm
    }
}
