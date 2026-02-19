//
//  CreateOfferOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/25.
//

import Foundation

public struct CreateOfferOptions {
    public var connection: ConnectionRecord?
    public var credentialDefinitionId: String
    public var attributes: [CredentialPreviewAttribute]
    public var autoAcceptCredential: AutoAcceptCredential?
    public var comment: String?

    public init(connection: ConnectionRecord? = nil, credentialDefinitionId: String, attributes: [CredentialPreviewAttribute], autoAcceptCredential: AutoAcceptCredential? = nil, comment: String? = nil) {
        self.connection = connection
        self.credentialDefinitionId = credentialDefinitionId
        self.attributes = attributes
        self.autoAcceptCredential = autoAcceptCredential
        self.comment = comment
    }
}
