//
//  RequestedCredentialsAnoncreds.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation
import AnyCodable

public struct RequestedCredentialsAnoncreds: Codable {
    
    public var requestedAttributes: [String: RequestedAttributeAnonCreds] = [:]
    public var requestedPredicates: [String: RequestedPredicateAnonCreds] = [:]
    public var selfAttestedAttributes: [String: String] = [:]
    
    
    
    enum CodingKeys: String, CodingKey {
        case requestedAttributes = "requested_attributes"
        case requestedPredicates = "requested_predicates"
        case selfAttestedAttributes = "self_attested_attributes"
    }

    public func toJsonString() throws -> String {
        var root: [String: Any] = [:]

        // Convert requestedAttributes
        let attributes: [String: AnyCodable] = Dictionary(
            uniqueKeysWithValues: requestedAttributes.map { (key, value) in
                (key, AnyCodable(value.toStringAnyCodable()))
            }
        )
        
        let predicates: [String: AnyCodable] = Dictionary(
            uniqueKeysWithValues: requestedPredicates.map { (key, value) in
                (key, AnyCodable(value.toStringAnyCodable()))
            }
        )

        root["requested_attributes"] = attributes
        root["requested_predicates"] = predicates
        root["self_attested_attributes"] = selfAttestedAttributes

        let jsonData = try JSONSerialization.data(withJSONObject: root, options: [])
        return String(data: jsonData, encoding: .utf8)!
    }

    // MARK: - Normalization
    public mutating func normalizeAllAttributes() {
        for key in requestedAttributes.keys {
            if var credInfo = requestedAttributes[key]?.credentialInfo {
                let normalized = credInfo.attributes.mapValues { "\($0)" }
                credInfo.attributes = normalized
                requestedAttributes[key]?.credentialInfo = credInfo
            }
        }

        for key in requestedPredicates.keys {
            if var credInfo = requestedPredicates[key]?.credentialInfo {
                let normalized = credInfo.attributes.mapValues { "\($0)" }
                credInfo.attributes = normalized
                requestedPredicates[key]?.credentialInfo = credInfo
            }
        }
    }
    
    public func getCredentialIdentifiers() -> [String] {
        var credIds = Set<String>()

        for (_, attr) in requestedAttributes {
            credIds.insert(attr.credentialId)
        }

        for (_, pred) in requestedPredicates {
            credIds.insert(pred.credentialId)
        }

        return Array(credIds)
    }
    
    public static func mapToRequestedCredentials(from root: [String: Any]?) throws -> RequestedCredentialsAnoncreds {
        guard let root = root else {
            return RequestedCredentialsAnoncreds()
        }

        let cleaned = cleanForJSONSerialization(root)
        let sanitized = deepSanitizeJSON(cleaned)

        guard let serializableDict = sanitized as? [String: Any] else {
            throw NSError(domain: "Serialization", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Sanitized root is not a [String: Any]"
            ])
        }


        let jsonData = try JSONSerialization.data(withJSONObject: serializableDict, options: [])
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys

        return try decoder.decode(RequestedCredentialsAnoncreds.self, from: jsonData)
    
    }
    
    private static func deepSanitizeJSON(_ object: Any) -> Any {
        switch object {
        case let dict as [String: Any]:
            var newDict: [String: Any] = [:]
            for (key, value) in dict {
                if "\(value)" == "()" || value is NSNull {
                    continue
                }
                let cleaned = deepSanitizeJSON(value)
                if !(cleaned is NSNull) {
                    newDict[key] = cleaned
                }
            }
            return newDict

        case let array as [Any]:
            return array.compactMap { element -> Any? in
                let cleaned = deepSanitizeJSON(element)
                return "\(cleaned)" == "()" ? nil : cleaned
            }

        default:
            return object
        }
    }
    
    private static func removeInvalidValues(_ object: Any) -> Any {
        switch object {
        case let dict as [String: Any]:
            var newDict: [String: Any] = [:]
            for (key, value) in dict {
                if "\(value)" == "()" { continue }
                if value is NSNull { continue }
                newDict[key] = removeInvalidValues(value)
            }
            return newDict

        case let array as [Any]:
            return array.compactMap { item in
                let cleaned = removeInvalidValues(item)
                return "\(cleaned)" == "()" ? nil : cleaned
            }

        default:
            return object
        }
    }
    
    // MARK: - Decode from JSON dictionary
    public static func from(jsonDict: [String: Any]?) throws -> RequestedCredentialsAnoncreds {
        guard let jsonDict = jsonDict else {
            return RequestedCredentialsAnoncreds()
        }

        let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
        let decoder = JSONDecoder()
        return try decoder.decode(RequestedCredentialsAnoncreds.self, from: jsonData)
    }
    
    public func toMap() -> [String: AnyCodable] {
        var root: [String: AnyCodable] = [:]

        func encodeOptional<T>(_ value: T?) -> AnyCodable {
            AnyCodable(value ?? (nil as Any?))
        }

        // MARK: - Requested Attributes
        let attributes = requestedAttributes.mapValues { attr in
            AnyCodable([
                "credentialId": AnyCodable(attr.credentialId),
                "revealed": AnyCodable(attr.revealed),
                "timestamp": encodeOptional(attr.timestamp),
                "credentialInfo": encodeOptional(attr.credentialInfo?.toJsonElement()),
                "revoked": encodeOptional(attr.revoked)
            ])
        }

        // MARK: - Requested Predicates
        let predicates = requestedPredicates.mapValues { pred in
            AnyCodable([
                "credentialId": AnyCodable(pred.credentialId),
                "timestamp": encodeOptional(pred.timestamp),
                "credentialInfo": encodeOptional(pred.credentialInfo?.toJsonElement()),
                "revoked": encodeOptional(pred.revoked)
            ])
        }

        // MARK: - Self-Attested Attributes
        let selfAttested = selfAttestedAttributes.mapValues { value in AnyCodable(value) }

        // MARK: - Root Map
        root["requested_attributes"] = AnyCodable(attributes)
        root["requested_predicates"] = AnyCodable(predicates)
        root["self_attested_attributes"] = AnyCodable(selfAttested)

        return root
    }
    
    private static func cleanForJSONSerialization(_ object: Any) -> Any {
        if let anyCodable = object as? AnyCodable {
            return cleanForJSONSerialization(anyCodable.value)
        }

        if let dictionary = object as? [String: Any] {
            return dictionary.mapValues { cleanForJSONSerialization($0) }
        }

        if let dictionary = object as? [String: AnyCodable] {
            return dictionary.mapValues { cleanForJSONSerialization($0.value) }
        }

        if let array = object as? [Any] {
            return array.map { cleanForJSONSerialization($0) }
        }

        if let array = object as? [AnyCodable] {
            return array.map { cleanForJSONSerialization($0.value) }
        }

        if JSONSerialization.isValidJSONObject([ "value": object ]) {
            return object
        }

        return String(describing: object)
    }
}
