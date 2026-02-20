//
//  AnonCredsCredentialBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework
import AnyCodable
import Foundation

final class AnonCredsCredentialBuilder {

    // MARK: - Defaults seguros para testes

    private var schemaId: String = "schema:test"
    private var credDefId: String = "creddef:test"
    private var revRegId: String? = nil

    private var values: [String: AnonCredsCredentialValue] = [:]

    private var signature: [String: AnyCodable] = [:]
    private var signatureCorrectnessProof: [String: AnyCodable] = [:]

    private var revReg: [String: AnyCodable]? = nil
    private var witness: [String: AnyCodable]? = nil

    // MARK: - Fluent API

    func withSchemaId(_ id: String) -> Self {
        self.schemaId = id
        return self
    }

    func withCredentialDefinitionId(_ id: String) -> Self {
        self.credDefId = id
        return self
    }

    func withRevocationRegistryId(_ id: String?) -> Self {
        self.revRegId = id
        return self
    }

    func withValue(
        name: String,
        raw: String,
        encoded: String? = nil
    ) -> Self {
        let encodedValue = encoded ?? raw
        values[name] = AnonCredsCredentialValue(
            raw: raw,
            encoded: encodedValue
        )
        return self
    }

    func withValues(_ values: [String: AnonCredsCredentialValue]) -> Self {
        self.values = values
        return self
    }

    func withSignature(_ signature: [String: AnyCodable]) -> Self {
        self.signature = signature
        return self
    }

    func withSignatureCorrectnessProof(_ proof: [String: AnyCodable]) -> Self {
        self.signatureCorrectnessProof = proof
        return self
    }

    func withRevocationData(_ data: [String: AnyCodable]?) -> Self {
        self.revReg = data
        return self
    }

    func withWitness(_ witness: [String: AnyCodable]?) -> Self {
        self.witness = witness
        return self
    }

    func withoutRevocation() -> Self {
        self.revRegId = nil
        self.revReg = nil
        self.witness = nil
        return self
    }

    // MARK: - Build

    func build() -> AnonCredsCredential {
        AnonCredsCredential(
            schemaId: schemaId,
            credDefId: credDefId,
            revRegId: revRegId,
            values: values,
            signature: signature,
            signatureCorrectnessProof: signatureCorrectnessProof,
            revReg: revReg,
            witness: witness
        )
    }
}
