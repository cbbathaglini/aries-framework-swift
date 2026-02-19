//
//  CreateCredentialParams.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public struct CreateCredentialParams {
    let credentialRecord: CredentialExchangeRecord
    let formatServices: [any CredentialFormatService]
    let comment: String?
    let goal: String?
    let goalCode: String?
    let credentialFormats: [String: Any]

    init(
        credentialRecord: CredentialExchangeRecord,
        formatServices: [any CredentialFormatService],
        comment: String? = nil,
        goal: String? = nil,
        goalCode: String? = nil,
        credentialFormats: [String: Any] = [:]
    ) {
        self.credentialRecord = credentialRecord
        self.formatServices = formatServices
        self.comment = comment
        self.goal = goal
        self.goalCode = goalCode
        self.credentialFormats = credentialFormats
    }
}
