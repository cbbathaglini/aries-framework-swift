//
//  AnonCredsCredentialOfferBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework
import Foundation

final class AnonCredsCredentialOfferBuilder {

    // MARK: - Defaults seguros para testes

    private var schemaId: String = "schema:test"
    private var credDefId: String = "creddef:test"
    private var nonce: String = UUID().uuidString
    private var keyCorrectnessProof: KeyCorrectnessProof? = nil

    // MARK: - Fluent API

    func withSchemaId(_ id: String) -> Self {
        self.schemaId = id
        return self
    }

    func withCredentialDefinitionId(_ id: String) -> Self {
        self.credDefId = id
        return self
    }

    func withNonce(_ nonce: String) -> Self {
        self.nonce = nonce
        return self
    }

    func withKeyCorrectnessProof(_ proof: KeyCorrectnessProof?) -> Self {
        self.keyCorrectnessProof = proof
        return self
    }

    // MARK: - Build

    func build() -> AnonCredsCredentialOffer {
        AnonCredsCredentialOffer(
            schemaId: schemaId,
            credDefId: credDefId,
            nonce: nonce,
            keyCorrectnessProof: keyCorrectnessProof
        )
    }
}
