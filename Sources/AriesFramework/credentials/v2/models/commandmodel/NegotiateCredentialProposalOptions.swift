//
//  NegotiateCredentialProposalOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

public struct NegotiateCredentialProposalOptions {
    let credentialExchangeRecord: CredentialExchangeRecord
    let credentialFormats: [String: Any]
    let autoAcceptCredential: AutoAcceptCredential?
    let comment: String?
    let goalCode: String?
    let goal: String?
}
