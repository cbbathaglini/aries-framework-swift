//
//  LinkedAttachment.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation
import CryptoKit

public struct LinkedAttachment : Codable {
    public let attributeName: String
    public let attachment: Attachment

    public static func fromOptions(_ options: LinkedAttachmentOptions) -> LinkedAttachment {
        var updatedAttachment = options.attachment
        updatedAttachment.id = getId(for: options.attachment)

        return LinkedAttachment(
            attributeName: options.name,
            attachment: updatedAttachment
        )
    }

    private static func getId(for attachment: Attachment) -> String {
        let encoded = encodeAttachment(attachment)
        let components = encoded.split(separator: ":")
        if components.count > 1 {
            return String(components[1].prefix(64))
        } else {
            return ""
        }
    }

    public static func encodeAttachment(
        _ attachment: Attachment,
        hashAlgorithm: String = "sha-256",
        baseName: String = "base58btc"
    ) -> String {
        let data = attachment.data

        if let sha256 = data.sha256 {
            return "hl:\(sha256)"
        }

        if let base64 = data.base64 {
            let bytes = TypedArrayEncoder.fromBase64(base64)
            return HashlinkEncoder.encode(bytes: bytes, hashAlgorithm: hashAlgorithm, baseName: baseName)
        }

        if data.json != nil {
            fatalError("Attachment (\(attachment.id)) has JSON encoded data. This is currently not supported")
        }

        fatalError("Attachment (\(attachment.id)) has no data to create a link with")
    }

    public static func isLinkedAttachment(_ attachment: Attachment) -> Bool {
        return HashlinkEncoder.isValid(hashlink: "hl:\(attachment.id)")
    }
}
