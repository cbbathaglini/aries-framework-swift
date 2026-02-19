//
//  LinkedDataProofWrapper.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 01/10/25.
//

import Foundation
import AnyCodable

public enum LinkedDataProofWrapper: Decodable {
    case linkedDataProof(LinkedDataProof)
    case dataIntegrityProof(DataIntegrityProof)

    var base: LinkedDataProofBase {
        switch self {
        case .linkedDataProof(let proof): return proof
        case .dataIntegrityProof(let proof): return proof
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let temp = try container.decode([String: AnyCodable].self)

        if let type = temp["type"]?.value as? String {
            switch type {
            case "LinkedDataProof":
                let decoded = try JSONDecoder().decode(LinkedDataProof.self, from: JSONSerialization.data(withJSONObject: temp))
                self = .linkedDataProof(decoded)
            case "DataIntegrityProof":
                let decoded = try JSONDecoder().decode(DataIntegrityProof.self, from: JSONSerialization.data(withJSONObject: temp))
                self = .dataIntegrityProof(decoded)
            default:
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown proof type: \(type)")
            }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Missing 'type' in proof")
        }
    }
    
}
extension LinkedDataProofWrapper: Encodable {
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .linkedDataProof(let proof):
            try proof.encode(to: encoder)
        case .dataIntegrityProof(let proof):
            try proof.encode(to: encoder)
        }
    }
}
