//
//  RevocationRegistryValue.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct RevocationRegistryValue: Codable {
    let publicKeys: PublicKeys
    let maxCredNum: Int
    let tailsLocation: String
    let tailsHash: String
    let issuanceType: String? 
}

public struct PublicKeys: Codable {
    let accumKey: AccumKey
}

