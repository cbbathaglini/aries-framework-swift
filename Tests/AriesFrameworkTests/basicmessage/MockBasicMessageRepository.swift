//
//  MockBasicMessageRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework

final class MockBasicMessageRepository: BasicMessageRepositoryProtocol {

    // MARK: - Spy state
    var receivedConnectionId: String?
    private(set) var savedRecords: [BasicMessageRecord] = []
    var resultToReturn: [BasicMessageRecord] = []
    var errorToThrow: Error?


    func findByConnectionRecordId(
        connectionRecordId: String
    ) async throws -> [BasicMessageRecord] {

        receivedConnectionId = connectionRecordId

        if let errorToThrow {
            throw errorToThrow
        }

        return resultToReturn
    }

    func save(_ record: BasicMessageRecord) async throws {
        if let errorToThrow {
            throw errorToThrow
        }
        savedRecords.append(record)
    }
}
