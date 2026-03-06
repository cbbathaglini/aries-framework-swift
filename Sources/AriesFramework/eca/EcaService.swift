//
//  EcaService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 05/03/26.
//

public class EcaService {
    let agent: Agent
    
    init(agent: Agent) {
        self.agent = agent
    }
    
    public func saveText(
        text: String
    ) async throws -> EcaRecord {
        var record = EcaRecord(
            credentialText: text
        )
        logDebug("saving text of eca (Dataprev): \(record.id)")
        
        let subjectId = try EcaCredentialIndex.extractSubjectId(from: text)

        record.tags = record.tags ?? [:]
        record.tags?["subjectId"] = subjectId
        
        try await agent.ecaRepository.save(record)
        return record
    }
    
    public func getBySubjectId(_ subjectId: String) async throws -> [EcaRecord] {
        logDebug("searching ECA credential by subjectId: \(subjectId)")

        return try await agent.ecaRepository.findBySubjectId(subjectId)
    }
    
    public func getAll() async throws -> [EcaRecord]? {
        return try await agent.ecaRepository.getAll()
    }
    
    public func deleteById(_ subjectId: String) async throws {
        return try await agent.ecaRepository.deleteBySubjectId(subjectId)
    }
    
    public func deleteAll() async throws {
        return try await agent.ecaRepository.deleteAllRecords()
    }
    
}
