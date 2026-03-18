//
//  MockProofUtils.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/26.
//

@testable import AriesFramework
import Foundation

final class MockProofUtils: ProofUtilsBridgeProtocol {

    var errorToThrow: Error?
    var retrievedCredentialsToReturn = RetrievedCredentialsAnonCreds()

    private(set) var getRequestedCredentialsCallCount = 0
    private(set) var receivedProofRecordId: String?
    private(set) var receivedAgent: Agent?

    func getRequestedCredentialsForProofRequest(
        proofRecordId: String,
        agent: Agent
    ) async throws -> RetrievedCredentialsAnonCreds {
        getRequestedCredentialsCallCount += 1
        receivedProofRecordId = proofRecordId
        receivedAgent = agent

        if let errorToThrow {
            throw errorToThrow
        }

        return retrievedCredentialsToReturn
    }
}
