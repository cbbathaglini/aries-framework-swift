//
//  DuplicateNames.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

public class DuplicateNames {
    public static func assertNoDuplicateGroupsNamesInProofRequest(_ proofRequest: AnonCredsProofRequest) throws {
        let attributes = attributeNamesToArray(proofRequest)
        let predicates = predicateNamesToArray(proofRequest)
        
        let duplicates = predicates.filter { attributes.contains($0) }
        if !duplicates.isEmpty {
            throw AriesFrameworkError.frameworkError("The proof request contains duplicate predicates and attributes: \(duplicates.joined(separator: ","))")
        }
    }

    public static func attributeNamesToArray(_ proofRequest: AnonCredsProofRequest) -> [String] {
        return proofRequest.requestedAttributes.values.flatMap { attr in
            if let name = attr.name {
                return [name]
            } else if let names = attr.names {
                return names
            } else {
                return []
            }
        }
    }

    public static func predicateNamesToArray(_ proofRequest: AnonCredsProofRequest) -> [String] {
        return Array(Set(proofRequest.requestedPredicates.values.map { $0.name }))
    }
}
