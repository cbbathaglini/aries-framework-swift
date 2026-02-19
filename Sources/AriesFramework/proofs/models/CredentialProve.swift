//
//  CredentialProve.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation

struct CredentialProve: Codable {
    let entryIndex: Int
    let referent: String
    let isPredicate: Bool
    let reveal: Bool
}
