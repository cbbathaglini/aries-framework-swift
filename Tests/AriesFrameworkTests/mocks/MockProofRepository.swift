//
//  MockProofRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//


@testable import AriesFramework
import Foundation

final class MockProofRepository: ProofRepository {

    private var store: [ProofExchangeRecord] = []

    private(set) var saveCalled = false
    private(set) var updateCalled = false
    private(set) var getByIdCalled = false
    private(set) var getAllCalled = false
    private(set) var findSingleByQueryCalled = false
    private(set) var getSingleByQueryCalled = false
    private(set) var getByThreadAndConnectionIdCalled = false
    private(set) var getByConnectionIdCalled = false
    private(set) var findByThreadRoleAndConnectionCalled = false
    private(set) var getByThreadAndConnectionIdAndRoleCalled = false
    private(set) var getByPresentationMessageIdCalled = false

    private(set) var savedRecords: [ProofExchangeRecord] = []
    private(set) var updatedRecords: [ProofExchangeRecord] = []

    var errorToThrowOnSave: Error?
    var errorToThrowOnUpdate: Error?

    override func save(_ record: ProofExchangeRecord) async throws {
        if let errorToThrowOnSave {
            throw errorToThrowOnSave
        }

        saveCalled = true
        savedRecords.append(record)
        store.append(record)
    }

    override func update(_ record: ProofExchangeRecord) async throws {
        if let errorToThrowOnUpdate {
            throw errorToThrowOnUpdate
        }

        updateCalled = true
        updatedRecords.append(record)

        if let index = store.firstIndex(where: { $0.id == record.id }) {
            store[index] = record
        } else {
            store.append(record)
        }
    }

    override func getById(_ id: String) async throws -> ProofExchangeRecord {
        getByIdCalled = true

        guard let record = store.first(where: { $0.id == id }) else {
            throw CredoError("ProofExchangeRecord not found")
        }

        return record
    }

    override func getAll() async -> [ProofExchangeRecord] {
        getAllCalled = true
        return store
    }

    override func findSingleByQuery(_ query: String) async throws -> ProofExchangeRecord? {
        findSingleByQueryCalled = true
        return match(query: query)
    }

    override func getSingleByQuery(_ query: String) async throws -> ProofExchangeRecord {
        getSingleByQueryCalled = true

        guard let record = match(query: query) else {
            throw CredoError("ProofExchangeRecord not found for query")
        }

        return record
    }

    override func getByThreadAndConnectionId(
        threadId: String,
        connectionId: String?
    ) async throws -> ProofExchangeRecord {
        getByThreadAndConnectionIdCalled = true

        if let record = store.first(where: {
            $0.threadId == threadId &&
            (connectionId == nil || $0.connectionId == connectionId)
        }) {
            return record
        }

        throw CredoError("ProofExchangeRecord not found")
    }

    override func getByConnectionId(connectionId: String?) async throws -> ProofExchangeRecord {
        getByConnectionIdCalled = true

        guard let record = store.first(where: { $0.connectionId == connectionId }) else {
            throw CredoError("ProofExchangeRecord not found")
        }

        return record
    }

    override func findByThreadRoleAndConnection(
        threadId: String? = nil,
        role: ProofRole? = nil,
        connectionId: String? = nil
    ) async throws -> ProofExchangeRecord? {
        findByThreadRoleAndConnectionCalled = true

        return store.first { record in
            if let threadId, record.threadId != threadId { return false }
            if let role, record.role != role { return false }
            if let connectionId, record.connectionId != connectionId { return false }
            return true
        }
    }

    override func getByThreadAndConnectionIdAndRole(
        threadId: String?,
        connectionId: String?,
        role: String
    ) async throws -> ProofExchangeRecord? {
        getByThreadAndConnectionIdAndRoleCalled = true

        return store.first { record in
            if let threadId, record.threadId != threadId { return false }
            if let connectionId, record.connectionId != connectionId { return false }
            if record.role.rawValue != role { return false }
            return true
        }
    }

    override func getByPresentationMessageId(_ messageId: String) async throws -> ProofExchangeRecord? {
        getByPresentationMessageIdCalled = true
        return store.first { $0.presentationMessage?.id == messageId }
    }

    func stub(_ records: [ProofExchangeRecord]) {
        store = records
    }

    func reset() {
        store.removeAll()
        savedRecords.removeAll()
        updatedRecords.removeAll()
        saveCalled = false
        updateCalled = false
        getByIdCalled = false
        getAllCalled = false
        findSingleByQueryCalled = false
        getSingleByQueryCalled = false
        getByThreadAndConnectionIdCalled = false
        getByConnectionIdCalled = false
        findByThreadRoleAndConnectionCalled = false
        getByThreadAndConnectionIdAndRoleCalled = false
        getByPresentationMessageIdCalled = false
        errorToThrowOnSave = nil
        errorToThrowOnUpdate = nil
    }

    private func match(query: String) -> ProofExchangeRecord? {
        store.first { matches(record: $0, query: query) }
    }

    private func matches(record: ProofExchangeRecord, query: String) -> Bool {
        func norm(_ s: String?) -> String {
            (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        let qThreadId = norm(extractJSONValue(for: "threadId", from: query))
        let qRole = norm(extractJSONValue(for: "role", from: query))
        let qConnId = norm(extractJSONValue(for: "connectionId", from: query))

        let rThreadId = norm(record.threadId)
        let rRole = norm(record.role.rawValue)
        let rConnId = norm(record.connectionId)

        if !qThreadId.isEmpty, rThreadId != qThreadId { return false }
        if !qRole.isEmpty, rRole != qRole { return false }
        if !qConnId.isEmpty, rConnId != qConnId { return false }

        return true
    }

    private func extractJSONValue(for key: String, from json: String) -> String? {
        let pattern = "\"\(NSRegularExpression.escapedPattern(for: key))\"\\s*:\\s*\"([^\"]*)\""
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(json.startIndex..<json.endIndex, in: json)

        guard let match = regex.firstMatch(in: json, range: range),
              match.numberOfRanges > 1,
              let valueRange = Range(match.range(at: 1), in: json) else {
            return nil
        }

        return String(json[valueRange])
    }
}
