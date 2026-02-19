//
//  CreateProposalOptionsV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation
import AnyCodable

public struct CreateProposalOptionsV2 : Codable{
    let connection: ConnectionRecord
    let autoAcceptCredential: AutoAcceptCredential?
    let credentialRecord: CredentialExchangeRecord
    let credentialFormats: [String: AnyCodable]
    let proposalAttachments: [Attachment]
    let comment: String?
    let goal: String?
    let goalCode: String?
    let credentialPreview: CredentialPreviewV2?
    let protocolVersion: String
    let credentialDefinitionId: String?
    let issuerDid: String?
    let threadId: String
    let parentThreadId: String?
}
