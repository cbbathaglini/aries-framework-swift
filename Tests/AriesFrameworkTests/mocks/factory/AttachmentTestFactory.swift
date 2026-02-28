//
//  AttachmentTestFactory.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework
import Foundation

enum AttachmentTestFactory {

    // MARK: - Defaults

    static let defaultAttachmentId = "test-attachment-id"

    // MARK: - JSON Attachments

    static func json(
            id: String = defaultAttachmentId,
            jsonObject: Any = ["test": true],
            mimeType: String = "application/json"
        ) -> Attachment {

            let jsonString = JsonTestEncoder.encode(jsonObject)

            return Attachment(
                id: id,
                desc: "Test JSON attachment",
                filename: nil,
                mimetype: mimeType,
                lastModified: Date(),
                byteCount: jsonString.count,
                data: AttachmentData(json: jsonString)
            )
        }
    
    static func json(
        id: String = defaultAttachmentId,
        jsonString: String,
        mimeType: String = "application/json"
    ) -> Attachment {

        return Attachment(
            id: id,
            desc: "Test JSON attachment",
            filename: nil,
            mimetype: mimeType,
            lastModified: Date(),
            byteCount: jsonString.count,
            data: AttachmentData(json: jsonString)
        )
    }

    // MARK: - Base64 Attachments

    static func base64(
        id: String = defaultAttachmentId,
        data: Data,
        mimeType: String = "application/json"
    ) -> Attachment {

        return Attachment(
            id: id,
            desc: "Test Base64 attachment",
            filename: nil,
            mimetype: mimeType,
            lastModified: Date(),
            byteCount: data.count,
            data: AttachmentData(base64: data.base64EncodedString())
        )
    }

    // MARK: - AnonCreds Request Attachment

    static func anoncredsRequest(
        id: String = defaultAttachmentId
    ) -> Attachment {

        let payload: [String: Any] = [
            "prover_did": "did:example:prover",
            "cred_def_id": "creddef:example",
            "nonce": "123456"
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: payload)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        return Attachment(
            id: id,
            desc: "Anoncreds credential request",
            filename: nil,
            mimetype: "application/json",
            lastModified: Date(),
            byteCount: jsonData.count,
            data: AttachmentData(json: jsonString)
        )
    }
    
    static func decodeFromAttachment<T: Decodable>(
        _ type: T.Type,
        attachment: Attachment,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {
        
        if let json = attachment.data.json {
            guard let data = json.data(using: .utf8) else {
                throw CredoError("Attachment json is not valid UTF-8")
            }
            return try decoder.decode(T.self, from: data)
        }

        if let base64 = attachment.data.base64 {
            guard let data = Data(base64Encoded: base64) else {
                throw CredoError("Attachment base64 is invalid")
            }
            return try decoder.decode(T.self, from: data)
        }

        if attachment.data.links != nil {
            throw CredoError("Attachment links not supported in tests decodeFromAttachment")
        }

        throw CredoError("Attachment has no decodable data (json/base64)")
    }

    // MARK: - Dummy / Minimal

    static func empty(
        id: String = defaultAttachmentId
    ) -> Attachment {

        return Attachment(
            id: id,
            desc: "Empty attachment",
            filename: nil,
            mimetype: "application/json",
            lastModified: nil,
            byteCount: nil,
            data: AttachmentData(json: "{}")
        )
    }
}
