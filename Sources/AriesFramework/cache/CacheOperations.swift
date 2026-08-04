//
//  CacheOperations.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/02/26.
//

import Foundation
import os

public class CacheOperations {

    
    public static func updateCache(agent: Agent) async {
        let logger = Logger(subsystem: "AriesFramework", category: "CacheOperations")
        print("updating cache")

        let all = await agent.credentialExchangeRepository.getAll()

        let schemaIds = Set(all.compactMap { $0.schemaId })
        let credDefIds = Set(all.compactMap { $0.credentialDefinitionId })
        let revRegIds = Set(all.compactMap { $0.revRegDefId })

        logger.info("schemaIds: \(schemaIds, privacy: .public) | credDefIds: \(credDefIds, privacy: .public) | revRegIds: \(revRegIds, privacy: .public)"
        )

        // Schemas
        for schemaId in schemaIds {
            do {
                _ = try await agent.ledgerService.getSchema(schemaId: schemaId)
            } catch {
                logger.warning("⚠️ Fail getSchema(\(schemaId)): \(error.localizedDescription)")
            }
        }

        // Credential Definitions
        for credDefId in credDefIds {
            do {
                _ = try await agent.ledgerService.getCredentialDefinition(id: credDefId)
            } catch {
                logger.warning("⚠️ Fail getCredentialDefinition(\(credDefId)): \(error.localizedDescription)")
            }
        }

        // Revocation Registry Definitions
        for revRegId in revRegIds {
            do {
                _ = try await agent.ledgerService
                    .getRevocationRegistryDefinitionIndyBesuLib(id: revRegId)
            } catch {
                logger.warning(
                    "⚠️ Fail getRevocationRegistryDefinition(\(revRegId)): \(error.localizedDescription)"
                )
            }
        }

        // Tails path
        do {
            _ = try await agent.ledgerService.getTailsPath()
        } catch {
            logger.warning("⚠️ Fail getTailsPath(): \(error.localizedDescription)")
        }
    }
}
