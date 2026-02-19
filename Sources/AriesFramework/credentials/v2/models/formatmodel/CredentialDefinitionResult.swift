//
//  CredentialDefinitionResult.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct CredentialDefinitionResult: Codable {
    let credentialDefinition: AnonCredsCredentialDefinition
    let credentialDefinitionId: String
    let indyNamespace: String?
}
