//
//  AnonCredsGetCredentialsForProofRequestOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation

public struct AnonCredsGetCredentialsForProofRequestOptions: Codable {
    public var filterByNonRevocationRequirements: Bool?

    public init(filterByNonRevocationRequirements: Bool? = nil) {
        self.filterByNonRevocationRequirements = filterByNonRevocationRequirements
    }

    private enum CodingKeys: String, CodingKey {
        case filterByNonRevocationRequirements = "filterByNonRevocationRequirements"
    }
}
