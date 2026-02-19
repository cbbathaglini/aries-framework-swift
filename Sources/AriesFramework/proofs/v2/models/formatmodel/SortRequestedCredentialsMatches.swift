//
//  SortRequestedCredentialsMatches.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation

class SortRequestedCredentialsMatches {
    
    static func sortRequestedCredentialsMatches<T>(
        _ credentials: [T],
        revokedOf: (T) -> Bool?,
        updatedAtOf: (T) -> Date
    ) -> [T] {
        func rank(_ revoked: Bool?) -> Int {
            switch revoked {
            case nil: return 0
            case false: return 1
            case true: return 2
            default: return -1
            }
        }

        return credentials.sorted {
            let ra = rank(revokedOf($0))
            let rb = rank(revokedOf($1))
            if ra != rb {
                return ra < rb
            } else {
                return updatedAtOf($0) > updatedAtOf($1) // DESC
            }
        }
    }

    static func sortRequestedCredentialsAttrMatches(
        _ credentials: [AnonCredsRequestedAttributeMatch]
    ) -> [AnonCredsRequestedAttributeMatch] {
        return sortRequestedCredentialsMatches(
            credentials,
            revokedOf: { $0.revoked },
            updatedAtOf: {
                $0.credentialInfo.updatedAt.date
            }
        )
    }
    
    static func sortRequestedCredentialsPredicatesMatches(
        _ credentials: [AnonCredsRequestedPredicateMatch]
    ) -> [AnonCredsRequestedPredicateMatch] {
        return sortRequestedCredentialsMatches(
            credentials,
            revokedOf: { $0.revoked },
            updatedAtOf: {
                $0.credentialInfo.updatedAt.date
            }
        )
    }

}
