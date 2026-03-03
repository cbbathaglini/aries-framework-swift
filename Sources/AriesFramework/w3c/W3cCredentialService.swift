//
//  W3cCredentialService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import AnyCodable

public final class W3cCredentialService {

    private let w3cCredentialRepository: W3cCredentialRepository
    private let w3cJsonLdCredentialService: W3cJsonLdCredentialService

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    public init(
        w3cCredentialRepository: W3cCredentialRepository,
        w3cJsonLdCredentialService: W3cJsonLdCredentialService,
    ) {
        self.w3cCredentialRepository = w3cCredentialRepository
        self.w3cJsonLdCredentialService = w3cJsonLdCredentialService
    }

    // MARK: - Kotlin: storeCredentialW3cJsonLdVerifiableCredential

    public func storeCredentialW3cJsonLdVerifiableCredential(
        jsonLdVerifiableCredential: W3cJsonLdVerifiableCredential
    ) async throws -> W3cCredentialRecord {
        let expandedTypes: [String: [String]] =
                    try w3cJsonLdCredentialService.getExpandedTypesForCredential(
                        contextList: jsonLdVerifiableCredential.context,
                        types: jsonLdVerifiableCredential.type
                    )
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

    // MARK: - Kotlin: storeCredentialW3cCredential

    public func storeCredentialW3cCredential(
        w3cCredential: W3cCredential
    ) async throws -> W3cCredentialRecord {

        let expandedTypes: [String: [String]] =
                    try w3cJsonLdCredentialService.getExpandedTypesForCredential(
                        contextList: w3cCredential.context,
                        types: w3cCredential.type
                    )

        let expandedTypesStr: [String: String] = expandedTypes.mapValues { $0.joined(separator: ",") }

        let record = W3cCredentialRecord(
            tags: expandedTypesStr,
            credential: w3cCredential
        )

        _ = record.getTags()
        try await w3cCredentialRepository.save(record)
        return record
    }

    // MARK: - Kotlin: processAndStorew3cCredential(rawJson) : W3cCredential

    public func processAndStorew3cCredential(rawJson: String) async throws -> W3cCredential {
        let parsedObj = try parseJsonObject(rawJson)
        let normalizedObj = W3cCredential.normalizeIncomingW3cPayload(root: parsedObj)

        let normalizedData = try JSONSerialization.data(withJSONObject: normalizedObj, options: [])
        let credential = try decoder.decode(W3cCredential.self, from: normalizedData)

        _ = try await storeCredentialW3cCredential(w3cCredential: credential)
        return credential
    }

    // MARK: - Kotlin: findByCredentialSubjectId

    public func findByCredentialSubjectId(subjectId: String) async throws -> [W3cCredentialRecord] {
        try await w3cCredentialRepository.findByCredentialSubjectId(subjectId)
    }
    
    public func getAll() async throws -> [W3cCredentialRecord] {
        await w3cCredentialRepository.getAll()
    }

    // MARK: - Helpers

    private func parseJsonObject(_ raw: String) throws -> [String: Any] {
        guard let data = raw.data(using: .utf8) else {
            throw NSError(domain: "W3cCredentialService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8"])
        }
        let any = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        guard let obj = any as? [String: Any] else {
            throw NSError(domain: "W3cCredentialService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Expected JSON object"])
        }
        return obj
    }

    private func encodeProofElements(_ proofs: [LinkedDataProofBase]?) throws -> [AnyCodable]? {
        guard let proofs, !proofs.isEmpty else { return nil }

        return try proofs.map { proof in
            let data = try encoder.encode(proof)
            let json = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            return AnyCodable(json)
        }
    }
}
