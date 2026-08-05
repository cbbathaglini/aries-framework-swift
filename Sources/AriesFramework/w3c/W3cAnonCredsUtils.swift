//
//  W3cAnonCredsUtils.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation
import AnyCodable

class W3cAnonCredsUtils {
    static func getW3cRecordAnonCredsTags(
        credentialSubject: W3cCredentialSubject,
        issuerId: String,
        schemaId: String,
        schema: AnonCredsSchema,
        credentialDefinitionId: String,
        revocationRegistryId: String? = nil,
        credentialRevocationId: String? = nil,
        linkSecretId: String,
        methodName: String
    ) throws -> Tags {
        var tags: [String: Any?] = [
            "anonCredsLinkSecretId": linkSecretId,
            "anonCredsCredentialDefinitionId": credentialDefinitionId,
            "anonCredsSchemaId": schemaId,
            "anonCredsSchemaName": schema.name,
            "anonCredsSchemaIssuerId": schema.issuerId,
            "anonCredsSchemaVersion": schema.version,
            "anonCredsMethodName": methodName,
            "anonCredsRevocationRegistryId": revocationRegistryId,
            "anonCredsCredentialRevocationId": credentialRevocationId
        ]

        if IndyIdentifiers.isIndyDid(issuerId) || IndyIdentifiers.isUnqualifiedIndyDid(issuerId) {
            tags.merge([
                "anonCredsUnqualifiedIssuerId": try IndyIdentifiers.getUnqualifiedDidIndyDid(identifier: issuerId),
                "anonCredsUnqualifiedCredentialDefinitionId": try IndyIdentifiers.getUnqualifiedDidIndyDid(identifier: credentialDefinitionId),
                "anonCredsUnqualifiedSchemaId": try IndyIdentifiers.getUnqualifiedDidIndyDid(identifier: schemaId),
                "anonCredsUnqualifiedSchemaIssuerId": try IndyIdentifiers.getUnqualifiedDidIndyDid(identifier: schema.issuerId),
                "anonCredsUnqualifiedRevocationRegistryId": try revocationRegistryId.flatMap { try IndyIdentifiers.getUnqualifiedDidIndyDid(identifier: $0) }
            ]) { (_, new) in new }
        }

        if let claims = credentialSubject.claims {
            for (key, anyCodableValue) in claims {
                let value = anyCodableValue.value

                if let stringValue = value as? String {
                    tags["anonCredsAttr::\(key)::value"] = stringValue
                    tags["anonCredsAttr::\(key)::marker"] = true

                } else if let numberValue = value as? NSNumber {
                    let stringified = numberValue.stringValue
                    tags["anonCredsAttr::\(key)::value"] = stringified
                    tags["anonCredsAttr::\(key)::marker"] = true

                } else {
                    print("⚠️ Key: \(key), value is neither String nor Number → \(String(describing: value))")
                }
            }
        }
        
        return convertToTags(map: tags)
    }

    private static func convertToTags(map: [String: Any?]) -> Tags {
        return map.compactMapValues { $0 as? String }
    }

    static func anonCredsCredentialInfoFromW3cRecord(
        w3cCredentialRecord: W3cCredentialRecord,
        useUnqualifiedIdentifiers: Bool?
    ) throws -> AnonCredsCredentialInfo {
        let w3c = w3cCredentialRecord.credential

        let w3cCredential = W3cJsonLdVerifiableCredential(
            context: w3c.context,
            id: w3c.id,
            type: w3c.type,
            issuer: w3c.issuer,
            issuanceDate: w3c.issuanceDate,
            credentialSubject: w3c.credentialSubject,
            expirationDate: w3c.expirationDate,
            credentialSchema: w3c.credentialSchema,
            credentialStatus: w3c.credentialStatus,
            proofs: nil
        )

        guard w3cCredential.credentialSubject.count == 1 else {
            throw CredoError("Credential subject must be an object, not an array.")
        }

        guard let anonCredsTags = getAnonCredsTagsFromRecord(record: w3cCredentialRecord) else {
            throw CredoError("AnonCreds tags not found on credential record.")
        }

        guard let metadataElement = w3cCredentialRecord.metadata[MetadataKeys.w3cAnonCredsCredentialMetadataKey] else {
            throw CredoError("AnonCreds metadata not found on credential record.")
        }

    
        let metadata: W3cAnonCredsCredentialMetadata = try decodeMetadata(metadataElement, as: W3cAnonCredsCredentialMetadata.self)

        let credentialDefinitionId = useUnqualifiedIdentifiers == true ?
            (anonCredsTags.unqualifiedCredentialDefinitionId ?? anonCredsTags.credentialDefinitionId) :
            anonCredsTags.credentialDefinitionId

        let schemaId = useUnqualifiedIdentifiers == true ?
            (anonCredsTags.unqualifiedSchemaId ?? anonCredsTags.schemaId) :
            anonCredsTags.schemaId

        let revocationRegistryId = useUnqualifiedIdentifiers == true ?
            (anonCredsTags.unqualifiedRevocationRegistryId ?? anonCredsTags.revocationRegistryId) :
            anonCredsTags.revocationRegistryId

        let subject = w3cCredential.credentialSubject.first!

       
        let claimssubject: [String: String] = subject.claims?.compactMapValues {
            if let str = $0.value as? String {
                return str
            }
            return String(describing: $0.value)
        } ?? [:]

        
        return AnonCredsCredentialInfo(
            credentialId: w3cCredentialRecord.id,
            attributes: claimssubject,
            schemaId: schemaId,
            credentialDefinitionId: credentialDefinitionId,
            revocationRegistryId: revocationRegistryId,
            credentialRevocationId: metadata.credentialRevocationId,
            methodName: metadata.methodName,
            createdAt: w3cCredentialRecord.createdAt,
            updatedAt: w3cCredentialRecord.updatedAt ?? w3cCredentialRecord.createdAt,
            linkSecretId: metadata.linkSecretId
        )
    }

