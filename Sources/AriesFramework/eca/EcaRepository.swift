//
//  EcaRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 05/03/26.
//

public class EcaRepository: Repository<EcaRecord> {

    public func findBySubjectId(_ subjectId: String?) async throws -> [EcaRecord] {
        guard let subjectId else {
            return []
        }

        let query = "{\"subjectId\": \"\(subjectId)\"}"
        return await findByQuery(query)
    }

    public func existsBySubjectId(_ subjectId: String) async throws -> Bool {
        let records = try await findBySubjectId(subjectId)
        return !records.isEmpty
    }
}
