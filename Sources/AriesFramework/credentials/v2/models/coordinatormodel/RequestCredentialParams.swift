//
//  RequestCredentialParams.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public struct RequestCredentialParams {
    let credentialFormats: [Format]
    let formatServices: [any CredentialFormatService]
    let credentialRecord: CredentialExchangeRecord
    let comment: String?
    let goalCode: String?
    let goal: String?

    init(
        credentialFormats: [Format],
        formatServices: [any CredentialFormatService],
        credentialRecord: CredentialExchangeRecord,
        comment: String? = nil,
        goalCode: String? = nil,
        goal: String? = nil
    ) {
        self.credentialFormats = credentialFormats
        self.formatServices = formatServices
        self.credentialRecord = credentialRecord
        self.comment = comment
        self.goalCode = goalCode
        self.goal = goal
    }
}
