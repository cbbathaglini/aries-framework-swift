//
//  W3cUtils.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation
import anoncreds_uniffi

class W3cUtils {
    static let VERSION_1_1 = "1.1"
    static let CONTEXT_VERSION_1_0 = "https://www.w3.org/2018/credentials/v1"
    static let VERIFIABLE_CREDENTIAL_TYPE = "VerifiableCredential"
    static let ANONCREDS_TYPE = "AnonCredsCredential"
    static let VERIFIABLE_PRESENTATION_TYPE = "VerifiablePresentation"

    static func isValidUri(_ input: String?) -> Bool {
        guard let input = input, !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        guard let url = URL(string: input), let scheme = url.scheme, !scheme.isEmpty else {
            return false
        }

        return true
    }
    
    static func getCredentialUniffiByW3cCredentialRecord(_ credentialRecord: W3cCredentialRecord) throws -> anoncreds_uniffi.Credential {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let jsonData = try encoder.encode(credentialRecord.credential)
        
        let jsonld = try JSONDecoder().decode(W3cJsonLdVerifiableCredential.self, from: jsonData)
        
        var jsonldData = try JSONEncoder().encode(jsonld)
        var jsonStr = String(data: jsonldData, encoding: .utf8) ?? ""
        
        jsonStr = jsonStr.replacingOccurrences(of: "\\\"", with: "")
        
   
        let pattern = "\"credentialSubject\"\\s*:\\s*\\[(\\{.*?\\})\\]"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(jsonStr.startIndex..., in: jsonStr)
            jsonStr = regex.stringByReplacingMatches(in: jsonStr, options: [], range: range, withTemplate: "\"credentialSubject\": $1")
        }
        return try anoncreds_uniffi.CredentialConversions().credentialFromW3cJson(w3cCredentialJson: jsonStr)
    }
}
