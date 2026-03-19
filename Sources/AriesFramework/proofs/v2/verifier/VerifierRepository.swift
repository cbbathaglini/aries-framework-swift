//
//  VerifierRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 15/10/25.
//

import Foundation
import AnyCodable

public class VerifierRepository: Repository<VerifierRecord> {
    public func getByProofRecordId(proofRecordId: String) async throws -> VerifierRecord {
        let query = """
        {"proofRecordId": "\(proofRecordId)"}
        """
        
        logDebug("query: \(query)")
        
        do {
            let record = try await getSingleByQuery(query)
            logDebug("✅ register founded: \(record)")
            return record
        } catch {
            logDebug("❌ Error getByProofRecordId: \(error)")
            throw error
        }
    }
    
    public func getByGlobalThreadId(globalThreadId: String) async throws -> VerifierRecord {
        let query = """
        {"globalThreadId": "\(globalThreadId)"}
        """
        return try await getSingleByQuery(query)
    }
    
}

extension VerifierRepository: VerifierRepositoryProtocol {}
