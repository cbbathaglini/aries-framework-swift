//
//  W3cCredentialRecord.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation
import AnyCodable

public class W3cCredentialRecord: BaseRecord, Codable {
    public static  let type = "W3cCredentialRecord"

    public var id: String
    public var tags: Tags?
    public var createdAt: Date
    public var updatedAt: Date?
    public var metadata: [String: AnyCodable] = [:]
    
    public var credential: W3cCredential

    enum CodingKeys: String, CodingKey {
        case id, tags = "_tags", createdAt, updatedAt, metadata
        case credential
    }
    
    init(
        id: String = RecordUtils.generateId(),
        tags: Tags?,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        credential: W3cCredential
    ) {
        self.credential = credential
        self.id = RecordUtils.generateId()
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.credential = credential
        self.tags = tags ?? [:]
    }


    func getTagsW3cJsonLd() -> Tags {
        var tags = self.tags ?? [:]
        tags["issuerId"] = String(describing: credential.issuer)
        tags["subjectIds"] = credential.credentialSubject.description
        tags["givenId"] = credential.id
        tags["types"] = credential.type.joined(separator: ",")
        return tags
    }

    public func getTags() -> Tags {
        var t = (tags ?? [:])

        let subjectIds: [String] = credential.credentialSubject
            .compactMap { $0.id?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let first = subjectIds.first {
            t["subjectId"] = first
            t["subjectIds"] = Array(Set(subjectIds)).joined(separator: ",") // distinct
        } else {
            t["subjectId"] = ""
            t["subjectIds"] = ""
        }

        if let given = credential.id, !given.isEmpty {
            t["givenId"] = given
        }

        t["issuerId"] = String(describing: credential.issuer)
        t["types"] = credential.type.joined(separator: ",")

        for sid in Array(Set(subjectIds)) {
            t["subjectId:\(sid)"] = "1"
        }

        self.tags = t
        return t
    }

    func getTagsAux() -> Tags {
        return tags ?? [:]
    }

    var description: String {
        return "W3cCredentialRecord(id: '\(id)', _tags: \(tags ?? [:]), createdAt: \(createdAt), updatedAt: \(updatedAt?.description ?? "nil"), credential: \(credential))"
    }
    
    public func toMap() -> [String: Any?] {
        // @TODO
        return [
            "recordId": self.id,
            "credentialId": self.credential.id,
            "attributes": [String: String](), // TODO
            "createdAt": String.fromDate(self.createdAt),
            "updatedAt": String.fromDate(self.updatedAt),
            "revocationId": nil, // TODO
            "linkSecretId": "", // TODO
            "credential": self.credential,
//            "schemaId": self.credential.credentialSchema?.first?.id ?? "", // TODO
            "schemaName": "", // TODO
            "schemaVersion": "", // TODO
            "schemaIssuerId": "", // TODO
            "issuerId": "", // TODO
            "definitionId": "", // TODO
            "revocationRegistryId": nil, // TODO
            "revocationNotification": nil // TODO
        ]
    }
}
