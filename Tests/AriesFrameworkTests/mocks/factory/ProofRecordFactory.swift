//
//  ProofRecordFactory.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

@testable import AriesFramework
import Foundation
import AnyCodable

enum ProofRecordFactory {
    static func make(
        id: String = UUID().uuidString,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        tags: Tags? = nil,
        metadata: [String: AnyCodable] = [:],
        connectionId: String = "test-connection-id",
        threadId: String = "test-thread-id",
        parentThreadId: String? = nil,
        isVerified: Bool? = nil,
        presentationId: String? = nil,
        state: ProofState = .ProposalSent,
        role: ProofRole = .prover,
        autoAcceptProof: AutoAcceptProof? = nil,
        errorMessage: String? = nil,
        comment: String? = nil,
        protocolVersion: String = ProofConstants.PROTOCOL_VERSION_V2,
        formats: [ProofFormatSpec]? = [],
        proofRequestVerifierJson: String? = nil,
        proofPresentationVerifierJson: String? = nil,
        presentationMessage: PresentationMessageV2? = nil,
        chosenCredentialId: String? = nil
    ) -> ProofExchangeRecord {
        var record = ProofExchangeRecord(
            tags: tags,
            connectionId: connectionId,
            threadId: threadId,
            parentThreadId: parentThreadId,
            isVerified: isVerified,
            presentationId: presentationId,
            state: state,
            role: role,
            autoAcceptProof: autoAcceptProof,
            errorMessage: errorMessage,
            protocolVersion: protocolVersion,
            comment: comment
        )

        record.id = id
        record.createdAt = createdAt
        record.updatedAt = updatedAt
        record.metadata = metadata
        record.formats = formats
        record.proofRequestVerifierJson = proofRequestVerifierJson
        record.proofPresentationVerifierJson = proofPresentationVerifierJson
        record.presentationMessage = presentationMessage
        record.chosenCredentialId = chosenCredentialId

        return record
    }
}
