//
//  AnonCredsCredentialRequest.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation
import AnyCodable

public struct AnonCredsCredentialRequest: Codable {
    public var proverDid: String?
    public var entropy: String?
    public var credDefId: String
    public var blindedMs: [String: AnyCodable]
    public var blindedMsCorrectnessProof: [String: AnyCodable]
    public var nonce: String

    func toJsonString() throws -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    static func fromJsonString(_ json: String) throws -> AnonCredsCredentialRequest {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = Data(json.utf8)
        return try decoder.decode(AnonCredsCredentialRequest.self, from: data)
    }
}
