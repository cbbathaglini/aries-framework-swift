//
//  AnonCredsHolderService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

public protocol AnonCredsHolderService {
    
    func storeCredential(
        options: StoreCredentialOptions,
        metadata: [String: Any]?
    ) async throws -> String

    func getCredential(
        credentialId: String,
        useUnqualifiedIdentifiersIfPresent: Bool?
    ) async throws -> AnonCredsCredentialInfo

    func createCredentialRequest(
        options: CreateCredentialHolderRequestOptions
    ) async throws -> CreateCredentialRequestReturn

    func deleteCredential(
        credentialId: String
    ) async throws

    func createLinkSecret(
        options: CreateLinkSecretOptions?
    ) async throws -> CreateLinkSecretReturn

    func legacyToW3cCredential(
        options: LegacyToW3cCredentialOptions
    ) async throws -> W3cJsonLdVerifiableCredential

    func createProof(options: CreateProofOptions
    ) async throws -> AnonCredsProof

    func getCredentialsForProofRequest(
        options: GetCredentialsForProofRequestOptions
    ) async throws -> GetCredentialsForProofRequestReturn
}
