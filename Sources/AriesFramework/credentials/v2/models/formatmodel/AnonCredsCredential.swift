//
//  AnonCredsCredential.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation
import AnyCodable

public struct AnonCredsCredential: Codable, CustomStringConvertible {
    public var schemaId: String
    public var credDefId: String
    public var revRegId: String?
    public var values: [String: AnonCredsCredentialValue]
    public var signature: [String: AnyCodable]
    public var signatureCorrectnessProof: [String: AnyCodable]
    public var revReg: [String: AnyCodable]?
    public var witness: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case schemaId = "schema_id"
        case credDefId = "cred_def_id"
        case revRegId = "rev_reg_id"
        case values
        case signature
        case signatureCorrectnessProof = "signature_correctness_proof"
        case revReg = "rev_reg"
        case witness
    }
    
    public var description: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let jsonData = try encoder.encode(self)
            return String(data: jsonData, encoding: .utf8) ?? "AnonCredsCredential(invalid UTF8)"
        } catch {
            return "AnonCredsCredential(encoding error: \(error))"
        }
    }
}

extension AnonCredsCredential {
    public func toJson() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys] // similar a prettyPrint
        return try encoder.encode(self).toUtf8String()
    }
}

fileprivate extension Data {
    func toUtf8String() -> String {
        String(decoding: self, as: UTF8.self)
    }
}
