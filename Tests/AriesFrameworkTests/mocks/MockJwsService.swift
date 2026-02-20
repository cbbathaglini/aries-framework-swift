//
//  MockJwsService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//
@testable import AriesFramework
import Foundation

final class MockJwsService: JwsServiceProtocol {

    func createJws(
        payload: Data,
        verkey: String
    ) async throws -> JwsGeneralFormat {
        JwsGeneralFormat(
            header: ["kid": verkey],
            signature: "sig",
            protected: "prot"
        )
    }

    func verifyJws(
        jws: Jws,
        payload: Data
    ) throws -> (isValid: Bool, signer: String) {
        return (true, verkeyFromHeader(jws))
    }

    private func verkeyFromHeader(_ jws: Jws) -> String {
        "verkey"
    }
}
