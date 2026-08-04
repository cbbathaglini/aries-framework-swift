//
//  AnonCredsCredentialsForProofRequest.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation

public struct AnonCredsCredentialsForProofRequest: Codable {
    let attributes: [String: [AnonCredsRequestedAttributeMatch]]
    let predicates: [String: [AnonCredsRequestedPredicateMatch]]
}
