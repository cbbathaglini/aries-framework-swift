//
//  MockAnonCredsCredentialDefinitionRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 20/02/26.
//

@testable import AriesFramework
import Foundation

final class MockAnonCredsCredentialDefinitionRepository:
    AnonCredsCredentialDefinitionRepositoryProtocol {

    var recordToReturn: AnonCredsCredentialDefinitionRecord!
    var errorToThrow: Error?

    func getByCredentialDefinitionId(
        _ credentialDefinitionId: String
    ) async throws -> AnonCredsCredentialDefinitionRecord {

        if let errorToThrow { throw errorToThrow }

        return recordToReturn
    }
}
