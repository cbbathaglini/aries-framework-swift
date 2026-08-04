//
//  AnonCredsLinkSecretBlindingData.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct AnonCredsLinkSecretBlindingData: Codable {
    public let vPrime: String
    public let vrPrime: String?

    enum CodingKeys: String, CodingKey {
        case vPrime = "v_prime"
        case vrPrime = "vr_prime"
    }
}
