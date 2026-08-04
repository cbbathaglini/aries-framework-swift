//
//  AnonCredsRevocationStatusList.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import indy_besu_vdr_uniffi

public struct AnonCredsRevocationStatusList: Codable {
    let issuerId: String
    let revRegDefId: String
    let revocationList: [Int]
    let currentAccumulator: String
    let timestamp: UInt64

    static func fromRevocationStatusList(_ revocation: indy_besu_vdr_uniffi.RevocationStatusList) -> AnonCredsRevocationStatusList {
        let intList = revocation.revocationList.map { Int($0) }
        return AnonCredsRevocationStatusList(
            issuerId: revocation.issuerId,
            revRegDefId: revocation.revRegDefId,
            revocationList: intList,
            currentAccumulator: revocation.currentAccumulator,
            timestamp: revocation.timestamp
        )
    }
    
    func toJson(pretty: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        
        if pretty {
            encoder.outputFormatting = [.prettyPrinted]
        }

        let data = try encoder.encode(self)

        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw CredoError("Failed to encode JSON as UTF-8 string")
        }

        return jsonString
    }
}
