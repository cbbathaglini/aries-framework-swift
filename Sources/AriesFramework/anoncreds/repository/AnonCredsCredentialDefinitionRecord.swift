//
//  AnonCredsCredentialDefinitionRecord.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import AnyCodable

public class AnonCredsCredentialDefinitionRecord: BaseRecord, Codable {
    public static let type = "AnonCredsCredentialDefinitionRecord"

    public var id: String
    public var tags: Tags?
    public var metadata: [String: AnyCodable] = [:]

    public var createdAt: Date
    public var updatedAt: Date?

    public var credentialDefinitionId: String
    public var credentialDefinition: AnonCredsCredentialDefinition
    public var methodName: String

   enum CodingKeys: String, CodingKey {
       case id, tags, createdAt, updatedAt
       case credentialDefinitionId, credentialDefinition, methodName
   }

    init(
       id: String,
       tags: Tags? = nil,
       createdAt: Date,
       updatedAt: Date? = nil,
       credentialDefinitionId: String,
       credentialDefinition: AnonCredsCredentialDefinition,
       methodName: String
   ) {
       self.id = id
       self.tags = tags
       self.createdAt = createdAt
       self.updatedAt = updatedAt
       self.credentialDefinitionId = credentialDefinitionId
       self.credentialDefinition = credentialDefinition
       self.methodName = methodName
   }

    public func getTags() -> Tags {
        var tagMap = tags ?? [:]

        var unqualifiedId: String = ""
        if IndyIdentifiers.isDidIndyCredentialDefinitionId(credentialDefinitionId) {
            do {
                let (namespaceIdentifier, schemaSeqNo, tag) = try IndyIdentifiers.parseIndyCredentialDefinitionId(credentialDefinitionId)
                unqualifiedId = IndyIdentifiers.getUnqualifiedCredentialDefinitionId(
                    unqualifiedDid: namespaceIdentifier,
                    schemaSeqNo: schemaSeqNo,
                    tag: tag
                )
            } catch {
                print("Error analyzing credentialDefinitionId: \(error)")
            }
        }

        tagMap["credentialDefinitionId"] = credentialDefinitionId
        tagMap["schemaId"] = credentialDefinition.schemaId
        tagMap["issuerId"] = credentialDefinition.issuerId
        tagMap["tag"] = credentialDefinition.tag
        tagMap["methodName"] = methodName
        tagMap["unqualifiedCredentialDefinitionId"] = unqualifiedId

        return tagMap
    }
}
