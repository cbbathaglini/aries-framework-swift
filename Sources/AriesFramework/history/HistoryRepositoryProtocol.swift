//
//  HistoryRepositoryProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/26.
//

import Foundation

public protocol HistoryRepositoryProtocol {
    func save(_ record: HistoryRecord) async throws
    func update(_ record: HistoryRecord) async throws
    func delete(_ record: HistoryRecord) async throws

    func getById(_ id: String) async throws -> HistoryRecord
    func getAll() async -> [HistoryRecord]

    func findByQuery(_ query: String) async -> [HistoryRecord]
    func getSingleByQuery(_ query: String) async throws -> HistoryRecord
    func findSingleByQuery(_ query: String) async throws -> HistoryRecord?

    func findByConnectionId(_ connectionId: String?) async throws -> [HistoryRecord]
    func findByAssociatedRecordId(_ associatedRecordId: String) async throws -> [HistoryRecord]
}
