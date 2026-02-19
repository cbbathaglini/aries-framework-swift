//
//  AnonCredsSchemas.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct AnonCredsSchemas: Codable {
    public var schemas: [String: AnonCredsSchema]

    public init(schemas: [String: AnonCredsSchema] = [:]) {
        self.schemas = schemas
    }
}
