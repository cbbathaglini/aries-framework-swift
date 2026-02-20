//
//  MockConnectionRecord.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//
@testable import AriesFramework

enum ConnectionRecordTestFactory {

    static func readyConnection(
        state: ConnectionState = .Complete
    ) -> ConnectionRecord {
        return makeConnection(state: state)
    }

    static func notReadyConnection(
        state: ConnectionState = .Invited
    ) -> ConnectionRecord {
        return makeConnection(state: state)
    }

    private static func makeConnection(
        state: ConnectionState
    ) -> ConnectionRecord {
        return ConnectionRecord(
            state: state,
            role: .Invitee,
            didDoc: DidDocTestFactory.minimal(),
            did: "did:test:123",
            verkey: "verkey",
            multiUseInvitation: false
        )
    }
}


