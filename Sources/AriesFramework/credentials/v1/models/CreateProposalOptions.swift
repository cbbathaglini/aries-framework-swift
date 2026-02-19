//
//  CreateProposalOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/25.
//
import Foundation

public struct CreateProposalOptions {
    public var connection: ConnectionRecord
    public var credentialPreview: CredentialPreview?
    public var schemaIssuerDid: String?
    public var schemaId: String?
    public var schemaName: String?
    public var schemaVersion: String?
    public var credentialDefinitionId: String?
    public var issuerDid: String?
    public var autoAcceptCredential: AutoAcceptCredential?
    public var comment: String?

    public init(connection: ConnectionRecord, credentialPreview: CredentialPreview? = nil, schemaIssuerDid: String? = nil, schemaId: String? = nil, schemaName: String? = nil, schemaVersion: String? = nil, credentialDefinitionId: String? = nil, issuerDid: String? = nil, autoAcceptCredential: AutoAcceptCredential? = nil, comment: String? = nil) {
        self.connection = connection
        self.credentialPreview = credentialPreview
        self.schemaIssuerDid = schemaIssuerDid
        self.schemaId = schemaId
        self.schemaName = schemaName
        self.schemaVersion = schemaVersion
        self.credentialDefinitionId = credentialDefinitionId
        self.issuerDid = issuerDid
        self.autoAcceptCredential = autoAcceptCredential
        self.comment = comment
    }
}
