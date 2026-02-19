//
//  AcceptProofRequestParams.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

import Foundation
import AnyCodable

public struct AcceptProofRequestParams: CustomStringConvertible {
    public let proofRecord: ProofExchangeRecord
    public let proofFormats: [String: AnyCodable]?
    public let formatServices: [any ProofFormatService]
    public let comment: String?
    public let lastPresentation: Bool?
    public let goalCode: String?
    public let goal: String?
    public let chosenCredentialId: String?
    
    
    public init(
        proofRecord: ProofExchangeRecord,
        proofFormats: [String: AnyCodable]? = [:],
        formatServices: [any ProofFormatService],
        comment: String? = nil,
        lastPresentation: Bool? = nil,
        goalCode: String? = nil,
        goal: String? = nil,
        chosenCredentialId: String? = nil
    ) {
        self.proofRecord = proofRecord
        self.proofFormats = proofFormats
        self.formatServices = formatServices
        self.comment = comment
        self.lastPresentation = lastPresentation
        self.goalCode = goalCode
        self.goal = goal
        self.chosenCredentialId = chosenCredentialId
    }
    
    public var description: String {
        return """
        AcceptProofRequestParams(
            proofRecord: \(proofRecord),
            proofFormats: \(proofFormats ?? [:]),
            formatServices count: \(formatServices.count),
            comment: \(comment ?? "nil"),
            lastPresentation: \(String(describing: lastPresentation)),
            goalCode: \(goalCode ?? "nil"),
            goal: \(goal ?? "nil")
            chosenCredentialId: \(chosenCredentialId ?? "nil")
        )
        """
    }
}
