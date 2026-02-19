//
//  AnonCredsRevocationRegistryDefinition.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct AnonCredsRevocationRegistryDefinition: Codable {
    let issuerId: String
    let revocDefType: String
    let credDefId: String
    let tag: String
    let value: RevocationRegistryValue

    init(
        issuerId: String,
        revocDefType: String = "CL_ACCUM",
        credDefId: String,
        tag: String,
        value: RevocationRegistryValue
    ) {
        self.issuerId = issuerId
        self.revocDefType = revocDefType
        self.credDefId = credDefId
        self.tag = tag
        self.value = value
    }

    func toJson(pretty: Bool = true) -> String? {
        let encoder = JSONEncoder()
        if pretty { encoder.outputFormatting = .prettyPrinted }

        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            logDebug("Error toJson AnonCredsRevocationRegistryDefinition: \(error)")
            return nil
        }
    }
}
