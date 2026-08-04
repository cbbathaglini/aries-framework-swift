//
//  AnonCredsSelectedCredentials.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import AnyCodable

public struct AnonCredsSelectedCredentials: Codable, CustomStringConvertible {
    public var attributes: [String: AnonCredsRequestedAttributeMatch]
    public var predicates: [String: AnonCredsRequestedPredicateMatch]
    public var selfAttestedAttributes: [String: String]

    enum CodingKeys: String, CodingKey {
        case attributes = "requested_attributes"
        case predicates = "requested_predicates"
        case selfAttestedAttributes = "self_attested_attributes"
    }
    
    static func convert(from proofFormats: [String: Any]?) throws -> AnonCredsSelectedCredentials {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        func decodeMap<T: Decodable>(_ key: String) throws -> [String: T] {
            guard let rawValue = proofFormats?[key] else {
                return [:]
            }

            let unwrapped: Any
            if let anyCodable = rawValue as? AnyCodable {
                unwrapped = anyCodable.value
            } else {
                unwrapped = rawValue
            }

            guard let rawDict = unwrapped as? [String: Any] else {
                return [:]
            }

            func sanitize(_ obj: Any) -> Any {
                if let dict = obj as? [String: Any] {
                    return dict.mapValues { sanitize($0) }
                } else if let arr = obj as? [Any] {
                    return arr.map { sanitize($0) }
                } else if let codable = obj as? AnyCodable {
                    return sanitize(codable.value)
                } else if obj is NSNull {
                    return NSNull()
                } else if JSONSerialization.isValidJSONObject([ "v": obj ]) {
                    return obj
                } else {
                    return String(describing: obj)
                }
            }

            let cleanDict = sanitize(rawDict)
            let data = try JSONSerialization.data(withJSONObject: cleanDict, options: [])
            return try decoder.decode([String: T].self, from: data)
        }

        let attributes = try decodeMap("requested_attributes") as [String: AnonCredsRequestedAttributeMatch]
        let predicates = try decodeMap("requested_predicates") as [String: AnonCredsRequestedPredicateMatch]
        let selfAttested = try decodeMap("self_attested_attributes") as [String: String]

        return AnonCredsSelectedCredentials(
            attributes: attributes,
            predicates: predicates,
            selfAttestedAttributes: selfAttested
        )
    }
    
    public var description: String {
        var components: [String] = []
        components.append("attributes: \(attributes)")
        components.append("predicates: \(predicates)")
        components.append("selfAttestedAttributes: \(selfAttestedAttributes)")
        return "AnonCredsSelectedCredentials(\n  " + components.joined(separator: ",\n  ") + "\n)"
    }
}
