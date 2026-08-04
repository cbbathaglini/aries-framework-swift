//
//  AnonCredsCredentialDefinition.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public class AnonCredsCredentialDefinition: Codable {
    public var issuerId: String
    public var  schemaId: String
    public var  type: String
    public var  tag: String
    public var  value: CredentialDefinitionValue

    enum CodingKeys: String, CodingKey {
        case issuerId
        case schemaId
        case type
        case tag
        case value
    }

    init(issuerId: String, schemaId: String, type: String = "CL", tag: String, value: CredentialDefinitionValue) {
        self.issuerId = issuerId
        self.schemaId = schemaId
        self.type = type
        self.tag = tag
        self.value = value
    }

    public func toJson(pretty: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        if pretty {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
