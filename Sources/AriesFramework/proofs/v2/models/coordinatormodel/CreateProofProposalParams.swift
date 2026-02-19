//
//  CreateProofProposalParams.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

import Foundation
import AnyCodable

public struct CreateProofProposalParams: CustomStringConvertible {
    public var formatServices: [any ProofFormatService]
    public var proofFormats: [String: AnyCodable]
    public var proofRecord: ProofExchangeRecord
    public var comment: String?
    public var goalCode: String?
    public var goal: String?
    
    public init(
        formatServices: [any ProofFormatService],
        proofFormats: [String: AnyCodable] = [:],
        proofRecord: ProofExchangeRecord,
        comment: String? = nil,
        goalCode: String? = nil,
        goal: String? = nil
    ) {
        self.formatServices = formatServices
        self.proofFormats = proofFormats
        self.proofRecord = proofRecord
        self.comment = comment
        self.goalCode = goalCode
        self.goal = goal
    }
    
    public var description: String {
        return """
        CreateProofProposalParams(
            formatServices: \(formatServices),
            proofFormats: \(proofFormats),
            proofRecord: \(proofRecord),
            comment: \(comment ?? "nil"),
            goalCode: \(goalCode ?? "nil"),
            goal: \(goal ?? "nil")
        )
        """
    }
}
