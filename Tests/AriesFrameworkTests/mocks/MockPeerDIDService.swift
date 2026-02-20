//
//  MockPeerDIDService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//
@testable import AriesFramework
import Foundation

final class MockPeerDIDService: PeerDIDServiceProtocol {

    func createPeerDID(
        verkey: String,
        useLegacyService: Bool
    ) async throws -> String {
        return "did:peer:123"
    }

    func parsePeerDID(
        _ did: String
    ) throws -> DidDoc {
        DidDoc.mock(id: did)
    }
}

extension DidDoc {

    static func mock(
        id: String = "did:peer:123",
        service: [DidDocService] = []
    ) -> DidDoc {
        DidDoc(
            id: id,
            publicKey: [],
            service: service,
            authentication: [],
        )
    }
}
