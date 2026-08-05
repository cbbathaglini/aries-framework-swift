//
//  W3cCredentialService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation

public class W3cCredentialService {
    private let w3cCredentialRepository: W3cCredentialRepository
    private let w3cJsonLdCredentialService: W3cJsonLdCredentialService

    public init(
        w3cCredentialRepository: W3cCredentialRepository,
        w3cJsonLdCredentialService: W3cJsonLdCredentialService,
    ) {
        self.w3cCredentialRepository = w3cCredentialRepository
        self.w3cJsonLdCredentialService = w3cJsonLdCredentialService
    }

    public func storeCredentialW3cJsonLdVerifiableCredential(
        jsonLdVerifiableCredential: W3cJsonLdVerifiableCredential
    ) async throws -> W3cCredentialRecord {
        let expandedTypes = try await w3cJsonLdCredentialService.getExpandedTypesForCredential(credential: jsonLdVerifiableCredential)
        print("🔍 DIAG [W3C] storeCredentialW3cJsonLd - expandedTypes=\(expandedTypes)")
        print("verifiable: \(jsonLdVerifiableCredential)")

        let w3cCredential = W3cCredential(
            context: jsonLdVerifiableCredential.context,
            id: jsonLdVerifiableCredential.id,
            type: jsonLdVerifiableCredential.type,
            issuer: jsonLdVerifiableCredential.issuer,
            issuanceDate: jsonLdVerifiableCredential.issuanceDate,
            credentialSubject: jsonLdVerifiableCredential.credentialSubject,
            expirationDate: jsonLdVerifiableCredential.expirationDate,
            credentialSchema: jsonLdVerifiableCredential.credentialSchema,
            credentialStatus: jsonLdVerifiableCredential.credentialStatus,
            proofs: jsonLdVerifiableCredential.proofs
        )

        let expandedTypesStr: [String: String] = expandedTypes.mapValues { $0.joined(separator: ",") }

        let w3cCredentialRecord = W3cCredentialRecord(
            tags: expandedTypesStr,
            credential: w3cCredential,
        )

        print("w3cCredentialRecord =====> \(w3cCredentialRecord)")
        try await w3cCredentialRepository.save(w3cCredentialRecord)
        return w3cCredentialRecord
    }
}
