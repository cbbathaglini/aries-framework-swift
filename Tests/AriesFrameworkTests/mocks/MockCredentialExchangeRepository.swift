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
    private(set) var getSingleByQueryCalled = false
    
    private(set) var getByThreadAndRoleCalled = false
    private(set) var findByThreadRoleAndConnectionIdCalled = false
    
    var getByW3cCredentialIdCalled = false
    var stubbedById: [String: CredentialExchangeRecord] = [:]

    override func getByThreadAndRole(
        threadId: String,
        role: CredentialRole?
    ) async throws -> CredentialExchangeRecord? {
        getByThreadAndRoleCalled = true
        return store.first { $0.threadId == threadId && $0.role == role }
    }

    override func findByThreadRoleAndConnectionId(
        threadId: String,
        role: CredentialRole?,
        connectionId: String?
    ) async throws -> CredentialExchangeRecord? {
        findByThreadRoleAndConnectionIdCalled = true
        return store.first { rec in
            if rec.threadId != threadId { return false }
            if let role, rec.role != role { return false }
        
            if let connectionId, rec.connectionId != connectionId { return false }
            return true
        }
    }

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
        getSingleByQueryCalled = true

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

        func norm(_ s: String?) -> String {
            (s ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        }

        let qThreadId = norm(extractJSONValue(for: "threadId", from: query))
        let qRole     = norm(extractJSONValue(for: "role", from: query)).split(separator: ".").last.map(String.init) ?? ""
        let qConnId   = norm(extractJSONValue(for: "connectionId", from: query))

        let rThreadId = norm(record.threadId)
        let rRole     = norm(record.role?.rawValue).split(separator: ".").last.map(String.init) ?? ""
        let rConnId   = norm(record.connectionId)

        if !qThreadId.isEmpty, rThreadId != qThreadId { return false }
        if !qRole.isEmpty, rRole != qRole { return false }
        if !qConnId.isEmpty, rConnId != qConnId { return false }

        return true
    }

    private func extractJSONValue(for key: String, from json: String) -> String? {
        // Regex: "key" : "value"
        let pattern = "\"\(NSRegularExpression.escapedPattern(for: key))\"\\s*:\\s*\"([^\"]*)\""
        guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(json.startIndex..<json.endIndex, in: json)
        guard let match = re.firstMatch(in: json, range: range),
              match.numberOfRanges >= 2,
              let r = Range(match.range(at: 1), in: json) else {
            return nil
        }
        return String(json[r])
    }

    private func normalizeEnumString(_ raw: String) -> String {
        // casos comuns:
        // "issuer" -> "issuer"
        // "CredentialRole.issuer" -> "issuer"
        // "AriesFramework.CredentialRole.issuer" -> "issuer"
        if let last = raw.split(separator: ".").last {
            return String(last)
        }
        return raw
    }
    
    override func getByW3cCredentialId(_ id: String) async throws -> CredentialExchangeRecord {
        getByW3cCredentialIdCalled = true
        if let r = stubbedById[id] { return r }
        throw CredoError("Credential not found")
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
        getByThreadAndRoleCalled = false
        findByThreadRoleAndConnectionIdCalled = false
    }
}
