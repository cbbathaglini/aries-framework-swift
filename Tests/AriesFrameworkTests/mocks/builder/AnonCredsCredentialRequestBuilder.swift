//
//  AnonCredsCredentialRequestBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework
import Foundation
import AnyCodable

final class AnonCredsCredentialRequestBuilder {

    // MARK: - Defaults seguros para testes

    private var proverDid: String? = "did:test:holder"
    private var entropy: String? = UUID().uuidString
    private var credDefId: String = "creddef:test"
    private var blindedMs: [String: AnyCodable] = [:]
    private var blindedMsCorrectnessProof: [String: AnyCodable] = [:]
    private var nonce: String = UUID().uuidString

    // MARK: - Fluent API

    func withProverDid(_ did: String?) -> Self {
        self.proverDid = did
        return self
    }

    func withEntropy(_ entropy: String?) -> Self {
        self.entropy = entropy
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

    func withBlindedMs(_ value: [String: AnyCodable]) -> Self {
        self.blindedMs = value
        return self
    }

    func withBlindedMsCorrectnessProof(_ value: [String: AnyCodable]) -> Self {
        self.blindedMsCorrectnessProof = value
        return self
    }

    func withEmptyBlindedData() -> Self {
        self.blindedMs = [:]
        self.blindedMsCorrectnessProof = [:]
        return self
    }

    // MARK: - Build

    func build() -> AnonCredsCredentialRequest {
        AnonCredsCredentialRequest(
            proverDid: proverDid,
            entropy: entropy,
            credDefId: credDefId,
            blindedMs: blindedMs,
            blindedMsCorrectnessProof: blindedMsCorrectnessProof,
            nonce: nonce
        )
    }
}
