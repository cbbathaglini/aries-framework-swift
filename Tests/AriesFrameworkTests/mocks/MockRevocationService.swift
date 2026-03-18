//
//  MockRevocationService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//

@testable import AriesFramework
import Foundation

final class MockRevocationService: RevocationService {

    var revocationStatusToReturn: (Bool, Int) = (false, 0)
    var errorToThrow: Error?

    private(set) var getRevocationStatusCallCount = 0
    private(set) var receivedCredentialRevocationId: String?
    private(set) var receivedRevocationRegistryId: String?
    private(set) var receivedRevocationInterval: AnonCredsNonRevokedInterval?

    override func getRevocationStatusAnonCreds(
        credentialRevocationId: String,
        revocationRegistryId: String,
        revocationInterval: AnonCredsNonRevokedInterval
    ) async throws -> (Bool, Int) {
        getRevocationStatusCallCount += 1
        receivedCredentialRevocationId = credentialRevocationId
        receivedRevocationRegistryId = revocationRegistryId
        receivedRevocationInterval = revocationInterval

        if let errorToThrow {
            throw errorToThrow
        }

        return revocationStatusToReturn
    }
}
