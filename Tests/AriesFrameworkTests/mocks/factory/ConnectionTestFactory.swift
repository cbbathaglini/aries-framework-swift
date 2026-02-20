//
//  ConnectionTestFactory.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework

enum ConnectionTestFactory {

    static func minimal() -> Connection {
        Connection(
            did: "did:test:123",
            didDoc: DidDocTestFactory.minimal()
        )
    }
}
