//
//  Credential.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

class Credential {
    
    static func convertAttributesToCredentialValues(
        _ attributes: [CredentialPreviewAttribute]
    ) -> [String: AnonCredsCredentialValue] {
        var result: [String: AnonCredsCredentialValue] = [:]
        
        for attribute in attributes {
            let encoded = AnonCredsEncoder.encodeCredentialValue(attribute.value)
            result[attribute.name] = AnonCredsCredentialValue(raw: attribute.value, encoded: encoded)
        }
        
        return result
    }

    static func assertCredentialValuesMatch(
        _ firstValues: [String: AnonCredsCredentialValue],
        _ secondValues: [String: AnonCredsCredentialValue]
    ) throws {
        guard firstValues.count == secondValues.count else {
            throw NSError(domain: "CredentialError", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Number of values in first entry (\(firstValues.count)) does not match number of values in second entry (\(secondValues.count))"
            ])
        }

        for key in firstValues.keys {
            guard let first = firstValues[key],
                  let second = secondValues[key] else {
                throw NSError(domain: "CredentialError", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "Second cred values object has no value for key '\(key)'"
                ])
            }

            if first.encoded != second.encoded {
                throw NSError(domain: "CredentialError", code: 3, userInfo: [
                    NSLocalizedDescriptionKey: "Encoded credential values for key '\(key)' do not match"
                ])
            }

            if first.raw != second.raw {
                throw NSError(domain: "CredentialError", code: 4, userInfo: [
                    NSLocalizedDescriptionKey: "Raw credential values for key '\(key)' do not match"
                ])
            }
        }
    }

    static func checkCredentialValuesMatch(
        _ firstValues: [String: AnonCredsCredentialValue],
        _ secondValues: [String: AnonCredsCredentialValue]
    ) -> Bool {
        do {
            try assertCredentialValuesMatch(firstValues, secondValues)
            return true
        } catch {
            return false
        }
    }
}
