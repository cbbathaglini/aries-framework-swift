//
//  CreateCredentialProblemReportOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

public struct CreateCredentialProblemReportOptions: Codable {
    public let credentialExchangeRecord: CredentialExchangeRecord
    public let description: String

    init(
        credentialExchangeRecord: CredentialExchangeRecord,
        description: String
    ) {
        self.credentialExchangeRecord = credentialExchangeRecord
        self.description = description
    }
}
