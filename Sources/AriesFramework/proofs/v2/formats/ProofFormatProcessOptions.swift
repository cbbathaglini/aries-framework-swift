//
//  ProofFormatProcessOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/10/25.
//

import Foundation

public struct ProofFormatProcessOptions {
    public let attachment: Attachment
    public var proofRecord: ProofExchangeRecord

    public init(attachment: Attachment, proofRecord: ProofExchangeRecord) {
        self.attachment = attachment
        self.proofRecord = proofRecord
    }
}
