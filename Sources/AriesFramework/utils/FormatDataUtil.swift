//
//  FormatDataUtil.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

class FormatDataUtil {
    
    static func getFormatData<T: Encodable>(_ data: T, id: String) throws -> Attachment {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(data)
        let base64 = jsonData.base64EncodedString()
        
        return Attachment(
            id: id,
            mimetype: "application/json",
            data: AttachmentData(base64: base64)
        )
    }
    
    static func getCredentialLinkedAttachments(
        attributes: [CredentialPreviewAttribute]? = nil,
        linkedAttachments: [LinkedAttachment]? = nil
    ) throws -> CredentialLinkedAttachmentsResult {
        if linkedAttachments == nil && attributes == nil {
            return CredentialLinkedAttachmentsResult()
        }
        
        var previewAttributesResult = attributes ?? []
        var attachments: [Attachment]? = nil
        
        
        if let linked = linkedAttachments {
            do {
                previewAttributesResult = try Functions.createAndLinkAttachmentsToPreview(
                    attachments: linked,
                    previewAttributes: previewAttributesResult
                )
                attachments = linked.map { $0.attachment }
            } catch {
                throw CredoError("Erro ao vincular attachments ao preview: \(error)") 
            }
        }
        
        return CredentialLinkedAttachmentsResult(
            attachments: attachments,
            previewAttributes: previewAttributesResult
        )
    }


    static func parseAttachmentData<T: Decodable>(_ attachment: Attachment, as type: T.Type) throws -> T {
        let jsonString = try attachment.getDataAsJson()
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw CredoError("Erro ao converter string JSON para Data")
        }

        let decodedObject = try JSONDecoder().decode(T.self, from: jsonData)
        return decodedObject
    }

    static func fetchSchema(agent: Agent, schemaId: String) async throws -> FetchSchemaReturn {
        let registry = try await agent.anonCredsRegistryService.getRegistryForIdentifier(for: schemaId)
        let result = try await registry.getSchema(agent: agent, schemaId: schemaId)

        guard let schema = result.schema else {
            throw CredoError("Schema not found for id \(schemaId): \(result.resolutionMetadata?.message ?? "unknown error")")
        }

        return FetchSchemaReturn(
            schema: schema,
            schemaId: result.schemaId,
            indyNamespace: result.schemaMetadata["didIndyNamespace"]?.value as? String
        )
    }

    static func assertPreviewAttributesMatchSchemaAttributes(agent: Agent, offer: AnonCredsCredentialOffer, attributes: [CredentialPreviewAttribute]) async throws {
        let result = try await fetchSchema(agent: agent, schemaId: offer.schemaId)
        try assertAttributesMatch(schema: result.schema, attributes: attributes)
    }

    static func assertAttributesMatch(schema: AnonCredsSchema, attributes: [CredentialPreviewAttribute]) throws {
        let schemaAttributes = Set(schema.attrNames)
        let credentialAttributes = Set(attributes.map { $0.name })

        let difference = schemaAttributes.symmetricDifference(credentialAttributes)

        if !difference.isEmpty {
            let diffStr = difference.joined(separator: ", ")
            throw CredoError("Mismatch in attributes. Difference: \(diffStr). Expected: \(schema.attrNames)")
        }
    }
}
