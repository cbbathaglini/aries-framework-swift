//
//  FormatGeneric.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation
import AnyCodable

class FormatGeneric {
    static func getAnonCredsFormatGeneric<T: Decodable>(
        from formats: [String: Any]?
    ) throws -> T {
        try decodeFormat(from: formats, formatKey: "anoncreds")
    }

    static func getLegacyIndyFormatGeneric<T: Decodable>(
        from formats: [String: Any]?
    ) throws -> T {
        try decodeFormat(from: formats, formatKey: "indy")
    }

    
    private static func decodeFormat<T: Decodable>(
        from formats: [String: Any]?,
        formatKey: String
    ) throws -> T {
        guard let raw = formats?[formatKey] else {
            throw NSError(
                domain: "FormatGeneric",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Missing '\(formatKey)' format"]
            )
        }


        let object = unwrap(raw)

        let jsonData: Data
        if let jsonString = object as? String {
            jsonData = Data(jsonString.utf8)
        } else if JSONSerialization.isValidJSONObject(object) {
            jsonData = try JSONSerialization.data(withJSONObject: object, options: [])
        } else {
            throw NSError(
                domain: "FormatGeneric",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid JSON object for '\(formatKey)'"]
            )
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: jsonData)
    }

    private static func unwrap(_ value: Any) -> Any {
        if let anyCodable = value as? AnyCodable {
            return unwrap(anyCodable.value)
        } else if let dict = value as? [String: AnyCodable] {
            return dict.mapValues { unwrap($0.value) }
        } else if let dict = value as? [String: Any] {
            return dict.mapValues { unwrap($0) }
        } else if let array = value as? [AnyCodable] {
            return array.map { unwrap($0.value) }
        } else if let array = value as? [Any] {
            return array.map { unwrap($0) }
        } else {
            return value
        }
    }
}
