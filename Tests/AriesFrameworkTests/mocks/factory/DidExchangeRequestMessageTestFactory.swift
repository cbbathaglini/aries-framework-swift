//
//  DidExchangeRequestMessageTestFactory.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//
import Foundation
@testable import AriesFramework

enum DidExchangeRequestMessageTestFactory {

    static func minimal(
        id: String = UUID().uuidString,
        label: String = "test",
        did: String = "did:test:123"
    ) -> DidExchangeRequestMessage {
        DidExchangeRequestMessage(
            id: id,
            label: label,
            did: did
        )
    }
}
