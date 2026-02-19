//
//  ReferentWalletQuery.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import AnyCodable

public struct ReferentWalletQuery: Codable {
    public var referents: [String: WalletQuery]
}

public typealias WalletQuery = [String: AnyCodable?]
