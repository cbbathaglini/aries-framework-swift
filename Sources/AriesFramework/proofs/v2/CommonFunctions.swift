//
//  CommonFunctions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 08/10/25.
//
import Foundation
import AnyCodable

public class CommonFunctions {
    
    private let agent: Agent
    private let proofFormats: [any ProofFormatService]

    
    public init(agent: Agent, proofFormats: [any ProofFormatService]) {
        self.agent = agent
        self.proofFormats = proofFormats
    }
    
    func updateState(proofRecord: inout ProofExchangeRecord, newState: ProofState) async throws {
        
        proofRecord.state = newState
        try await agent.proofRepository.update(proofRecord)
        agent.agentDelegate?.onProofStateChangedV2(proofRecord: proofRecord)
    
    }
    
    
    func getFormatServicesByList(_ formats: [ProofFormatSpec]) -> [any ProofFormatService] {
        var seen = Set<String>()
        var result: [any ProofFormatService] = []

        for format in formats {
            if let id = format.attachmentId,
               let service = getFormatServiceForFormatKey(id),
               !seen.contains(service.formatKey) {
                seen.insert(service.formatKey)
                result.append(service)
            }
        }

        return result
    }

    func getFormatServiceForFormatKey(_ formatKey: String) -> (any ProofFormatService)? {
        logDebug("format key: \(formatKey)")
        return proofFormats.first { $0.formatKey == formatKey }
    }

    
     func getFormatServiceForFormat(_ format: String) -> (any ProofFormatService)? {
        return proofFormats.first { $0.supportsFormat(formatIdentifier: format) }
    }

    func getFormatServices(_ formats: [String: AnyCodable]) -> [any ProofFormatService] {
        var seen = Set<String>()
        var result: [any ProofFormatService] = []

        for key in formats.keys {
            if let service = getFormatServiceForFormatKey(key),
               !seen.contains(service.formatKey) {
                seen.insert(service.formatKey)
                result.append(service)
            }
        }

        return result
    }


    func getFormatServicesFromMessage(_ messageFormats: [ProofFormatSpec]) -> [any ProofFormatService] {
        var seenKeys = Set<String>()
        var result: [any ProofFormatService] = []

        for format in messageFormats {
            guard let service = getFormatServiceForFormat(format.format) else { continue }
            if !seenKeys.contains(service.formatKey) {
                seenKeys.insert(service.formatKey)
                result.append(service)
            }
        }

        return result
    }
}
