//
//  ProcessOfferParams.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public struct ProcessOfferParams : CustomStringConvertible{
    let credentialExchangeRecord: CredentialExchangeRecord
    let message: OfferCredentialMessageV2
    let formatService: [any CredentialFormatService]

    init(
        credentialExchangeRecord: CredentialExchangeRecord,
        message: OfferCredentialMessageV2,
        formatService: [any CredentialFormatService]
    ) {
        self.credentialExchangeRecord = credentialExchangeRecord
        self.message = message
        self.formatService = formatService
    }
    
    public var description: String {
        return "ProcessOfferParams(credentialExchangeRecordId: \(credentialExchangeRecord.id), formatServiceCount: \(formatService.count), messageId: \(message.id))"
    }
}
