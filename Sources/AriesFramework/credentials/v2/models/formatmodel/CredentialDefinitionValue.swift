//
//  CredentialDefinitionValue.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import AnyCodable

public class CredentialDefinitionValue : Codable{
    public var primary: [String: AnyCodable] = [:]
    public var revocation: AnyCodable? = nil

    enum CodingKeys: String, CodingKey {
        case primary
        case revocation
    }
}
