//
//  ProcessRequestParams.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public struct ProcessRequestParams {
    let credentialExchangeRecord: CredentialExchangeRecord
    let message: RequestCredentialMessageV2
    let formatService: [any CredentialFormatService]

    init(
        credentialExchangeRecord: CredentialExchangeRecord,
        message: RequestCredentialMessageV2,
        formatService: [any CredentialFormatService]
    ) {
        self.credentialExchangeRecord = credentialExchangeRecord
        self.message = message
        self.formatService = formatService
    }
}
