//
//  RevRegDefDto.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 03/02/26.
//

import Foundation

struct RevRegDefDto: Codable {
    let issuerId: String
    let revocDefType: String
    let credDefId: String
    let tag: String
    let value: String
}
