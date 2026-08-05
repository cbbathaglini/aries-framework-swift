//
//  GetCredentialsForProofRequestReferent.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation
import os.log

public class GetCredentialsForProofRequestReferent {
    private let logger = Logger(subsystem: "org.hyperledger.ariesframework", category: "GetCredentialsForProofRequestReferent")
    
    public static func getCredentialsForProofRequestReferent(
        agent: Agent,
        proofRequest: AnonCredsProofRequest,
        chosenCredentialId: String? = nil,
        attributeReferent: String
    ) async throws -> GetCredentialsForProofRequestReturn {
        return try await agent.anonCredsHolderService.getCredentialsForProofRequest(
            options: GetCredentialsForProofRequestOptions(
                proofRequest: proofRequest,
                attributeReferent: attributeReferent,
                chosenCredentialId: chosenCredentialId
            )
        )
    }
    
    public static func getRevocationStatus(
        agent: Agent,
        proofRequest: AnonCredsProofRequest,
        requestedItem: Any,
        credentialInfo: AnonCredsCredentialInfo
    ) async throws -> RevocationStatusResult {
        
        let requestNonRevoked: AnonCredsNonRevokedInterval? = {
            switch requestedItem {
            case let attr as AnonCredsRequestedAttribute:
                return attr.nonRevoked ?? proofRequest.nonRevoked
            case let pred as AnonCredsRequestedPredicate:
                return pred.nonRevoked ?? proofRequest.nonRevoked
            default:
                return proofRequest.nonRevoked
            }
        }()
        
        guard
            let requestInterval = requestNonRevoked,
            let credRevocationId = credentialInfo.credentialRevocationId,
            let revocationRegistryId = credentialInfo.revocationRegistryId,
            !revocationRegistryId.isEmpty
        else {
            return RevocationStatusResult(isRevoked: nil, timestamp: nil)
        }

        // Aries RFC 0441 - validação (pode ser opcional)
        try RevocationInterval.assertBestPractice(requestInterval)

        let toTimestamp = requestInterval.to ?? UInt64(Date().timeIntervalSince1970)

        let revocationStatusList : AnonCredsRevocationStatusList = try await AnonCredsObjects.fetchRevocationStatusList(
            agent: agent,
            revocationRegistryId: revocationRegistryId,
            timestamp: toTimestamp
        )

        guard let index = Int(credRevocationId) else {
            throw CredoError("invalid credRevocationId")
        }
        let isRevoked = revocationStatusList.revocationList[index] == 1

        return RevocationStatusResult(
            isRevoked: isRevoked,
            timestamp: revocationStatusList.timestamp
        )
    }
    
    public static func getCredentialsForAnonCredsProofRequest(
        agent: Agent,
        proofRequest: AnonCredsProofRequest,
        chosenCredentialId: String? = nil,
        options: AnonCredsGetCredentialsForProofRequestOptions
    ) async throws -> AnonCredsCredentialsForProofRequest {

        var attributesMap: [String: [AnonCredsRequestedAttributeMatch]] = [:]
        var predicatesMap: [String: [AnonCredsRequestedPredicateMatch]] = [:]

        for (referent, requestedAttribute) in proofRequest.requestedAttributes {
            let credentialsForReferent = try await GetCredentialsForProofRequestReferent.getCredentialsForProofRequestReferent(
                agent: agent,
                proofRequest: proofRequest,
                chosenCredentialId: chosenCredentialId,
                attributeReferent: referent
            )

            let matches = try await withThrowingTaskGroup(of: AnonCredsRequestedAttributeMatch.self) { group in
                for credential in credentialsForReferent.credentials {
                    group.addTask {
                        let rev = try await GetCredentialsForProofRequestReferent.getRevocationStatus(
                            agent: agent,
                            proofRequest: proofRequest,
                            requestedItem: requestedAttribute,
                            credentialInfo: credential.credentialInfo
                        )
                        
//                        if(rev.isRevoked){
//                        }
                        
                        return AnonCredsRequestedAttributeMatch(
                            credentialId: credential.credentialInfo.credentialId,
                            timestamp: rev.timestamp,
                            revealed: true,
                            credentialInfo: credential.credentialInfo,
                            revoked: rev.isRevoked
                        )
                    }
                }

                var result: [AnonCredsRequestedAttributeMatch] = []
                for try await match in group {
                    result.append(match)
                }
                return SortRequestedCredentialsMatches.sortRequestedCredentialsAttrMatches(result)
            }

            let filtered = options.filterByNonRevocationRequirements == true
                ? matches.filter { $0.revoked != true }
                : matches

            attributesMap[referent] = filtered
        }

        for (referent, requestedPredicate) in proofRequest.requestedPredicates {
            let credentialsForReferent = try await GetCredentialsForProofRequestReferent.getCredentialsForProofRequestReferent(
                agent: agent,
                proofRequest: proofRequest,
                chosenCredentialId: chosenCredentialId,
                attributeReferent: referent
            )

            let matches = try await withThrowingTaskGroup(of: AnonCredsRequestedPredicateMatch.self) { group in
                for credential in credentialsForReferent.credentials {
                    group.addTask {
                        let rev = try await GetCredentialsForProofRequestReferent.getRevocationStatus(
                            agent: agent,
                            proofRequest: proofRequest,
                            requestedItem: requestedPredicate,
                            credentialInfo: credential.credentialInfo
                        )
                        return AnonCredsRequestedPredicateMatch(
                            credentialId: credential.credentialInfo.credentialId,
                            timestamp: rev.timestamp,
                            credentialInfo: credential.credentialInfo,
                            revoked: rev.isRevoked
                        )
                    }
                }

                var result: [AnonCredsRequestedPredicateMatch] = []
                for try await match in group {
                    result.append(match)
                }
                return SortRequestedCredentialsMatches.sortRequestedCredentialsPredicatesMatches(result)
            }

            let filtered = options.filterByNonRevocationRequirements == true
                ? matches.filter { $0.revoked != true }
                : matches

            predicatesMap[referent] = filtered
        }

        return AnonCredsCredentialsForProofRequest(
            attributes: attributesMap,
            predicates: predicatesMap
        )
    }
    
    private func dateToTimestamp(_ date: Date) -> Int {
        return Int(date.timeIntervalSince1970)
    }
}
