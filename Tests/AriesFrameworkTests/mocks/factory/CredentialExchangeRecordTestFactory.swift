//
//  CredentialExchangeRecordTestFactory.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework
import Foundation

enum CredentialExchangeRecordTestFactory {

    static func empty() -> CredentialExchangeRecord {
        CredentialExchangeRecordBuilder()
            .setId(UUID().uuidString)
            .setProtocolVersion("2.0")
            .setState(.ProposalSent)
            .setRole(.holder)
            .build()
    }
}
