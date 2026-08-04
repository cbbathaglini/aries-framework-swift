//
//  W3cCredential.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation
import AnyCodable

public struct W3cCredential: Codable, CustomStringConvertible {
    public let context: [AnyCodable]
    public let id: String?
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
        case id, type, issuer, issuanceDate, credentialSubject, expirationDate
        case credentialSchema, credentialStatus, proofs = "proof"
    }

    // Descrição tipo toString()
    public var description: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(self), let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        } else {
            return "W3cCredential(invalid JSON)"
        }
    }
}
