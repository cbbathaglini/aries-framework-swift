//
//  NegotiateCredentialOfferOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation
import AnyCodable

public struct NegotiateCredentialOfferOptions : Codable {
    public let credentialExchangeRecord: CredentialExchangeRecord
    public let credentialFormat: [String: AnyCodable]
    public let autoAcceptCredential: AutoAcceptCredential
    public let comment: String?
    public let goal: String?
    public let goalCode: String?

    public init(
        credentialExchangeRecord: CredentialExchangeRecord,
        credentialFormat: [String: AnyCodable],
        autoAcceptCredential: AutoAcceptCredential,
        comment: String? = nil,
        goal: String? = nil,
        goalCode: String? = nil
    ) {
        self.credentialExchangeRecord = credentialExchangeRecord
        self.credentialFormat = credentialFormat
        self.autoAcceptCredential = autoAcceptCredential
        self.comment = comment
        self.goal = goal
        self.goalCode = goalCode
    }
}
