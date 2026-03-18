//
//  ProofUtilsBridgeProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/26.
//

@testable import AriesFramework
import Foundation

protocol ProofUtilsBridgeProtocol: AnyObject {
    func getRequestedCredentialsForProofRequest(
        proofRecordId: String,
        agent: Agent
    ) async throws -> RetrievedCredentialsAnonCreds
}

final class DefaultProofUtilsBridge: ProofUtilsBridgeProtocol {
    func getRequestedCredentialsForProofRequest(
        proofRecordId: String,
        agent: Agent
    ) async throws -> RetrievedCredentialsAnonCreds {
        try await ProofUtils.getRequestedCredentialsForProofRequest(
            proofRecordId: proofRecordId,
            agent: agent
        )
    }
}

final class ProofUtilsBridge {
    static var shared: ProofUtilsBridgeProtocol = DefaultProofUtilsBridge()
}
