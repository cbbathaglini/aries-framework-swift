//
//  HistoryRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 01/10/25.
//

public class HistoryRepository: Repository<HistoryRecord> {

    public func findByConnectionId(_ connectionId: String?) async throws -> [HistoryRecord] {
        guard let connectionId else {
            return []
        }
        let query = "{\"connectionId\": \"\(connectionId)\"}"
        return await findByQuery(query)
    }

    public func findByAssociatedRecordId(_ associatedRecordId: String) async throws -> [HistoryRecord] {
        return await findByQuery("""
            {\"associatedRecordId\": \"\(associatedRecordId)\"}
            """)
    }
}

extension HistoryRepository: HistoryRepositoryProtocol {}
