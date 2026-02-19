//
//  ProofUtils.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation
import AnyCodable
import anoncreds_uniffi
import os.log

public struct ProofUtils {
    let logger = Logger(subsystem: "AriesFramework", category: "ProofUtils")
    
    static func getSchemas(agent: Agent, schemaIds: Set<String>) async throws -> [String: AnonCredsSchema] {
        var schemas: [String: AnonCredsSchema] = [:]

        try await withThrowingTaskGroup(of: (String, AnonCredsSchema).self) { group in
            for schemaId in schemaIds {
                group.addTask {
                    let schema = try await agent.ledgerService.getSchemaObj(schemaId: schemaId)
                    return (schemaId, schema)
                }
            }

            for try await (schemaId, schema) in group {
                schemas[schemaId] = schema
            }
        }

        return schemas
    }

    static func getSchemasUniffi(agent: Agent, schemaIds: Set<String>) async throws -> [String: Schema] {
        var schemas: [String: Schema] = [:]

        try await withThrowingTaskGroup(of: (String, Schema).self) { group in
            for schemaId in schemaIds {
                group.addTask {
                    let (schema, _) = try await agent.ledgerService.getSchema(schemaId: schemaId)
                    return (schemaId, try Schema(json: schema))
                }
            }

            for try await (schemaId, schema) in group {
                schemas[schemaId] = schema
            }
        }

        return schemas
    }

    static func getCredentialDefinitionsUniffi(
        agent: Agent,
        credentialDefinitionIds: Set<String>
    ) async throws -> [String: CredentialDefinition] {
        var credentialDefs: [String: CredentialDefinition] = [:]

        try await withThrowingTaskGroup(of: (String, CredentialDefinition).self) { group in
            for credDefId in credentialDefinitionIds {
                group.addTask {
                    let credDef = try await agent.ledgerService.getCredentialDefinition(id: credDefId)
                    return (credDefId, try CredentialDefinition(json: credDef))
                }
            }

            for try await (credDefId, credDef) in group {
                credentialDefs[credDefId] = credDef
            }
        }

        return credentialDefs
    }
    
    public static func getCredentialDefinitions(agent: Agent, credentialDefinitionIds: Set<String>) async throws -> [String: AnonCredsCredentialDefinition] {
        var credentialDefinitions: [String: AnonCredsCredentialDefinition] = [:]

        try await withThrowingTaskGroup(of: (String, AnonCredsCredentialDefinition).self) { group in
            for id in credentialDefinitionIds {
                group.addTask {
                    let rawDefinition = try await agent.ledgerService.getCredentialDefinition(id: id)
                    let fixedJson = rawDefinition.replacingOccurrences(of: "\\\"", with: "\"")
                    let data = fixedJson.data(using: .utf8)!
                    let decoded = try JSONDecoder().decode(AnonCredsCredentialDefinition.self, from: data)

                    return (id, decoded)
                }
            }

            for try await (id, decodedDefinition) in group {
                credentialDefinitions[id] = decodedDefinition
            }
        }

        return credentialDefinitions
    }
    
