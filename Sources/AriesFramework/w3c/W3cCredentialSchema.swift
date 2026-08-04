//
//  W3cCredentialSchema.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct W3cCredentialSchema: Codable {
    public let id: String
    public let type: String

    enum CodingKeys: String, CodingKey {
        case id
        case type
    }

    public init(id: String, type: String) {
        self.id = id
        self.type = type
    }
}
