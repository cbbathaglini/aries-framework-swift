//
//  AnonCredsSchema.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 23/09/25.
//

import Foundation

public struct AnonCredsSchema: Codable, CustomStringConvertible {
    public var issuerId: String
    public var name: String
    public var version: String
    public var attrNames: [String]

    public func toJson(pretty: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        if pretty {
            encoder.outputFormatting = .prettyPrinted
        }

        let jsonData = try encoder.encode(self)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw NSError(domain: "JsonEncoding", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON data to string."])
        }
        return jsonString
    }
    
    public var description: String {
        return """
        AnonCredsSchema(
          issuerId: "\(issuerId)",
          name: "\(name)",
          version: "\(version)",
          attrNames: \(attrNames)
        )
        """
    }
}
