//
//  MockVerifierRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 27/02/26.
//

@testable import AriesFramework
import Foundation

final class MockVerifierRepository: VerifierRepository {

    private(set) var saveCalled = false
    private(set) var saved: [VerifierRecord] = []

    private(set) var updateCalled = false
    private(set) var updated: [VerifierRecord] = []

    private(set) var getByGlobalThreadIdCalled = false
    private(set) var findByQueryCalled = false

    var verifierRecordToReturn: VerifierRecord?
    var queryResultsToReturn: [VerifierRecord] = []

    override func save(_ record: VerifierRecord) async throws {
        saveCalled = true
        saved.append(record)
    }

    override func update(_ record: VerifierRecord) async throws {
        updateCalled = true
        updated.append(record)
    }

    override func getByGlobalThreadId(globalThreadId: String) async throws -> VerifierRecord {
        getByGlobalThreadIdCalled = true

        guard let verifierRecordToReturn else {
            throw CredoError("VerifierRecord not found for globalThreadId \(globalThreadId)")
        }

        return verifierRecordToReturn
    }

    override func findByQuery(_ query: String) async -> [VerifierRecord] {
        findByQueryCalled = true
        return queryResultsToReturn
    }
}
