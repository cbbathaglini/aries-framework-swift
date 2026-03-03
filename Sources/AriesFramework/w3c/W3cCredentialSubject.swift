//
//  W3cCredentialSubject.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import AnyCodable

public struct W3cCredentialSubject: Codable {
    public var id: String?
    public var claims: [String: AnyCodable]?

    public init(id: String? = nil, claims: [String: AnyCodable]? = nil) {
        self.id = id
        self.claims = claims
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        var tempClaims: [String: AnyCodable] = [:]
        var foundId: String? = nil

        for key in container.allKeys {
            switch key.stringValue {
            case "@id":
                foundId = try container.decodeIfPresent(String.self, forKey: key)
            case "id":
                let v = try container.decodeIfPresent(String.self, forKey: key)
                if foundId == nil { foundId = v }
            default:
                tempClaims[key.stringValue] = try container.decode(AnyCodable.self, forKey: key)
            }
        }

        self.id = foundId
        self.claims = tempClaims
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)

        if let id = id {
            try container.encode(id, forKey: DynamicCodingKeys(stringValue: "@id")!)
        }

        if let claims = claims {
            for (key, value) in claims {
                if key == "@id" || key == "id" { continue }
                try container.encode(value, forKey: DynamicCodingKeys(stringValue: key)!)
            }
        }
    }
        

    struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }
    }
}
