//
//  AnonCredsProposeCredentialFormat.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

public struct AnonCredsProposeCredentialFormat: Codable {
    public var schemaIssuerId: String?
    public var schemaId: String?
    public var schemaName: String?
    public var schemaVersion: String?

    public var credentialDefinitionId: String?
    public var issuerId: String?

    public var attributes: [CredentialPreviewAttribute]?
    public var linkedAttachments: [LinkedAttachment]?

    public var schemaIssuerDid: String?
    public var issuerDid: String?

    enum CodingKeys: String, CodingKey {
        case schemaIssuerId
        case schemaId
        case schemaName
        case schemaVersion
        case credentialDefinitionId
        case issuerId
        case attributes
        case linkedAttachments
        case schemaIssuerDid
        case issuerDid
    }
}
