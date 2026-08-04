//
//  FetchSchemaReturn.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

public struct FetchSchemaReturn: Codable, CustomStringConvertible {
    public let schema: AnonCredsSchema
    public let schemaId: String
    public let indyNamespace: String?

    public static func fromJson(_ jsonElementSchema: Any, schemaId: String) -> FetchSchemaReturn? {
        guard
            let json = jsonElementSchema as? [String: Any],
            let attrNamesArray = json["attrNames"] as? [Any]
        else {
            print("Invalid schema JSON structure")
            return nil
        }

        let attrNames: [String] = attrNamesArray.compactMap { "\($0)".replacingOccurrences(of: "\"", with: "") }

        guard
            let issuerIdRaw = json["issuerId"],
            let nameRaw = json["name"],
            let versionRaw = json["version"]
        else {
            print("Missing required fields in schema")
            return nil
        }

        let anoncredsSchema = AnonCredsSchema(
            issuerId: "\(issuerIdRaw)".replacingOccurrences(of: "\"", with: ""),
            name: "\(nameRaw)".replacingOccurrences(of: "\"", with: ""),
            version: "\(versionRaw)".replacingOccurrences(of: "\"", with: ""),
            attrNames: attrNames
        )

        return FetchSchemaReturn(
            schema: anoncredsSchema,
            schemaId: schemaId,
            indyNamespace: nil
        )
    }
    
    public var description: String {
        return """
        FetchSchemaReturn(
            schema: \(schema),
            schemaId: "\(schemaId)",
            indyNamespace: "\(indyNamespace ?? "nil")"
        )
        """
    }
}
