//
//  AnonCredsPresentationPreviewPredicate.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation

public struct AnonCredsPresentationPreviewPredicate: Codable {
    public let name: String
    public let credentialDefinitionId: String?
    public let predicateType: String
    public let threshold: Int64

    private enum CodingKeys: String, CodingKey {
        case name
        case credentialDefinitionId = "credentialDefinitionId"
        case predicateType = "p_type"
        case threshold = "p_value"
    }

    public init(
        name: String,
        credentialDefinitionId: String? = nil,
        predicateType: String,
        threshold: Int64
    ) {
        self.name = name
        self.credentialDefinitionId = credentialDefinitionId
        self.predicateType = predicateType
        self.threshold = threshold
    }
}
