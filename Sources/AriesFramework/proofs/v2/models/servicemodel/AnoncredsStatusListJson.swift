//
//  AnoncredsStatusListJson.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/11/25.
//

struct AnoncredsStatusListJson: Codable {
    let issuerId: String
    let currentAccumulator: String
    let revRegDefId: String
    let revocationList: [UInt32]
    let timestamp: Int
}
