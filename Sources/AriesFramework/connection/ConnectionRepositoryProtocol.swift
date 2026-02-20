//
//  ConnectionRepositoryProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

public protocol ConnectionRepositoryProtocol {

    func save(_ record: ConnectionRecord) async throws
    func update(_ record: ConnectionRecord) async throws
    func getById(_ id: String) async throws -> ConnectionRecord
    func delete(_ record: ConnectionRecord) async throws
    
    func getAll() async -> [ConnectionRecord]
    func findByQuery(_ query: String) async -> [ConnectionRecord]
    func findSingleByQuery(_ query: String) async throws -> ConnectionRecord?
    func getSingleByQuery(_ query: String) async throws -> ConnectionRecord
}

extension ConnectionRepository: ConnectionRepositoryProtocol {}
