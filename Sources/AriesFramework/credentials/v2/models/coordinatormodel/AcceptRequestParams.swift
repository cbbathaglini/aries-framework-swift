//
//  AcceptRequestParams.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public struct AcceptRequestParams {
    let credentialExchangeRecord: CredentialExchangeRecord
    let formatService: [any CredentialFormatService]
    let comment: String?
    let goal: String?
    let goalCode: String?
    let credentialFormat: [String: Any]?

    init(
        credentialExchangeRecord: CredentialExchangeRecord,
        formatService: [any CredentialFormatService],
        comment: String? = nil,
        goal: String? = nil,
        goalCode: String? = nil,
        credentialFormat: [String: Any]? = nil
    ) {
        self.credentialExchangeRecord = credentialExchangeRecord
        self.formatService = formatService
        self.comment = comment
        self.goal = goal
        self.goalCode = goalCode
        self.credentialFormat = credentialFormat
    }
}
