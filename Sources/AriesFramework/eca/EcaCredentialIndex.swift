//
//  EcaCredentialIndex.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 05/03/26.
//

import Foundation
import AnyCodable

enum EcaCredentialIndex {
    static func extractSubjectId(from credentialText: String) throws -> String {
        let data = Data(credentialText.utf8)
        let obj = try JSONSerialization.jsonObject(with: data, options: [])
        guard
            let root = obj as? [String: Any],
            let cred = root["credential"] as? [String: Any],
            let subject = cred["credentialSubject"] as? [String: Any],
            let subjectId = subject["id"] as? String,
            !subjectId.isEmpty
        else {
            throw NSError(domain: "EcaCredentialIndex", code: 1, userInfo: [NSLocalizedDescriptionKey: "credentialSubject.id não encontrado"])
        }
        return subjectId
    }

    static func extractIssuer(from credentialText: String) -> String? {
        guard
            let data = credentialText.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data, options: []),
            let root = obj as? [String: Any],
            let cred = root["credential"] as? [String: Any],
            let issuer = cred["issuer"] as? String
        else { return nil }
        return issuer
    }
}
