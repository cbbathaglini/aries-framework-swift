//
//  W3cJsonLdVerifiableCredential.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import AnyCodable

public struct W3cJsonLdVerifiableCredential : Codable{
    public let context: [AnyCodable]
    public var id: String?
    public let type: [String]
    public let issuer: AnyCodable
    public let issuanceDate: String
    public let credentialSubject: [W3cCredentialSubject]
    public let expirationDate: String?
    public let credentialSchema: [W3cCredentialSchema]?
    public let credentialStatus: W3cCredentialStatus?
    public let proofs: [AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case id
        case type
        case issuer
        case issuanceDate
        case credentialSubject
        case expirationDate
        case credentialSchema
        case credentialStatus
        case proofs = "proof"
    }
    
    public init(
        context: [AnyCodable],
        id: String?,
        type: [String],
        issuer: AnyCodable,
        issuanceDate: String,
        credentialSubject: [W3cCredentialSubject],
        expirationDate: String?,
        credentialSchema: [W3cCredentialSchema]?,
        credentialStatus: W3cCredentialStatus?,
        proofs: [AnyCodable]?
    ) {
        self.context = context
        self.id = id
        self.type = type
        self.issuer = issuer
        self.issuanceDate = issuanceDate
        self.credentialSubject = credentialSubject
        self.expirationDate = expirationDate
        self.credentialSchema = credentialSchema
        self.credentialStatus = credentialStatus
        self.proofs = proofs
    }
    
    public var claimFormat: String {
        return "ldp_vc"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        context = try container.decode([AnyCodable].self, forKey: .context)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        type = try container.decode([String].self, forKey: .type)
        issuer = try container.decode(AnyCodable.self, forKey: .issuer)
        issuanceDate = try container.decode(String.self, forKey: .issuanceDate)
        credentialSubject = try container.decode([W3cCredentialSubject].self, forKey: .credentialSubject)
        expirationDate = try container.decodeIfPresent(String.self, forKey: .expirationDate)
        credentialSchema = try container.decodeIfPresent([W3cCredentialSchema].self, forKey: .credentialSchema)
        credentialStatus = try container.decodeIfPresent(W3cCredentialStatus.self, forKey: .credentialStatus)
        let proofWrappers = try container.decodeIfPresent([AnyCodable].self, forKey: .proofs) //revisar
        self.proofs = proofWrappers
    }
    
    public static func fromJson(_ json: String) throws -> W3cJsonLdVerifiableCredential {
        print("json >> \(json)")
        let jsonData = json.data(using: .utf8)!
        return try JSONDecoder().decode(W3cJsonLdVerifiableCredential.self, from: jsonData)
    }
    
}

extension W3cJsonLdVerifiableCredential {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(context, forKey: .context)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(issuer, forKey: .issuer)
        try container.encode(issuanceDate, forKey: .issuanceDate)
        try container.encode(credentialSubject, forKey: .credentialSubject)
        try container.encodeIfPresent(expirationDate, forKey: .expirationDate)
        try container.encodeIfPresent(credentialSchema, forKey: .credentialSchema)
        try container.encodeIfPresent(credentialStatus, forKey: .credentialStatus)

        if let proofs = proofs {
            let wrappers: [LinkedDataProofWrapper] = proofs.compactMap { anyCodableProof in
                guard let dict = anyCodableProof.value as? [String: Any] else {
                    print("⚠️ Not a valid dictionary")
                    return nil
                }

                do {
                    let data = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()

                    if let linkedDataProof = try? decoder.decode(LinkedDataProof.self, from: data) {
                        return .linkedDataProof(linkedDataProof)
                    }

                    if let integrityProof = try? decoder.decode(DataIntegrityProof.self, from: data) {
                        return .dataIntegrityProof(integrityProof)
                    }

                    print("❌ Type unknown of proof: \(dict)")
                    return nil

                } catch {
                    print("❌ Error decode proof: \(error)")
                    return nil
                }
            }

            try container.encode(wrappers, forKey: .proofs)
        }
    }
}