    static func getAnonCredsTagsFromRecord(record: W3cCredentialRecord) -> AnonCredsCredentialTags? {
        guard record.metadata[MetadataKeys.w3cAnonCredsCredentialMetadataKey] != nil else {
            return nil
        }

        guard let tags = record.getTags() as? [String: String?] else {
            return nil
        }

        let requiredKeys = [
            "anonCredsLinkSecretId",
            "anonCredsMethodName",
            "anonCredsSchemaId",
            "anonCredsSchemaName",
            "anonCredsSchemaVersion",
            "anonCredsSchemaIssuerId",
            "anonCredsCredentialDefinitionId"
        ]

        guard requiredKeys.allSatisfy({ !(tags[$0]?.isNilOrEmpty ?? true) }) else {
            return nil
        }

        return AnonCredsCredentialTags(
            linkSecretId: tags["anonCredsLinkSecretId"]!!,
            credentialRevocationId: tags["anonCredsCredentialRevocationId"] ?? nil,
            methodName: tags["anonCredsMethodName"]!!,
            schemaName: tags["anonCredsSchemaName"]!!,
            schemaVersion: tags["anonCredsSchemaVersion"]!!,
            schemaId: tags["anonCredsSchemaId"]!!,
            schemaIssuerId: tags["anonCredsSchemaIssuerId"]!!,
            credentialDefinitionId: tags["anonCredsCredentialDefinitionId"]!!,
            revocationRegistryId: tags["anonCredsRevocationRegistryId"] ?? nil,
            unqualifiedIssuerId: tags["anonCredsUnqualifiedIssuerId"] ?? nil,
            unqualifiedSchemaId: tags["anonCredsUnqualifiedSchemaId"] ?? nil,
            unqualifiedSchemaIssuerId: tags["anonCredsUnqualifiedSchemaIssuerId"] ?? nil,
            unqualifiedCredentialDefinitionId: tags["anonCredsUnqualifiedCredentialDefinitionId"] ?? nil,
            unqualifiedRevocationRegistryId: tags["anonCredsUnqualifiedRevocationRegistryId"] ?? nil,
            dynamicAttributes: tags.filter { $0.key.hasPrefix("anonCredsAttr::") }.compactMapValues { $0 }
        )
    }

    static func anonCredsCredentialInfoFromAnonCredsRecord(
        anonCredsCredentialRecord: AnonCredsCredentialRecord
    ) -> AnonCredsCredentialInfo {
        var attributes = [String: String]()
        for (attribute, valueWrapper) in anonCredsCredentialRecord.credential.values {
            attributes[attribute] = valueWrapper.raw
        }

        return AnonCredsCredentialInfo(
            credentialId: anonCredsCredentialRecord.id,
            attributes: attributes,
            schemaId: anonCredsCredentialRecord.credential.schemaId,
            credentialDefinitionId: anonCredsCredentialRecord.credential.credDefId,
            revocationRegistryId: anonCredsCredentialRecord.credential.revRegId,
            credentialRevocationId: anonCredsCredentialRecord.credentialRevocationId,
            methodName: anonCredsCredentialRecord.methodName,
            createdAt: anonCredsCredentialRecord.createdAt,
            updatedAt: anonCredsCredentialRecord.updatedAt ?? anonCredsCredentialRecord.createdAt,
            linkSecretId: anonCredsCredentialRecord.linkSecretId
        )
    }
}

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}
