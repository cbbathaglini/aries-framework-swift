//
//  ProofRequestOperations.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//
import Foundation

class ProofRequestOperations {
    static func proofRequestUsesUnqualifiedIdentifiers(proofRequest: AnonCredsProofRequest) -> Bool {

        func hasUnqualified(_ restrictions: [AnonCredsProofRequestRestriction]?) -> Bool {
            guard let restrictions = restrictions else { return false }

            return restrictions.contains { r in
                (r.credDefId.map(IndyIdentifiers.isUnqualifiedCredentialDefinitionId) == true) ||
                (r.schemaId.map(IndyIdentifiers.isUnqualifiedSchemaId) == true) ||
                (r.issuerDid.map(IndyIdentifiers.isUnqualifiedIndyDid) == true) ||
                (r.issuerId.map(IndyIdentifiers.isUnqualifiedIndyDid) == true) ||
                (r.schemaIssuerDid.map(IndyIdentifiers.isUnqualifiedIndyDid) == true) ||
                (r.schemaIssuerId.map(IndyIdentifiers.isUnqualifiedIndyDid) == true) ||
                (r.revRegId.map(IndyIdentifiers.isUnqualifiedRevocationRegistryId) == true)
            }
        }

        let attributesHaveUnqualified = proofRequest.requestedAttributes.values.contains {
            hasUnqualified($0.restrictions)
        }

        let predicatesHaveUnqualified = proofRequest.requestedPredicates.values.contains {
            hasUnqualified($0.restrictions)
        }

        return attributesHaveUnqualified || predicatesHaveUnqualified
    }
}
