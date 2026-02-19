//
//  CreateProofRequestOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

import AnyCodable

public struct CreateProofRequestOptions: Codable {
    public let proofRequest: AnonCredsProofRequest
    public let formats: [ProofFormatSpec]
    public let proofFormats: [String: AnyCodable]
    public let parentThreadId: String?
    public var connectionRecord: ConnectionRecord? = nil
    public let comment: String?
    public let goalCode: String?
    public let goal: String?
    public let autoAcceptProof: AutoAcceptProof
    public let willConfirm: Bool?

    public init(
        proofRequest: AnonCredsProofRequest,
        formats: [ProofFormatSpec] = [],
        proofFormats: [String: AnyCodable] = [:],
        parentThreadId: String? = nil,
        connectionRecord: ConnectionRecord? = nil,
        comment: String? = nil,
        goalCode: String? = nil,
        goal: String? = nil,
        autoAcceptProof: AutoAcceptProof,
        willConfirm: Bool? = true
    ) {
        self.proofRequest = proofRequest
        self.formats = formats
        self.proofFormats = proofFormats
        self.parentThreadId = parentThreadId
        self.connectionRecord = connectionRecord
        self.comment = comment
        self.goalCode = goalCode
        self.goal = goal
        self.autoAcceptProof = autoAcceptProof
        self.willConfirm = willConfirm
    }
}
