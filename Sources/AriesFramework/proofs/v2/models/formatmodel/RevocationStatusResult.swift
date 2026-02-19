//
//  RevocationStatusResult.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation

public struct RevocationStatusResult: Codable {
    public let isRevoked: Bool?
    public let timestamp: UInt64?

    public init(isRevoked: Bool?, timestamp: UInt64?) {
        self.isRevoked = isRevoked
        self.timestamp = timestamp
    }
}
