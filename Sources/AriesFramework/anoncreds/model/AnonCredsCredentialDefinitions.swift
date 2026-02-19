//
//  AnonCredsCredentialDefinitions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct AnonCredsCredentialDefinitions: Codable {
    public var credentialDefinitions: [String: AnonCredsCredentialDefinition]

    public init(credentialDefinitions: [String: AnonCredsCredentialDefinition]) {
        self.credentialDefinitions = credentialDefinitions
    }
}
