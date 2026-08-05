//
//  AnoncredsVerifierService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation
import os
import Anoncreds
import indy_besu_vdr_uniffi

public class AnonCredsRsVerifierService: AnonCredsVerifierService {
    let agent: Agent
    private let logger = Logger(subsystem: "org.hyperledger.ariesframework", category: "AnonCredsRsVerifierService")
    
    public init(agent: Agent) {
        self.agent = agent
    }
    
    public func verifyProof(options: VerifyProofOptions) async throws -> Bool {
        let proofRequest = options.proofRequest
        let presentationMessage = options.presentationMessage
        let requestMessage = options.requestMessage
        let proof = options.proof
        let schemas = options.schemas
        let credentialDefinitions = options.credentialDefinitions
        
        try AnonCredsEncoder.checkEncodes(anonCredsProof: proof)
        
        let proofJson = try presentationMessage.anoncredsProof()
        let proofIdentifiers: [ProofIdentifier] = proof.identifiers.map { id in
            ProofIdentifier(
                schemaId: id.schemaId,
                credentialDefinitionId: id.credDefId,
                revocationRegistryId: id.revRegId,
                timestamp: id.timestamp != nil ? Int(id.timestamp!) : nil
            )
        }
        let partialProof : PartialProof =  PartialProof(identifiers: proofIdentifiers)
        let identifiers = partialProof.identifiers
        if identifiers.isEmpty {
            return false
        }

        let identifier = identifiers.first!
        let holderTimestamp = identifier.timestamp
        let revRegId = identifier.revocationRegistryId

        let presentationRequest = try PresentationRequest(json: requestMessage.anoncredsProofRequest())

        let presentation = try Presentation(json: proofJson)
       
        let schemaIds = Set(schemas.schemas.keys)
        let schemasAnoncreds =
            try await RecoverFromLedger.getSchemas(schemaIds: schemaIds, agent: agent)

        let credDefIds = Set(credentialDefinitions.credentialDefinitions.keys)
        let credDefsAnoncreds =
            try await RecoverFromLedger.getCredentialDefinitions(
                credentialDefinitionIds: credDefIds,
                agent: agent
            )

        // If the presentation does NOT use revocation
        if holderTimestamp == nil || revRegId == nil {
            do {
                return try Verifier().verifyPresentation(
                    presentation: presentation,
                    presReq: presentationRequest,
                    schemas: schemasAnoncreds,
                    credDefs: credDefsAnoncreds,
                    revRegDefs: nil,
                    revStatusLists: nil,
                    nonrevokeIntervalOverride: nil
                )
            } catch {
                return false
            }
        }

        // Uses revocation
        print("🔍 DIAG verifyProof REVOCACAO ativada - revRegId=\(String(describing: revRegId)) holderTimestamp=\(String(describing: holderTimestamp))")
        let ts = UInt64(holderTimestamp!)

        let revRegDefJson =
            try await agent.ledgerService.getRevocationRegistryDefinition(id: revRegId!)
        let revRegDefUni = try Anoncreds.RevocationRegistryDefinition(json: revRegDefJson)

        let revRegDefsMap = [revRegId!: revRegDefUni]

        let ledgerStatusList =
            try await agent.ledgerService.getRevocationStatusList(
                id: revRegId!,
                timestamp: ts
            )

        let statusListJson = indyBesuRevocationStatusListToJson(
            src: ledgerStatusList,
            revRegDefId: revRegId!,
            targetTimestamp: ts
        )

        let statusListUniffi = try Anoncreds.RevocationStatusList(json: statusListJson)

        let timestampResult = try await verifyTimestamps(proof: proof, proofRequest: proofRequest)
        print("🔍 DIAG verifyProof verifyTimestamps verified=\(timestampResult.verified) overrides=\(String(describing: timestampResult.nonRevokedIntervalOverrides?.count ?? 0))")
        guard timestampResult.verified else { return false }

        var intervalOverrides: [String: [UInt64: UInt64]] = [:]
        if let overrides = timestampResult.nonRevokedIntervalOverrides {
            for item in overrides {
                intervalOverrides[item.revocationRegistryDefinitionId] =
                    [item.requestedFromTimestamp: item.overrideRevocationStatusListTimestamp]
            }
        }

        do {
            let verified = try Verifier().verifyPresentation(
                presentation: presentation,
                presReq: presentationRequest,
                schemas: schemasAnoncreds,
                credDefs: credDefsAnoncreds,
                revRegDefs: revRegDefsMap,
                revStatusLists: [statusListUniffi],
                nonrevokeIntervalOverride: intervalOverrides.isEmpty ? nil : intervalOverrides
            )
            return verified
        } catch {
            return false
        }
    }
    