    public static func checkIfMessageTypeIsCorrect(proofRecordId: String, agent: Agent) async throws {
        
        let query = #"{"associatedRecordId": "\#(proofRecordId)"}"#
        let recordMessageType : DidCommMessageRecord = try await agent.didCommMessageRepository.getSingleByQuery(query)
        let typeTag = recordMessageType.getTags()["messageType"]
        
    
        guard typeTag!.contains("/2.0/") else {
            throw NSError(domain: "ProofError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Version of proof protocol is incorrect"
            ])
        }
    }
    
    public static func updateProofFormat(record: inout ProofExchangeRecord, formats: [ProofFormatSpec], agent: Agent) async throws {
        record.formats = formats
        try await agent.proofRepository.update(record)
    }
    
    public static func getProofFormats(proofRequest: AnonCredsProofRequest, format: String) -> [String: AnyCodable] {
        var formatContent: [String: Any] = [:]
        
        formatContent["name"] = proofRequest.name
        formatContent["version"] = proofRequest.version
        
        if let nonRevoked = proofRequest.nonRevoked {
            var nonRevokedMap: [String: UInt64] = [:]
            if let from = nonRevoked.from {
                nonRevokedMap["from"] = from
            }
            if let to = nonRevoked.to {
                nonRevokedMap["to"] = to
            }
            formatContent["non_revoked"] = nonRevokedMap
        }

        var requestedAttributes: [String: Any] = [:]
        for (key, attr) in proofRequest.requestedAttributes {
            var attrMap: [String: Any] = [:]

            if let name = attr.name {
                attrMap["name"] = name
            }
            if let names = attr.names {
                attrMap["names"] = names
            }
            if let restrictions = attr.restrictions, !restrictions.isEmpty {
                attrMap["restrictions"] = restrictions.map { restrictionToJson($0) }
            }
            if let nonRevoked = attr.nonRevoked {
                var nonRevokedMap: [String: UInt64] = [:]
                if let from = nonRevoked.from {
                    nonRevokedMap["from"] = from
                }
                if let to = nonRevoked.to {
                    nonRevokedMap["to"] = to
                }
                attrMap["non_revoked"] = nonRevokedMap
            }

            requestedAttributes[key] = attrMap
        }
        formatContent["requested_attributes"] = requestedAttributes

        var requestedPredicates: [String: Any] = [:]
        for (key, pred) in proofRequest.requestedPredicates {
            var predMap: [String: Any] = [
                "name": pred.name,
                "p_type": pred.pType,
                "p_value": pred.pValue
            ]

            if let restrictions = pred.restrictions, !restrictions.isEmpty {
                predMap["restrictions"] = restrictions.map { restrictionToJson($0) }
            }
            if let nonRevoked = pred.nonRevoked {
                var nonRevokedMap: [String: UInt64] = [:]
                if let from = nonRevoked.from {
                    nonRevokedMap["from"] = from
                }
                if let to = nonRevoked.to {
                    nonRevokedMap["to"] = to
                }
                predMap["non_revoked"] = nonRevokedMap
            }

            requestedPredicates[key] = predMap
        }
        formatContent["requested_predicates"] = requestedPredicates

        return [format: AnyCodable(formatContent)]
    }
    
    public static func restrictionToJson(_ r: AnonCredsProofRequestRestriction) -> [String: AnyCodable] {
        var json: [String: AnyCodable] = [:]
        
        if let schemaId = r.schemaId { json["schema_id"] = AnyCodable(schemaId) }
        if let schemaIssuerId = r.schemaIssuerId { json["schema_issuer_id"] = AnyCodable(schemaIssuerId) }
        if let schemaName = r.schemaName { json["schema_name"] = AnyCodable(schemaName) }
        if let schemaVersion = r.schemaVersion { json["schema_version"] = AnyCodable(schemaVersion) }
        if let issuerId = r.issuerId { json["issuer_id"] = AnyCodable(issuerId) }
        if let credDefId = r.credDefId { json["cred_def_id"] = AnyCodable(credDefId) }
        if let revRegId = r.revRegId { json["rev_reg_id"] = AnyCodable(revRegId) }
        if let schemaIssuerDid = r.schemaIssuerDid { json["schema_issuer_did"] = AnyCodable(schemaIssuerDid) }
        if let issuerDid = r.issuerDid { json["issuer_did"] = AnyCodable(issuerDid) }

        for (key, value) in r.attributeMarkers {
            json["attr::\(key)::marker"] = AnyCodable(value)
        }
        for (key, value) in r.attributeValues {
            json["attr::\(key)::value"] = AnyCodable(value)
        }

        return json
    }
    
    public static func getAttachmentForService(
        proofFormatService: any ProofFormatService,
        formats: [ProofFormatSpec],
        attachments: [Attachment]
    ) throws -> Attachment {
        let attachmentId = try getAttachmentIdForService(proofFormatService: proofFormatService, formats: formats)

        guard let attachment = attachments.first(where: { $0.id == attachmentId }) else {
            throw CredoError("Attachment with id \(attachmentId) not found in attachments.")
        }

        return attachment
    }
    
  
    private static func getAttachmentIdForService(
        proofFormatService: any ProofFormatService,
        formats: [ProofFormatSpec]
    ) throws -> String {
        guard let format = formats.first(where: { proofFormatService.supportsFormat(formatIdentifier: $0.format) }) else {
            throw CredoError("No attachment found for service \(proofFormatService.formatKey)")
        }

        guard let attachmentId = format.attachmentId else {
            throw CredoError("Attachment ID is missing for format \(format)")
        }

        return attachmentId
    }
    
    public static func getRequestedCredentialsForProofRequest(
        proofRecordId: String,
        agent: Agent,
        credentialW3cId: String? = nil
    ) async throws -> RetrievedCredentialsAnonCreds {
        
        logDebug("[init] getRequestedCredentialsForProofRequest")
        
        var record = try await agent.proofRepository.getById(proofRecordId)
    
        try await checkIfMessageTypeIsCorrect(proofRecordId: proofRecordId, agent: agent)
        
        let proofRequestMessageJson = try await agent.didCommMessageRepository.getAgentMessage(
            associatedRecordId: record.id,
            messageType: RequestPresentationMessageV2.type
        )
        logDebug("proofRequestMessageJson (RequestPresentationMessageV2): \(proofRequestMessageJson)")
       
        guard let proofRequestMessage =  MessageSerializer.decodeFromString(
            proofRequestMessageJson) as? RequestPresentationMessageV2
        else {
            throw CredoError("Unable to decode proof request message")
        }
       
        logDebug("proofRequestMessage: \(proofRequestMessage)")
        try await updateProofFormat(
            record: &record,
            formats: proofRequestMessage.formats,
            agent: agent
        )
        
        let proofRequestJson = try proofRequestMessage.anoncredsProofRequest()
        logDebug("proofRequestJson: \(proofRequestJson)")
        
        let proofRequest = try JSONDecoder().decode(
            AnonCredsProofRequest.self,
            from: Data(proofRequestJson.utf8)
        )
       logDebug("proofRequest: \(proofRequest)")
        
        return try await agent.proofServiceV2.getRequestedCredentialsForProofRequest(anoncredsProofRequest: proofRequest, credentialW3cId: credentialW3cId)
    }
    
   
}
