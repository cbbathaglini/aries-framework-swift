//
//  RequestedCredentialsForProofRequestProcessor.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 08/10/25.
//

import Foundation

/// Responsible for retrieving credentials that satisfy a given proof request (AnonCreds).
final class RequestedCredentialsForProofRequestProcessor {

    private let agent: Agent
    private let common: CommonFunctions

    init(agent: Agent, common: CommonFunctions) {
        self.agent = agent
        self.common = common
    }
   
    func getRequestedCredentials(for anoncredsProofRequest: AnonCredsProofRequest, credentialW3cId: String? = nil) async throws -> RetrievedCredentialsAnonCreds {
        logDebug("[init] Retrieving requested credentials for proof request \(anoncredsProofRequest.name)")
        
        let attributes = try await fetchRequestedAttributes(for: anoncredsProofRequest, credentialW3cId: credentialW3cId)
        let predicates = try await fetchRequestedPredicates(for: anoncredsProofRequest, credentialW3cId: credentialW3cId)

        var retrieved = RetrievedCredentialsAnonCreds()
        retrieved.requestedAttributes = attributes
        retrieved.requestedPredicates = predicates

        logDebug("[end] Successfully retrieved credentials for proof request \(anoncredsProofRequest.name)")
        return retrieved
    }


    private func fetchRequestedAttributes(for proofRequest: AnonCredsProofRequest, credentialW3cId: String? = nil) async throws -> [String: [RequestedAttributeAnonCreds]] {
        var result: [String: [RequestedAttributeAnonCreds]] = [:]

        try await withThrowingTaskGroup(of: (String, [RequestedAttributeAnonCreds]).self) { group in
            for (referent, requestedAttribute) in proofRequest.requestedAttributes {
                group.addTask {
                    let credentials = try await self.agent.anonCredsHolderService.getCredentialsForProofRequest(
                        options: GetCredentialsForProofRequestOptions(
                            proofRequest: proofRequest,
                            attributeReferent: referent,
                            chosenCredentialId: credentialW3cId
                        )
                    )

                    let attributes = try await credentials.credentials.asyncMap { credentialInfo in
                        let (revoked, timestamp) = try await self.getRevocationStatusForRequestedItemAnoncreds(
                            proofRequest: proofRequest,
                            nonRevoked: requestedAttribute.nonRevoked,
                            credential: credentialInfo
                        )

                        return RequestedAttributeAnonCreds(
                            credentialId: credentialInfo.credentialInfo.credentialId,
                            timestamp: timestamp,
                            revealed: true,
                            credentialInfo: credentialInfo.credentialInfo,
                            revoked: revoked
                        )
                    }

                    return (referent, attributes)
                }
            }

            for try await (referent, attributes) in group {
                result[referent] = attributes
            }
        }

        return result
    }

    private func fetchRequestedPredicates(for proofRequest: AnonCredsProofRequest, credentialW3cId: String?) async throws -> [String: [RequestedPredicateAnonCreds]] {
        var result: [String: [RequestedPredicateAnonCreds]] = [:]

        try await withThrowingTaskGroup(of: (String, [RequestedPredicateAnonCreds]).self) { group in
            for (referent, requestedPredicate) in proofRequest.requestedPredicates {
                group.addTask {
                    let credentials = try await self.agent.anonCredsHolderService.getCredentialsForProofRequest(
                        options: GetCredentialsForProofRequestOptions(
                            proofRequest: proofRequest,
                            attributeReferent: referent,
                            chosenCredentialId: credentialW3cId
                        )
                    )

                    let predicates = try await credentials.credentials.asyncMap { credentialInfo in
                        let (revoked, timestamp) = try await self.getRevocationStatusForRequestedItemAnoncreds(
                            proofRequest: proofRequest,
                            nonRevoked: requestedPredicate.nonRevoked,
                            credential: credentialInfo
                        )

                        return RequestedPredicateAnonCreds(
                            credentialId: credentialInfo.credentialInfo.credentialId,
                            timestamp: timestamp,
                            credentialInfo: credentialInfo.credentialInfo,
                            revoked: revoked
                        )
                    }

                    return (referent, predicates)
                }
            }

            for try await (referent, predicates) in group {
                result[referent] = predicates
            }
        }

        return result
    }
    
    private func getRevocationStatusForRequestedItemAnoncreds(
        proofRequest: AnonCredsProofRequest,
        nonRevoked: AnonCredsNonRevokedInterval?,
        credential: CredentialForProofRequest
    ) async throws -> (Bool?, Int?) {
        let requestNonRevoked = nonRevoked ?? proofRequest.nonRevoked
        let credentialRevocationId = credential.credentialInfo.credentialRevocationId
        let revocationRegistryId = credential.credentialInfo.revocationRegistryId
        print("🔍 DIAG getRevocationStatus credRevId=\(String(describing: credentialRevocationId)) revRegId=\(String(describing: revocationRegistryId)) nonRevoked=\(String(describing: requestNonRevoked))")
        print("🔍 DIAG getRevocationStatus credInfo: revocationRegistryId=\(String(describing: credential.credentialInfo.revocationRegistryId)) credRevId=\(String(describing: credential.credentialInfo.credentialRevocationId))")

        guard
            let nonRevoked = requestNonRevoked,
            let credRevId = credentialRevocationId,
            let revRegId = revocationRegistryId
        else {
            return (nil, nil)
        }

        if agent.agentConfig.ignoreRevocationCheck {
            return (false, Int(nonRevoked.to!))
        }

        return try await agent.revocationService.getRevocationStatusAnonCreds(
            credentialRevocationId: credRevId,
            revocationRegistryId: revRegId,
            revocationInterval: nonRevoked
        )
    }
}
