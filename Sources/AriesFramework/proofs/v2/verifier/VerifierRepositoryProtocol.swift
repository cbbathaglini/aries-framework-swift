//
//  VerifierRepositoryProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/26.
//

import Foundation

public protocol VerifierRepositoryProtocol {
    func save(_ record: VerifierRecord) async throws
    func update(_ record: VerifierRecord) async throws
    func delete(_ record: VerifierRecord) async throws

    func getById(_ id: String) async throws -> VerifierRecord
    func getAll() async -> [VerifierRecord]

    func findByQuery(_ query: String) async -> [VerifierRecord]
    func getSingleByQuery(_ query: String) async throws -> VerifierRecord
    func findSingleByQuery(_ query: String) async throws -> VerifierRecord?

    func getByProofRecordId(proofRecordId: String) async throws -> VerifierRecord
    func getByGlobalThreadId(globalThreadId: String) async throws -> VerifierRecord
}
