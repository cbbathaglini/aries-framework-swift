//
//  JsonOperations.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import AnyCodable

public func convertJsonStringToJsonObject(_ jsonString: String) throws -> AnyCodable {
    let data = Data(jsonString.utf8)
    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
    return AnyCodable(jsonObject)
}

 public func convertMapToJson(_ map: [String: Any?]) -> [String: Any] {
    return map.mapValues { value in
        switch value {
        case nil:
            return NSNull()
        case let v as Bool:
            return v
        case let v as Int:
            return v
        case let v as Double:
            return v
        case let v as Float:
            return v
        case let v as String:
            return v
        case let v as [String: Any?]:
            return convertMapToJson(v)
        case let v as [Any?]:
            return v.map { elementToJson($0) }
        default:
            return String(describing: value!) // Fallback: convert to string
        }
    }
}

public func elementToJson(_ value: Any?) -> Any {
    switch value {
    case nil:
        return NSNull()
    case let v as Bool:
        return v
    case let v as Int:
        return v
    case let v as Double:
        return v
    case let v as Float:
        return v
    case let v as String:
        return v
    case let v as [String: Any?]:
        return convertMapToJson(v)
    case let v as [Any?]:
        return v.map { elementToJson($0) }
    default:
        return String(describing: value!) // Fallback
    }
}

public func mapToJson(_ map: [String: Any?]) -> [String: Any] {
    return map.mapValues { value in
        return elementToJson(value)
    }
}

public func toJsonData(_ map: [String: Any]) -> Data? {
    try? JSONSerialization.data(withJSONObject: map, options: [])
}

public func toJsonString(_ map: [String: Any]) -> String? {
    guard let data = toJsonData(map) else { return nil }
    return String(data: data, encoding: .utf8)
}

public func decodeMetadata<T: Decodable>(_ anyCodable: AnyCodable, as type: T.Type) throws -> T {
    guard JSONSerialization.isValidJSONObject(anyCodable.value),
          let jsonData = try? JSONSerialization.data(withJSONObject: anyCodable.value, options: []) else {
        throw NSError(domain: "Decoder", code: 0, userInfo: [NSLocalizedDescriptionKey: "metadata is not a valid JSON object"])
    }

    return try JSONDecoder().decode(T.self, from: jsonData)
}


