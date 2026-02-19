//
//  AnonCredsAcceptOfferFormat.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

public struct AnonCredsAcceptOfferFormat: Codable {
    public var linkSecretId: String?

    enum CodingKeys: String, CodingKey {
        case linkSecretId = "linkSecretId"
    }
}
