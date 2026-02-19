//
//  AcceptOfferParams.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public struct AcceptOfferParams {
    let credentialRecord: CredentialExchangeRecord
    let formatServices: [any CredentialFormatService]
    let comment: String?
    let goal: String?
    let goalCode: String?
    let credentialFormats: [Format]?

    init(
        credentialRecord: CredentialExchangeRecord,
        formatServices: [any CredentialFormatService],
        comment: String? = nil,
        goal: String? = nil,
        goalCode: String? = nil,
        credentialFormats: [Format]? = []
    ) {
        self.credentialRecord = credentialRecord
        self.formatServices = formatServices
        self.comment = comment
        self.goal = goal
        self.goalCode = goalCode
        self.credentialFormats = credentialFormats
    }
}
