//
//  AnonCredsEncoder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import CryptoKit
import BigInt

public class AnonCredsEncoder {

    public static func checkEncodes(anonCredsProof: AnonCredsProof) throws {
        for (referent, attribute) in anonCredsProof.requestedProof.revealedAttrs {
            guard checkValidCredentialValueEncoding(raw: attribute.raw, encoded: attribute.encoded) else {
                throw CredoError(
                    "The encoded value for '\(referent)' is invalid. " +
                    "Expected '\(AnonCredsEncoder.encodeCredentialValue(attribute.raw))'. " +
                    "Actual '\(attribute.encoded)'"
                )
            }
        }

        for (_, group) in anonCredsProof.requestedProof.revealedAttrGroups ?? [:] {
            for (attrName, attr) in group.values {
                guard checkValidCredentialValueEncoding(raw: attr.raw, encoded: attr.encoded) else {
                    throw CredoError(
                        "The encoded value for '\(attrName)' is invalid. " +
                        "Expected '\(AnonCredsEncoder.encodeCredentialValue(attr.raw))'. " +
                        "Actual '\(attr.encoded)'"
                    )
                }
            }
        }
    }

    private static func checkValidCredentialValueEncoding(raw: Any, encoded: String) -> Bool {
        return encoded == AnonCredsEncoder.encodeCredentialValue(raw)
    }

    public static func encodeCredentialValue(_ value: Any?) -> String {
        guard let value = value else {
            return sha256Encode("None")
        }

        if let b = value as? Bool {
            return b ? "1" : "0"
        }

        if let n = value as? NSNumber {
            let intValue = n.intValue
            if intValue <= Int32.max && intValue >= Int32.min {
                return String(intValue)
            }
        }

        if let s = value as? String {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.isEmpty {
                return sha256Encode("None")
            }

            if let intValue = Int32(trimmed) {
                return String(intValue)
            }

            return sha256Encode(trimmed)
        }

        return sha256Encode(String(describing: value))
    }

    private static func sha256Encode(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        let bigint = BigUInt(Data(hash))
        return bigint.description
    }
}
