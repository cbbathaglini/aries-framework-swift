//
//  JwsServiceProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

import Foundation

public protocol JwsServiceProtocol: AnyObject {
    func createJws(
        payload: Data,
        verkey: String
    ) async throws -> JwsGeneralFormat

    func verifyJws(
        jws: Jws,
        payload: Data
    ) throws -> (isValid: Bool, signer: String)
}

extension JwsService: JwsServiceProtocol {}
