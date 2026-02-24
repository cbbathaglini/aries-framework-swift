//
//  MockMediationRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 23/02/26.
//
@testable import AriesFramework

final class MockMediationRepository: MediationRepository {

    var store: [MediationRecord] = []

    var getDefaultCalled = false
    var deleteCalled = false
    var saveCalled = false
    var updateCalled = false
    var getByConnectionIdCalled = false

    var deleted: [MediationRecord] = []
    var updated: [MediationRecord] = []
    var saved: [MediationRecord] = []

    override func getDefault() async throws -> MediationRecord? {
        getDefaultCalled = true
        return store.first
    }

    override func delete(_ record: MediationRecord) async throws {
        deleteCalled = true
        deleted.append(record)
        store.removeAll { $0.id == record.id }
    }

    override func save(_ record: MediationRecord) async throws {
        saveCalled = true
        saved.append(record)
        store.append(record)
    }

    override func update(_ record: MediationRecord) async throws {
        updateCalled = true
        updated.append(record)
        if let i = store.firstIndex(where: { $0.id == record.id }) {
            store[i] = record
        } else {
            store.append(record)
        }
    }

    override func getSingleByQuery(_ query: String) async throws -> MediationRecord {
        // usado por getByConnectionId no repo real
        if let rec = store.first { query.contains($0.connectionId) } { return rec }
        throw AriesFrameworkError.frameworkError("MediationRecord not found")
    }

    override func findSingleByQuery(_ query: String) async throws -> MediationRecord? {
        // query "{}" no getDefault
        return store.first
    }
}
