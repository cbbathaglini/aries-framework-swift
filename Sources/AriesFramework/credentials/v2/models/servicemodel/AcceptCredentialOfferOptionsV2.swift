//
//  AcceptCredentialOfferOptionsV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

public struct AcceptCredentialOfferOptionsV2 {
    public let credentialExchangeRecord: CredentialExchangeRecord
    public let autoAcceptCredential: AutoAcceptCredential?
    public let comment: String?
    public let goal: String?
    public let goalCode: String?
    public let credentialFormats: [Format]?

    public init(
        credentialExchangeRecord: CredentialExchangeRecord,
        autoAcceptCredential: AutoAcceptCredential? = nil,
        comment: String? = nil,
        goal: String? = nil,
        goalCode: String? = nil,
        credentialFormats: [Format]? = []
    ) {
        self.credentialExchangeRecord = credentialExchangeRecord
        self.autoAcceptCredential = autoAcceptCredential
        self.comment = comment
        self.goal = goal
        self.goalCode = goalCode
        self.credentialFormats = credentialFormats
    }
}
