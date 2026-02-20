//
//  BasicMessageRepositoryProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

public protocol BasicMessageRepositoryProtocol {
    func findByConnectionRecordId(
        connectionRecordId: String
    ) async throws -> [BasicMessageRecord]

    func save(_ record: BasicMessageRecord) async throws
}

extension BasicMessageRepository: BasicMessageRepositoryProtocol {}
