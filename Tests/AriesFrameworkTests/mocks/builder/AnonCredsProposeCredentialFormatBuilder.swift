//
//  AnonCredsProposeCredentialFormatBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework

final class AnonCredsProposeCredentialFormatBuilder {

    private var schemaIssuerId: String? = "did:example:issuer"
    private var schemaId: String? = "schema:test:1"
    private var schemaName: String? = "TestSchema"
    private var schemaVersion: String? = "1.0"

    private var credentialDefinitionId: String? = "creddef:test"
    private var issuerId: String? = "issuer:test"

    private var attributes: [CredentialPreviewAttribute]? = []
    private var linkedAttachments: [LinkedAttachment]? = []

    private var schemaIssuerDid: String? = "did:example:schema-issuer"
    private var issuerDid: String? = "did:example:issuer"

    // MARK: - Fluent setters

    func withSchemaIssuerId(_ value: String?) -> Self {
        self.schemaIssuerId = value
        return self
    }

    func withSchemaId(_ value: String?) -> Self {
        self.schemaId = value
        return self
    }

    func withSchemaName(_ value: String?) -> Self {
        self.schemaName = value
        return self
    }

    func withSchemaVersion(_ value: String?) -> Self {
        self.schemaVersion = value
        return self
    }

    func withCredentialDefinitionId(_ value: String?) -> Self {
        self.credentialDefinitionId = value
        return self
    }

    func withIssuerId(_ value: String?) -> Self {
        self.issuerId = value
        return self
    }

    func withSchemaIssuerDid(_ value: String?) -> Self {
        self.schemaIssuerDid = value
        return self
    }

    func withIssuerDid(_ value: String?) -> Self {
        self.issuerDid = value
        return self
    }

    func withAttribute(
        name: String,
        value: String,
        mimeType: String? = "text/plain"
    ) -> Self {
        let attribute = CredentialPreviewAttribute(
            name: name,
            mimeType: mimeType ?? "application/json",
            value: value
        )

        if attributes == nil {
            attributes = []
        }
        attributes?.append(attribute)
        return self
    }

    func withLinkedAttachment(_ attachment: LinkedAttachment) -> Self {
        if linkedAttachments == nil {
            linkedAttachments = []
        }
        linkedAttachments?.append(attachment)
        return self
    }

    // MARK: - Build

    func build() -> AnonCredsProposeCredentialFormat {
        AnonCredsProposeCredentialFormat(
            schemaIssuerId: schemaIssuerId,
            schemaId: schemaId,
            schemaName: schemaName,
            schemaVersion: schemaVersion,
            credentialDefinitionId: credentialDefinitionId,
            issuerId: issuerId,
            attributes: attributes,
            linkedAttachments: linkedAttachments,
            schemaIssuerDid: schemaIssuerDid,
            issuerDid: issuerDid
        )
    }
}
