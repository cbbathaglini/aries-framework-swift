//
//  AnonCredsIssuerService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public protocol AnonCredsIssuerService {
    func createCredentialOffer(credentialDefinitionId: String) async throws -> AnonCredsCredentialOffer

    func createCredential(options: CreateCredentialOptions) async throws -> CreateCredentialReturn
}
