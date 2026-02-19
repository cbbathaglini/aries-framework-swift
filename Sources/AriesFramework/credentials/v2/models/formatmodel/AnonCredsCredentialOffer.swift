//
//  AnonCredsCredentialOffer.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public struct AnonCredsCredentialOffer: Codable, CustomStringConvertible {
    let schemaId: String
    let credDefId: String
    let nonce: String
    let keyCorrectnessProof: KeyCorrectnessProof?

    public var description: String {
        return "AnonCredsCredentialOffer(schemaId='\(schemaId)', credDefId='\(credDefId)', nonce='\(nonce)', keyCorrectnessProof=\(String(describing: keyCorrectnessProof)))"
    }

    func toJsonString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(self),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "Error encoding AnonCredsCredentialOffer"
        }
        return jsonString
    }

    static func fromAttachment(_ attachment: Attachment) throws -> AnonCredsCredentialOffer {
        guard let base64String = attachment.data.base64,
              let decodedData = Data(base64Encoded: base64String),
              let jsonObject = try? JSONSerialization.jsonObject(with: decodedData),
              let map = jsonObject as? [String: Any] else {
            throw CredoError("Invalid attachment data for AnonCredsCredentialOffer")
        }

        guard let schemaId = map["schema_id"] as? String,
              let credDefId = map["cred_def_id"] as? String,
              let nonce = map["nonce"] as? String else {
            throw CredoError("Missing required fields in AnonCredsCredentialOffer")
        }

        let proofData: Data?
        if let proofDict = map["key_correctness_proof"] {
            proofData = try? JSONSerialization.data(withJSONObject: proofDict)
        } else {
            proofData = nil
        }

        let keyCorrectnessProof = proofData.flatMap {
            try? JSONDecoder().decode(KeyCorrectnessProof.self, from: $0)
        }

        return AnonCredsCredentialOffer(
            schemaId: schemaId,
            credDefId: credDefId,
            nonce: nonce,
            keyCorrectnessProof: keyCorrectnessProof
        )
    }
}
