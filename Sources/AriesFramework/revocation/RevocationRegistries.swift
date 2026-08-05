//
//  RevocationRegistries.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation
import os.log
import indy_besu_vdr_uniffi

public class RevocationRegistries {
    let agent: Agent

    init(agent: Agent) {
        self.agent = agent
    }

    private let logger = Logger(subsystem: "org.hyperledger.ariesframework", category: "RevocationRegistries")
    
    func getRevocationRegistriesForRequest(
        proofRequest: AnonCredsProofRequest,
        selectedCredentials: AnonCredsSelectedCredentials
    ) async throws -> RevocationRegistriesForRequestResult {

        var updatedSelectedCredentials = selectedCredentials
        var revocationRegistries: [String: RevocationRegistryBucket] = [:]

        logDebug("Retrieving revocation registries for proof request \(proofRequest) \(selectedCredentials)")

        var referentCredentials: [[String: Any]] = []

        for (referent, selectedCredential) in selectedCredentials.attributes {
            let nonRevoked = proofRequest.requestedAttributes[referent]?.nonRevoked ?? proofRequest.nonRevoked
            referentCredentials.append([
                "type": "attributes",
                "referent": referent,
                "selectedCredential": selectedCredential,
                "nonRevoked": nonRevoked as Any
            ])
        }

        for (referent, selectedCredential) in selectedCredentials.predicates {
            let nonRevoked = proofRequest.requestedPredicates[referent]?.nonRevoked ?? proofRequest.nonRevoked
            referentCredentials.append([
                "type": "predicates",
                "referent": referent,
                "selectedCredential": selectedCredential,
                "nonRevoked": nonRevoked as Any
            ])
        }

        for credential in referentCredentials {
            guard
                let referent = credential["referent"] as? String,
                let _ = credential["type"] as? String,
                let selected = credential["selectedCredential"],
                let nonRevoked = credential["nonRevoked"] as? AnonCredsNonRevokedInterval
            else {
                continue
            }
            
            let info: AnonCredsCredentialInfo
            let timestamp: UInt64?
            
            if let attr = selected as? AnonCredsRequestedAttributeMatch {
                info = attr.credentialInfo
                timestamp = attr.timestamp != nil ? UInt64(attr.timestamp!) : nil
            } else if let pred = selected as? AnonCredsRequestedPredicateMatch {
                info = pred.credentialInfo
                timestamp = pred.timestamp != nil ? UInt64(pred.timestamp!) : nil
            } else {
                throw CredoError("selectedCredential inválido para referent '\(referent)'")
            }
            
            guard let credentialRevocationId = info.credentialRevocationId,
                  let revocationRegistryId = info.revocationRegistryId else {
                continue
            }
            
            if nonRevoked != nil && credentialRevocationId != nil && revocationRegistryId != nil {
                
                /*logger.trace("Presentation is requesting proof of non revocation for referent '\(referent)', creating revocation state for credential: nonRevoked=\(nonRevoked), credentialRevocationId=\(credentialRevocationId), revocationRegistryId=\(revocationRegistryId), timestamp=\(String(describing: timestamp))")*/
                
                try RevocationInterval.assertBestPractice(nonRevoked)
                
                let revocationRegistry = try await agent.ledgerService.getRevocationRegistryDefinitionIndyBesuLib(id: revocationRegistryId)
                
                let revRegValue = try JSONDecoder().decode(RevocationRegistryValue.self, from: Data(revocationRegistry.value.utf8))
                
                revocationRegistries[revocationRegistryId] = await RevocationRegistryBucket(
                    definition: revocationRegistry,
                    tailsFilePath: try agent.ledgerService.getTailsPath(),
                    tailsHash: revRegValue.tailsHash
                )
                
                let tsToFetch: UInt64? = timestamp ?? nonRevoked.to
                
                
                if let tsToFetch = tsToFetch,
                   !revocationRegistries.isEmpty,
                   revocationRegistries[revocationRegistryId]?.revocationStatusLists?[tsToFetch] == nil {
                    
                    let statusList = try await agent.ledgerService.getRevocationStatusList(
                        id: revocationRegistryId,
                        timestamp: tsToFetch
                    )
                    
                    let ledgerTs = statusList.timestamp
                    
                    revocationRegistries[revocationRegistryId] = RevocationRegistryBucket(
                        definition: revocationRegistries[revocationRegistryId]!.definition,
                        tailsFilePath: revocationRegistries[revocationRegistryId]!.tailsFilePath,
                        tailsHash: revocationRegistries[revocationRegistryId]!.tailsHash,
                        revocationStatusLists: [
                            ledgerTs: statusList
                        ]
                    )
                    
                    if timestamp == nil {
                        if var attr = updatedSelectedCredentials.attributes[referent] {
                            attr.timestamp = ledgerTs
                            updatedSelectedCredentials.attributes[referent] = attr
                        }
                        if var pred = updatedSelectedCredentials.predicates[referent] {
                            pred.timestamp = ledgerTs
                            updatedSelectedCredentials.predicates[referent] = pred
                        }
                    }  
                }
            }
        }

        logDebug("Retrieved revocation registries for proof request: \(revocationRegistries)")

        return RevocationRegistriesForRequestResult(
            revocationRegistries: revocationRegistries,
            updatedSelectedCredentials: updatedSelectedCredentials
        )
    }
    
    
    public func getRevocationRegistriesForProof(
        proof: AnonCredsProof
    ) async throws -> [String: RevocationRegistryEntry] {

        var revocationRegistries: [String: RevocationRegistryEntry] = [:]

        for identifier in proof.identifiers {
            
            guard
                let revRegId = identifier.revRegId,
                let timestamp = identifier.timestamp
            else { continue }
            
            let registry = try agent.anonCredsRegistryService.getRegistryForIdentifier(
                for: revRegId
            )
            
          if revocationRegistries[revRegId] == nil {
                
                let result = try await registry.getRevocationRegistryDefinition(
                    agent: agent,
                    revocationRegistryDefinitionId: revRegId
                )
                
                let definition = result.revocationRegistryDefinition
                let metadata = result.resolutionMetadata
                
                guard let definition else {
                    throw NSError(
                        domain: "AnonCreds",
                        code: 400,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Could not retrieve revocation registry definition for \(revRegId): \(metadata)"
                        ]
                    )
                }
                
                revocationRegistries[revRegId] = RevocationRegistryEntry(
                    definition: definition,
                    revocationStatusLists: [:]
                )
            }
            
            
            if var entry = revocationRegistries[revRegId] {
                
                var lists = entry.revocationStatusLists ?? [:]
                
                if lists[timestamp] == nil {
                    
                    let result = try await registry.getRevocationStatusList(
                        agent: agent,
                        revocationRegistryId: revRegId,
                        timestamp: timestamp
                    )
                    
                    let statusList = result.revocationStatusList
                    
                    guard let statusList else {
                        throw NSError(
                            domain: "AnonCreds",
                            code: 400,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "Could not retrieve revocation status list for \(revRegId)"
                            ]
                        )
                    }
                    
                    lists[timestamp] = statusList
                    entry.revocationStatusLists = lists
                    
                    revocationRegistries[revRegId] = entry
                }
            }
        }
        return revocationRegistries
    }
    
}
