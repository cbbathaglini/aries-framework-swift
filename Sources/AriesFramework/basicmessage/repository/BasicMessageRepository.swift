//
//  BasicMessageRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 28/03/25.
//

import Foundation

public class BasicMessageRepository: Repository<BasicMessageRecord> {
    
    public func findByConnectionRecordId(connectionRecordId: String) async throws -> [BasicMessageRecord] {
        return try await findByQuery("""
            {"connectionRecordId": "\(connectionRecordId)" }
            """
        )
    }
}
