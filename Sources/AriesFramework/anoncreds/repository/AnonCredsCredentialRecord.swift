//
//  AnonCredsCredentialRecord.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation
import AnyCodable

public class AnonCredsCredentialRecord: BaseRecord, Codable {
    
    public static let type = "AnonCredsCredentialRecord"
    
    public var id: String
    public var tags: Tags?
    public var metadata: [String: AnyCodable] = [:]

    public var createdAt: Date
    public var updatedAt: Date?
    
    var credentialId: String
    var credentialRevocationId: String?
    var linkSecretId: String
    var credential: AnonCredsCredential
    var methodName: String
    

      init(
        id: String,
        tags: Tags?,
        createdAt: Date,
        updatedAt: Date?,
        credentialId: String,
        credentialRevocationId: String? = nil,
        linkSecretId: String,
        credential: AnonCredsCredential,
        methodName: String
    ) {
        self.id = id
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.credentialId = credentialId
        self.credentialRevocationId = credentialRevocationId
        self.linkSecretId = linkSecretId
        self.credential = credential
        self.methodName = methodName

    }


    convenience init(
        tags: Tags? = nil,
        credentialId: String,
        credentialRevocationId: String?,
        linkSecretId: String,
        credential: AnonCredsCredential,
        methodName: String
    ) {
        let generatedId = RecordUtils.generateId()
        let now = Date()
        self.init(
            id: generatedId,
            tags: tags,
            createdAt: now,
            updatedAt: nil,
            credentialId: credentialId,
            credentialRevocationId: credentialRevocationId,
            linkSecretId: linkSecretId,
            credential: credential,
            methodName: methodName
        )
    }

    public func getTags() -> Tags {
        var dynamicTags = tags ?? [:]
        dynamicTags["credentialDefinitionId"] = credential.credDefId
        dynamicTags["schemaId"] = credential.schemaId
        dynamicTags["credentialId"] = credentialId
        dynamicTags["credentialRevocationId"] = credentialRevocationId
        dynamicTags["revocationRegistryId"] = credential.revRegId
        dynamicTags["linkSecretId"] = linkSecretId
        dynamicTags["methodName"] = methodName
        return dynamicTags
    }
}
