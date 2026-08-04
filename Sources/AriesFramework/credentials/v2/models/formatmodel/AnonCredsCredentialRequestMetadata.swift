//
//  AnonCredsCredentialRequestMetadata.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct AnonCredsCredentialRequestMetadata: Codable {
    public let linkSecretBlindingData: AnonCredsLinkSecretBlindingData
    public let linkSecretName: String
    public let nonce: String

    enum CodingKeys: String, CodingKey {
        case linkSecretBlindingData = "link_secret_blinding_data"
        case linkSecretName = "link_secret_name"
        case nonce
    }

    func toJson(pretty: Bool = false) throws -> String {
        let encoder = JSONEncoder()
        if pretty {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    static func fromJsonString(_ json: String) throws -> AnonCredsCredentialRequestMetadata {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(AnonCredsCredentialRequestMetadata.self, from: data)
    }

    var description: String {
        return "AnonCredsCredentialRequestMetadata(linkSecretBlindingData: \(linkSecretBlindingData), linkSecretName: \(linkSecretName), nonce: \(nonce))"
    }
}
