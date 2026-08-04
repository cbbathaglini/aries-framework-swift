//
//  BestPracticeNonRevokedInterval.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

public struct BestPracticeNonRevokedInterval: Codable {
    let from: UInt64?
    let to: UInt64
}

extension BestPracticeNonRevokedInterval {
    private enum CodingKeys: String, CodingKey {
        case from, to
    }
}
