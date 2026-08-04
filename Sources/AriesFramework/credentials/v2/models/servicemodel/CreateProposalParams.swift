//
//  CreateProposalParams.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 23/09/25.
//

import Foundation
import AnyCodable
public struct CreateProposalParams{
    let credentialFormats: [String: AnyCodable]
    let formatServices: [any CredentialFormatService]
    let credentialRecord: CredentialExchangeRecord
    let comment: String?
    let goalCode: String?
    let goal: String?
}
