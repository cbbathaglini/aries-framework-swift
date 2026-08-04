//
//  AnonCredsPresentationPreviewAttribute.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation

public struct AnonCredsPresentationPreviewAttribute: Codable {
    public let name: String
    public let credentialDefinitionId: String?
    public let mimeType: String?
    public let value: String?
    public let referent: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case credentialDefinitionId = "credentialDefinitionId"
        case mimeType = "mimeType"
        case value
        case referent
    }

    public init(
        name: String,
        credentialDefinitionId: String? = nil,
        mimeType: String? = nil,
        value: String? = nil,
        referent: String? = nil
    ) {
        self.name = name
        self.credentialDefinitionId = credentialDefinitionId
        self.mimeType = mimeType
        self.value = value
        self.referent = referent
    }
    
}
