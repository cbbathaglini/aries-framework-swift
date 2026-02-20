//
//  PeerDIDServiceProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

public protocol PeerDIDServiceProtocol: AnyObject {

    func createPeerDID(
        verkey: String,
        useLegacyService: Bool
    ) async throws -> String

    func parsePeerDID(
        _ did: String
    ) throws -> DidDoc
}

extension PeerDIDService: PeerDIDServiceProtocol {}


extension PeerDIDServiceProtocol{
    func createPeerDID(
        verkey: String,
        useLegacyService: Bool = true
    ) async throws -> String{
        try await createPeerDID(
            verkey: verkey,
            useLegacyService: useLegacyService
        )
    }
}
