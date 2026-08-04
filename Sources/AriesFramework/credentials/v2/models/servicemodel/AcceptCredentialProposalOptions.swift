//
//  AcceptCredentialProposalOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

public struct AcceptCredentialProposalOptions {
    let credentialExchangeRecord: CredentialExchangeRecord
    let credentialFormats: [String: Any]?
    let autoAcceptCredential: AutoAcceptCredential?
    let comment: String?
    let goal: String?
    let goalCode: String?

    init(
        credentialExchangeRecord: CredentialExchangeRecord,
        credentialFormats: [String: Any]? = [:],
        autoAcceptCredential: AutoAcceptCredential? = nil,
        comment: String? = nil,
        goal: String? = nil,
        goalCode: String? = nil
    ) {
        self.credentialExchangeRecord = credentialExchangeRecord
        self.credentialFormats = credentialFormats
        self.autoAcceptCredential = autoAcceptCredential
        self.comment = comment
        self.goal = goal
        self.goalCode = goalCode
    }
}
