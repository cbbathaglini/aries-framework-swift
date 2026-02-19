//
//  AnonCredsProof.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import AnyCodable

public struct AnonCredsProof: Codable {
    public var requestedProof: RequestedProof
    public var proof: [String: AnyCodable]?  // JsonElement ≈ Dictionary
    public var identifiers: [Identifier]
    
    enum CodingKeys: String, CodingKey {
        case requestedProof = "requested_proof"
        case proof
        case identifiers
    }

    public func toJson() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        let data = try encoder.encode(self)
        
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "JsonEncoding", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to convert proof JSON to string"])
        }
        return jsonString
    }
}
