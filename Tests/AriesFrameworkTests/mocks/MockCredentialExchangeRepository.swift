//
//  MockCredentialExchangeRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework
import Foundation

final class MockCredentialExchangeRepository: CredentialExchangeRepository {

    // MARK: - Storage

    private var store: [CredentialExchangeRecord] = []

    // MARK: - Spies

    private(set) var saveCalled = false
    private(set) var updateCalled = false
    private(set) var getByIdCalled = false
    private(set) var getAllCalled = false
    private(set) var findSingleByQueryCalled = false

    // MARK: - Overrides

    override func save(_ record: CredentialExchangeRecord) async throws {
        saveCalled = true
        store.append(record)
    }

    override func update(_ record: CredentialExchangeRecord) async throws {
        updateCalled = true

        guard let index = store.firstIndex(where: { $0.id == record.id }) else {
            store.append(record)
            return
        }

        store[index] = record
    }

    override func getById(_ id: String) async throws -> CredentialExchangeRecord {
        getByIdCalled = true

        guard let record = store.first(where: { $0.id == id }) else {
            throw CredoError("CredentialExchangeRecord not found")
        }

        return record
    }

    override func getAll() async -> [CredentialExchangeRecord] {
        getAllCalled = true
        return store
    }

    // MARK: - Query-based methods (simplified)

    override func findSingleByQuery(_ query: String) async throws -> CredentialExchangeRecord? {
        findSingleByQueryCalled = true
        return match(query: query)
    }

    override func getSingleByQuery(_ query: String) async throws -> CredentialExchangeRecord {
        findSingleByQueryCalled = true

        guard let record = match(query: query) else {
            throw CredoError("CredentialExchangeRecord not found for query")
        }

        return record
    }

    // MARK: - Helpers

    private func match(query: String) -> CredentialExchangeRecord? {
        store.first { record in
            matches(record: record, query: query)
        }
    }

    private func matches(record: CredentialExchangeRecord, query: String) -> Bool {
        // ⚠️ propositalmente simples — suficiente para testes

        if query.contains("threadId") && !query.contains(record.threadId ?? "") {
            return false
        }

        if let connectionId = record.connectionId,
           query.contains("connectionId"),
           !query.contains(connectionId) {
            return false
        }

        if let role = record.role?.rawValue,
           query.contains("role"),
           !query.contains(role) {
            return false
        }

        return true
    }

    // MARK: - Test helpers

    func stub(_ records: [CredentialExchangeRecord]) {
        self.store = records
    }

    func reset() {
        store.removeAll()
        saveCalled = false
        updateCalled = false
        getByIdCalled = false
        getAllCalled = false
        findSingleByQueryCalled = false
    }
}