    private func indyBesuRevocationStatusListToJson(
        src: indy_besu_vdr_uniffi.RevocationStatusList,
        revRegDefId: String,
        targetTimestamp: UInt64
    ) -> String {

        let listAsInt = src.revocationList.map { Int($0) }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]

        let revocationListData = try! encoder.encode(listAsInt)
        let revocationListJson = String(data: revocationListData, encoding: .utf8)!

        return """
        {
          "issuerId": "\(src.issuerId)",
          "revRegDefId": "\(revRegDefId)",
          "revocationList": \(revocationListJson),
          "currentAccumulator": "\(src.currentAccumulator)",
          "timestamp": \(targetTimestamp)
        }
        """
    }
    
    
    func jsonStringToDictionary(_ json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
    
    func jsonStringToDict(_ json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
    
    private func verifyTimestamps(
        proof: AnonCredsProof,
        proofRequest: AnonCredsProofRequest
    ) async throws -> TimestampVerificationResult {
        var nonRevokedIntervalOverrides: [NonRevokedIntervalOverride] = []
        let globalNonRevokedInterval = proofRequest.nonRevoked
        
        var requestedNonRevokedRestrictions: [RequestedProofItem] = []
        
        
        let allRequestedValues: [Any] =
        Array(proofRequest.requestedAttributes.values) as [Any] +
        Array(proofRequest.requestedPredicates.values) as [Any]
        
        for value in allRequestedValues {
            let nonRevokedInterval: AnonCredsNonRevokedInterval?
            
            if let attr = value as? AnonCredsRequestedAttribute {
                nonRevokedInterval = attr.nonRevoked
            } else if let pred = value as? AnonCredsRequestedPredicate {
                nonRevokedInterval = pred.nonRevoked
            } else {
                nonRevokedInterval = globalNonRevokedInterval
            }
            
            if let interval = nonRevokedInterval {
                let restrictions: [AnonCredsProofRequestRestriction]
                
                if let attr = value as? AnonCredsRequestedAttribute {
                    restrictions = attr.restrictions ?? []
                } else if let pred = value as? AnonCredsRequestedPredicate {
                    restrictions = pred.restrictions ?? []
                } else {
                    restrictions = []
                }
                
                for restriction in restrictions {
                    requestedNonRevokedRestrictions.append(
                        RequestedProofItem(
                            nonRevokedInterval: interval,
                            schemaId: restriction.schemaId,
                            credentialDefinitionId: restriction.credDefId,
                            revocationRegistryDefinitionId: restriction.revRegId
                        )
                    )
                }
            }
        }
        
        for identifier in proof.identifiers {
            guard let timestamp = identifier.timestamp,
                  let revRegId = identifier.revRegId else {
                continue
            }
            
            let related = requestedNonRevokedRestrictions.first(where: { item in
                item.revocationRegistryDefinitionId == revRegId ||
                item.credentialDefinitionId == identifier.credDefId ||
                item.schemaId == identifier.schemaId
            })
            
            let requestedFrom = related?.nonRevokedInterval.from
            
            if let requestedFrom = requestedFrom, requestedFrom > timestamp {
                let revocationStatusList = try await agent.ledgerService.getRevocationStatusList(
                    id: revRegId,
                    timestamp: requestedFrom
                )
                
                let vdrTimestamp = revocationStatusList.timestamp
                if vdrTimestamp == timestamp {
                    nonRevokedIntervalOverrides.append(
                        NonRevokedIntervalOverride(
                            revocationRegistryDefinitionId: revRegId,
                            requestedFromTimestamp: requestedFrom,
                            overrideRevocationStatusListTimestamp: timestamp
                        )
                    )
                } else {
                    //                        "VDR timestamp for \(requestedFrom) does not correspond to the one provided in proof identifiers. " +
                    //                        "Expected: \(timestamp), received: \(vdrTimestamp)"
                    //                    )
                    return TimestampVerificationResult(verified: false, nonRevokedIntervalOverrides: nil)
                }
            }
        }
        
        return TimestampVerificationResult(
            verified: true,
            nonRevokedIntervalOverrides: nonRevokedIntervalOverrides.isEmpty ? nil : nonRevokedIntervalOverrides
        )
    }
}
