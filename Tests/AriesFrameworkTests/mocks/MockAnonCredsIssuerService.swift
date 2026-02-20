//
//  MockAnonCredsIssuerService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/01/26.
//

@testable import AriesFramework
import Foundation

final class MockAnonCredsIssuerService: AnonCredsIssuerService {

    func createCredentialOffer(
        credentialDefinitionId: String
    ) async throws -> AnonCredsCredentialOffer {
        
        return AnonCredsCredentialOfferBuilder()
            .withSchemaId("schema:test")
            .withCredentialDefinitionId(credentialDefinitionId)
            .build()
    }

    func createCredential(
        options: CreateCredentialOptions
    ) async throws -> CreateCredentialReturn {
        fatalError("createCredential not needed in unit tests")
    }
}
