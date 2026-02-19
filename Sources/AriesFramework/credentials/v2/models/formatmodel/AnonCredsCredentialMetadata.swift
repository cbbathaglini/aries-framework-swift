//
//  AnonCredsCredentialMetadata.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

struct AnonCredsCredentialMetadata: Codable {
    var schemaId: String?
    var credentialDefinitionId: String?
    var revocationRegistryId: String?
    var credentialRevocationId: String?
}
