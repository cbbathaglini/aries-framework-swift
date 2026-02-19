//
//  CreateAnoncredsOffer.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

struct CreateAnoncredsOffer: Codable {
    let credentialExchangeRecord: CredentialExchangeRecord
    let attachmentId: String?
    let attributes: [CredentialPreviewAttribute]
    let credentialDefinitionId: String
    let revocationRegistryDefinitionId: String?
    let revocationRegistryIndex: Int64?
    let linkedAttachments: [LinkedAttachment]?
}
