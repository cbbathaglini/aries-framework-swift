//
//  CredentialEntryResult.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation
import AnyCodable

struct CredentialEntryResult: Codable {
    let linkSecretId: String
    let credentialEntry: CredentialEntry
    let credentialId: String

    func toJson(prettyPrint: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        if prettyPrint {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

struct CredentialEntry: Codable {
    let credential: AnyCodable
    let timestamp: UInt64?
    let revocationState: AnyCodable?

    func toJson(prettyPrint: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        if prettyPrint {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
