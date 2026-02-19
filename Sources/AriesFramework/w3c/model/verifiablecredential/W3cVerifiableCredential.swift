//
//  W3cVerifiableCredential.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 22/04/25.
//

import Foundation
import AnyCodable

public class W3cVerifiableCredential: Codable, CustomStringConvertible {
    var context: [AnyCodable]
    public var id: String?
    var idValidated: String?
    var type: [String]
    var issuer: AnyCodable
    var credentialSubject: [CredentialSubject]
    var proof: [AnyCodable]?
    var version: String?
    var expirationDate: String?
    var issuanceDate: String

    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case id, type, issuer, credentialSubject, proof, version, expirationDate, issuanceDate
    }

    init(
        context: [AnyCodable],
        id: String? = nil,
        type: [String] = [],
        issuer: AnyCodable,
        credentialSubject: [CredentialSubject],
        proof: [AnyCodable]? = nil,
        version: String? = nil,
        expirationDate: String? = nil,
        issuanceDate: String = ISO8601DateFormatter().string(from: Date())
    ) throws {
        self.context = try Self.validateAndSetContext(context)
        self.id = id
        self.idValidated = try Self.validateAndSetId(id)
        self.type = type
        self.issuer = issuer
        self.credentialSubject = credentialSubject
        self.proof = proof
        self.version = version
        self.expirationDate = expirationDate
        self.issuanceDate = issuanceDate
    }

    required convenience public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let context = try container.decode([AnyCodable].self, forKey: .context)
        let id = try container.decodeIfPresent(String.self, forKey: .id)
        let type = try container.decodeIfPresent([String].self, forKey: .type) ?? []
        let issuer = try container.decode(AnyCodable.self, forKey: .issuer)

        // Accept either object or list for credentialSubject
        let credentialSubject: [CredentialSubject]
        if let single = try? container.decode(CredentialSubject.self, forKey: .credentialSubject) {
            credentialSubject = [single]
        } else {
            credentialSubject = try container.decode([CredentialSubject].self, forKey: .credentialSubject)
        }

        let proof = try container.decodeIfPresent([AnyCodable].self, forKey: .proof)
        let version = try container.decodeIfPresent(String.self, forKey: .version)
        let expirationDate = try container.decodeIfPresent(String.self, forKey: .expirationDate)
        let issuanceDate = try container.decodeIfPresent(String.self, forKey: .issuanceDate)
            ?? ISO8601DateFormatter().string(from: Date())

        try self.init(
            context: context,
            id: id,
            type: type,
            issuer: issuer,
            credentialSubject: credentialSubject,
            proof: proof,
            version: version,
            expirationDate: expirationDate,
            issuanceDate: issuanceDate
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(context, forKey: .context)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(issuer, forKey: .issuer)
        try container.encode(credentialSubject, forKey: .credentialSubject)
        try container.encodeIfPresent(proof, forKey: .proof)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(expirationDate, forKey: .expirationDate)
        try container.encode(issuanceDate, forKey: .issuanceDate)
    }


    private static func validateAndSetContext(_ context: [AnyCodable]) throws -> [AnyCodable] {
        if let first = context.first?.value as? String {
            guard W3cUtils.isValidUri(first) else {
                throw NSError(domain: "W3cVerifiableCredential", code: 1, userInfo: [NSLocalizedDescriptionKey: "The first context is not a valid URI"])
            }
            guard first == W3cUtils.CONTEXT_VERSION_1_0 else {
                throw NSError(domain: "W3cVerifiableCredential", code: 2, userInfo: [NSLocalizedDescriptionKey: "The first context must be \(W3cUtils.CONTEXT_VERSION_1_0)"])
            }
        }
        return context
    }

    private static func validateAndSetId(_ id: String?) throws -> String? {
        if let id = id, !id.isEmpty {
            guard W3cUtils.isValidUri(id) else {
                throw NSError(domain: "W3cVerifiableCredential", code: 3, userInfo: [NSLocalizedDescriptionKey: "The id is not a valid URI"])
            }
        }
        return id
    }

    public var description: String {
        let subjectStrings = credentialSubject.map { $0.toJson() }.joined(separator: ", ")
        return "VerifiableCredentialV1(context: \(context), id: \(id ?? "nil"), type: \(type), issuer: \(issuer), credentialSubject: [\(subjectStrings)], issuanceDate: \(issuanceDate), expirationDate: \(expirationDate ?? "nil"), proof: \(proof ?? []), version: \(version ?? "nil"))"
    }
}
