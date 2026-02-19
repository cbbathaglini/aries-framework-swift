//
//  ProcessCredentialParams.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public struct ProcessCredentialParams {
    let credentialExchangeRecord: CredentialExchangeRecord
    let formatService: [any CredentialFormatService]
    let requestCredentialMessageV2: RequestCredentialMessageV2
    let message: IssueCredentialMessageV2

    init(
        credentialExchangeRecord: CredentialExchangeRecord,
        formatService: [any CredentialFormatService],
        requestCredentialMessageV2: RequestCredentialMessageV2,
        message: IssueCredentialMessageV2
    ) {
        self.credentialExchangeRecord = credentialExchangeRecord
        self.formatService = formatService
        self.requestCredentialMessageV2 = requestCredentialMessageV2
        self.message = message
    }
}
