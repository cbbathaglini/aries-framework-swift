//
//  ParsedIndyRevocationRegistryId.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

struct ParsedIndyRevocationRegistryId: Codable {
    let did: String
    let namespaceIdentifier: String
    let schemaSeqNo: String
    let credentialDefinitionTag: String
    let revocationRegistryTag: String
    let namespace: String?
}
