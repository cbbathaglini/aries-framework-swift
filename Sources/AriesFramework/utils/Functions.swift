//
//  Functions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation
import CryptoKit
import BigInt

enum Functions {
    
    
    static func createAndLinkAttachmentsToPreview(
        attachments: [LinkedAttachment],
        previewAttributes: [CredentialPreviewAttribute]
    ) throws -> [CredentialPreviewAttribute] {
        let existingAttributeNames = Set(previewAttributes.map { $0.name })
        var newPreviewAttributes = previewAttributes

        for linkedAttachment in attachments {
            if existingAttributeNames.contains(linkedAttachment.attributeName) {
                throw NSError(domain: "CredoError", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "linkedAttachment \(linkedAttachment.attributeName) already exists in the preview"
                ])
            } else {
                let encodedValue = try encodeAttachment(attachment: linkedAttachment.attachment)
                let newAttribute = CredentialPreviewAttribute(
                    name: linkedAttachment.attributeName,
                    mimeType: linkedAttachment.attachment.mimetype ?? "mimetype not informed",
                    value: encodedValue
                )
                newPreviewAttributes.append(newAttribute)
            }
        }

        return newPreviewAttributes
    }

    static func encodeCredentialValue(_ value: Any?) -> String {
        if let boolVal = value as? Bool {
            return boolVal ? "1" : "0"
        }

        if let intVal = value as? Int {
            return String(intVal)
        }

        if let stringVal = value as? String, let intVal = Int(stringVal) {
            return String(intVal)
        }

        let stringValue: String
        if let val = value {
            stringValue = String(describing: val)
        } else {
            stringValue = "None"
        }

        let data = Data(stringValue.utf8)
        let hash = SHA256.hash(data: data)
        let bigint = BigUInt(Data(hash))
        return bigint.description
    }

    static func mapAttributeRawValuesToAnonCredsCredentialValues(
        record: [String: Any]
    ) throws -> [String: AnonCredsCredentialValue] {
        var result: [String: AnonCredsCredentialValue] = [:]

        for (key, value) in record {
            if value is [String: Any] {
                throw NSError(domain: "CredoError", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Unsupported value type: object for W3cAnonCreds Credential"
                ])
            }

            let raw = String(describing: value)
            let encoded = encodeCredentialValue(value)
            result[key] = AnonCredsCredentialValue(raw: raw, encoded: encoded)
        }

        return result
    }

    static func encodeAttachment(
        attachment: Attachment,
        hashAlgorithm: String = "sha-256",
        baseName: String = "base58btc"
    ) throws -> String {
        let data = attachment.data

        if let sha = data.sha256 {
            return "hl:\(sha)"
        }

        if let base64 = data.base64,
           let bytes = Data(base64Encoded: base64) {
            return "hl:\(base58btcEncode(bytes))"
        }

        if data.json != nil {
            throw NSError(domain: "CredoError", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Attachment (\(attachment.id)) has JSON encoded data. This is currently not supported"
            ])
        }

        throw NSError(domain: "CredoError", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Attachment (\(attachment.id)) has no data to create a link with"
        ])
    }

    // MARK: Base58btc Encoding (Simplified)
    static func base58btcEncode(_ input: Data) -> String {
        let alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
        var intData = BigUInt(input)
        var result = ""

        while intData > 0 {
            let (quotient, remainder) = intData.quotientAndRemainder(dividingBy: 58)
            result.insert(alphabet[String.Index(utf16Offset: Int(remainder), in: alphabet)], at: result.startIndex)
            intData = quotient
        }

        // Add leading zeroes
        for byte in input {
            if byte == 0 {
                result.insert("1", at: result.startIndex)
            } else {
                break
            }
        }

        return result
    }
}
