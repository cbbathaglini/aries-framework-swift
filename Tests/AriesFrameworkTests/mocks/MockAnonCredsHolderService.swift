//
//  MockAnonCredsHolderService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 20/02/26.
//
import Foundation
@testable import AriesFramework

final class MockAnonCredsHolderService: AnonCredsHolderService {

    // MARK: - Spy (captura chamadas)
    private(set) var storeCredentialCalls: [(options: StoreCredentialOptions, metadata: [String: Any]?)] = []
    private(set) var getCredentialCalls: [(credentialId: String, useUnqualifiedIdentifiersIfPresent: Bool?)] = []
    private(set) var createCredentialRequestCalls: [CreateCredentialHolderRequestOptions] = []
    private(set) var deleteCredentialCalls: [String] = []
    private(set) var createLinkSecretCalls: [CreateLinkSecretOptions?] = []
    private(set) var legacyToW3cCredentialCalls: [LegacyToW3cCredentialOptions] = []
    private(set) var createProofCalls: [CreateProofOptions] = []
    private(set) var getCredentialsForProofRequestCalls: [GetCredentialsForProofRequestOptions] = []
    private(set) var generateNonceCallCount: Int = 0
    var nonceToReturn: String = "mock-nonce"


    // MARK: - Config (retornos e erros)
    var errorToThrow: Error?

    var storeCredentialIdToReturn: String = "mock-credential-id"
    var credentialInfoToReturn: AnonCredsCredentialInfo?
    var createCredentialRequestToReturn: CreateCredentialRequestReturn?
    var createLinkSecretToReturn: CreateLinkSecretReturn?
    var legacyToW3cCredentialToReturn: W3cJsonLdVerifiableCredential?
    var proofToReturn: AnonCredsProof?
    var credentialsForProofRequestToReturn: GetCredentialsForProofRequestReturn?

    // MARK: - AnonCredsHolderService

    func storeCredential(
        options: StoreCredentialOptions,
        metadata: [String: Any]?
    ) async throws -> String {
        if let errorToThrow { throw errorToThrow }
        storeCredentialCalls.append((options, metadata))
        return storeCredentialIdToReturn
    }

    func getCredential(
        credentialId: String,
        useUnqualifiedIdentifiersIfPresent: Bool?
    ) async throws -> AnonCredsCredentialInfo {
        if let errorToThrow { throw errorToThrow }
        getCredentialCalls.append((credentialId, useUnqualifiedIdentifiersIfPresent))

        guard let credentialInfoToReturn else {
            throw CredoError("MockAnonCredsHolderService.credentialInfoToReturn not set")
        }
        return credentialInfoToReturn
    }

    func createCredentialRequest(
        options: CreateCredentialHolderRequestOptions
    ) async throws -> CreateCredentialRequestReturn {
        if let errorToThrow { throw errorToThrow }
        createCredentialRequestCalls.append(options)

        guard let createCredentialRequestToReturn else {
            throw CredoError("MockAnonCredsHolderService.createCredentialRequestToReturn not set")
        }
        return createCredentialRequestToReturn
    }

    func deleteCredential(
        credentialId: String
    ) async throws {
        if let errorToThrow { throw errorToThrow }
        deleteCredentialCalls.append(credentialId)
    }

    func createLinkSecret(
        options: CreateLinkSecretOptions?
    ) async throws -> CreateLinkSecretReturn {
        if let errorToThrow { throw errorToThrow }
        createLinkSecretCalls.append(options)

        guard let createLinkSecretToReturn else {
            throw CredoError("MockAnonCredsHolderService.createLinkSecretToReturn not set")
        }
        return createLinkSecretToReturn
    }

    func legacyToW3cCredential(
        options: LegacyToW3cCredentialOptions
    ) async throws -> W3cJsonLdVerifiableCredential {
        if let errorToThrow { throw errorToThrow }
        legacyToW3cCredentialCalls.append(options)

        guard let legacyToW3cCredentialToReturn else {
            throw CredoError("MockAnonCredsHolderService.legacyToW3cCredentialToReturn not set")
        }
        return legacyToW3cCredentialToReturn
    }

    func createProof(
        options: CreateProofOptions
    ) async throws -> AnonCredsProof {
        if let errorToThrow { throw errorToThrow }
        createProofCalls.append(options)

        guard let proofToReturn else {
            throw CredoError("MockAnonCredsHolderService.proofToReturn not set")
        }
        return proofToReturn
    }

    func getCredentialsForProofRequest(
        options: GetCredentialsForProofRequestOptions
    ) async throws -> GetCredentialsForProofRequestReturn {
        if let errorToThrow { throw errorToThrow }
        getCredentialsForProofRequestCalls.append(options)

        guard let credentialsForProofRequestToReturn else {
            throw CredoError("MockAnonCredsHolderService.credentialsForProofRequestToReturn not set")
        }
        return credentialsForProofRequestToReturn
    }
    
    func generateNonce() -> String {
        generateNonceCallCount += 1
        return nonceToReturn
    }
}
