//
//  CreateProposalProofOptionsV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

import AnyCodable

/// Options used when creating a proof proposal in the protocol version 2.
/// Includes connection details, proof formats, comments, goals, and threading context.
public struct CreateProposalProofOptionsV2: CustomStringConvertible {
    public let connectionRecord: ConnectionRecord
    public let proofFormats: [String: AnyCodable]
    public let comment: String
    public let autoAcceptProof: AutoAcceptProof?
    public let goalCode: String
    public let goal: String
    public let parentThreadId: String

    public init(
        connectionRecord: ConnectionRecord,
        proofFormats: [String: AnyCodable] = [:],
        comment: String,
        autoAcceptProof: AutoAcceptProof? = nil,
        goalCode: String,
        goal: String,
        parentThreadId: String
    ) {
        self.connectionRecord = connectionRecord
        self.proofFormats = proofFormats
        self.comment = comment
        self.autoAcceptProof = autoAcceptProof
        self.goalCode = goalCode
        self.goal = goal
        self.parentThreadId = parentThreadId
    }

    public var description: String {
        return "CreateProposalProofOptionsV2(connectionId: \(connectionRecord.id), comment: \(comment), goalCode: \(goalCode), goal: \(goal), parentThreadId: \(parentThreadId))"
    }
}
