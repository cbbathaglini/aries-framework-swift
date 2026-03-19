//
//  MockConnectionRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework
import Foundation

final class MockConnectionRepository: ConnectionRepositoryProtocol {
    private var store: [String: ConnectionRecord] = [:]

    func delete(_ record: ConnectionRecord) async throws {
        store.removeValue(forKey: record.id)
    }
    
    func save(_ record: ConnectionRecord) async throws {
        print("✅ MockConnectionRepository.save chamado")
        store[record.id] = record
    }
    
    func getAll() async -> [ConnectionRecord] {
        store.values.map { $0 }
    }

    func update(_ record: ConnectionRecord) async throws {
        store[record.id] = record
    }

    func getById(_ id: String) async throws -> ConnectionRecord {
        guard let r = store[id] else {
            throw AriesFrameworkError.frameworkError("Not found")
        }
        return r
    }

    func findByQuery(_ query: String) async -> [ConnectionRecord] {
        let q = query.replacingOccurrences(of: " ", with: "")
        if q.contains("\"invitationKey\":") {
            let key = extractValue(q, field: "invitationKey")
            return store.values.filter { $0.getTags()["invitationKey"] == key }
        }
        if q.contains("\"threadId\":") {
            let tid = extractValue(q, field: "threadId")
            return store.values.filter { $0.threadId == tid }
        }
        if q.contains("\"verkey\":") && q.contains("\"theirKey\":") {
            let verkey = extractValue(q, field: "verkey")
            let theirKey = extractValue(q, field: "theirKey")
            return store.values.filter { $0.verkey == verkey && $0.theirKey() == theirKey }
        }
        return []
    }

    func getSingleByQuery(_ query: String) async throws -> ConnectionRecord {
        let results = await findByQuery(query)
        guard let first = results.first else {
            throw AriesFrameworkError.frameworkError("Not found")
        }
        return first
    }

    func findSingleByQuery(_ query: String) async throws -> ConnectionRecord? {
        let results = await findByQuery(query)
        return results.first
    }

    private func extractValue(_ q: String, field: String) -> String {
        let needle = "\"\(field)\":\""
        guard let start = q.range(of: needle)?.upperBound else { return "" }
        guard let end = q[start...].firstIndex(of: "\"") else { return "" }
        return String(q[start..<end])
    }
}
