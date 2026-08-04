//
//  AnonCredsVerifierService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

public protocol AnonCredsVerifierService {
    func verifyProof(
        options: VerifyProofOptions
    ) async throws -> Bool
}
