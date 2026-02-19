//
//  EthrAnonCredsRegistry.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import indy_besu_vdr_uniffi

public class EthrAnonCredsRegistry: AnonCredsRegistry {
    public let methodName: String
    public let supportedIdentifier: NSRegularExpression

    public init(methodName: String = "ethr") {
        self.methodName = methodName

        // Regex: ^did:ethr:[^/]+/anoncreds/v0/(...)
        let pattern = #"^did:ethr:[^/]+/anoncreds/v0/(?:SCHEMA/[^/]+/\d+(?:\.\d+)*|CRED_DEF/[^/]+|REV_REG_DEF/[^/]+/[^/]+/(?:\d+|CL_ACCUM(?::|/)[A-Za-z0-9._-]+)|REV_REG/[^/]+/CL_ACCUM(?::|/)[A-Za-z0-9._-]+)$"#

        do {
            self.supportedIdentifier = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        } catch {
            fatalError("Invalid regex pattern: \(error)")
        }
    }

    public func getSchema(agent: Agent, schemaId: String) async throws -> GetSchemaReturn {
        guard matchesSupportedIdentifier(schemaId) else {
            throw AnonCredsError("Schema id não suportado por EthrAnonCredsRegistry: \(schemaId)")
        }

        let (name, version) = parseEthrSchemaId(schemaId)
        let (rawJson, _) = try await agent.ledgerService.getSchema(schemaId: schemaId)
        let jsonData = rawJson.data(using: .utf8)!
        let jsonElement = try JSONDecoder().decode(FetchSchemaReturn.self, from: jsonData)

        let issuerId = extractDidEthr(from: schemaId)

        return GetSchemaReturn(
            schema: jsonElement.schema,
            schemaId: schemaId,
            issuerId: issuerId
        )
    }

    public func getCredentialDefinition(agent: Agent, credentialDefinitionId: String) async throws -> GetCredentialDefinitionReturn {
        let credentialDefinitionVdr = try await agent.ledgerService
            .getCredentialDefinitionVdr(credentialId: credentialDefinitionId)

        let credDefValueData = credentialDefinitionVdr.value.data(using: .utf8)!
        let credDefValue = try JSONDecoder().decode(CredentialDefinitionValue.self, from: credDefValueData)

        let anonCredsCredentialDefinition = AnonCredsCredentialDefinition(
            issuerId: credentialDefinitionVdr.issuerId,
            schemaId: credentialDefinitionVdr.schemaId,
            type: credentialDefinitionVdr.credDefType,
            tag: credentialDefinitionVdr.tag,
            value: credDefValue
        )

        return GetCredentialDefinitionReturn(
            credentialDefinition: anonCredsCredentialDefinition,
            credentialDefinitionId: credentialDefinitionId
        )
    }

    public func getRevocationRegistryDefinition(
        agent: Agent,
        revocationRegistryDefinitionId: String
    ) async throws -> GetRevocationRegistryDefinitionReturn {
        
        let revocationJson = try await agent.ledgerService.getRevocationRegistryDefinition(id: revocationRegistryDefinitionId)
        var revocationRegistryResult = try JSONDecoder().decode(
            FetchIntermediateRevocationRegistryDefinitionResult.self,
            from: Data(revocationJson.utf8)
        )
        
        revocationRegistryResult.revocationRegistryDefinitionId = revocationRegistryDefinitionId
        
        guard
            let revRegId = revocationRegistryResult.revocationRegistryDefinitionId
        else {
            throw CredoError("Invalid revocation registry definition response")
        }

        guard let credentialDefinitionId = extractCredentialDefinitionId(from: revocationRegistryDefinitionId) else {
            throw CredoError("Could not extract credential definition ID")
        }

        let revDef = AnonCredsRevocationRegistryDefinition(
            issuerId: revocationRegistryResult.issuerId,
            revocDefType: revocationRegistryResult.revocDefType,
            credDefId: revocationRegistryResult.credDefId,
            tag: revocationRegistryResult.tag,
            value: revocationRegistryResult.value
        )
        
    
        let returnval = GetRevocationRegistryDefinitionReturn(
            revocationRegistryDefinition: revDef,
            revocationRegistryDefinitionId: revocationRegistryDefinitionId
        )
        
        return returnval
    }
    

    func extractCredentialDefinitionId(from revRegDefId: String) -> String? {
        let parts = revRegDefId.components(separatedBy: "REV_REG_DEF/")
        guard parts.count > 1 else { return nil }
        return parts[1].components(separatedBy: "/").first
    }

    public func getRevocationStatusList(agent: Agent, revocationRegistryId: String, timestamp: UInt64) async throws -> GetRevocationStatusListReturn {
        
            let revocationStatusList = try await agent.ledgerService
                .getRevocationStatusList(
                id: revocationRegistryId,
                timestamp: timestamp
            )
                  
            let revocationListInts  = revocationStatusList.revocationList.map { Int($0) }

            let anoncredsList = AnonCredsRevocationStatusList(
                issuerId: revocationStatusList.issuerId,
                revRegDefId: revocationStatusList.revRegDefId,
                revocationList: revocationListInts,
                currentAccumulator: revocationStatusList.currentAccumulator,
                timestamp: revocationStatusList.timestamp
            )

            return GetRevocationStatusListReturn(revocationStatusList: anoncredsList)

    }

    // MARK: - Helpers

    private func matchesSupportedIdentifier(_ id: String) -> Bool {
        let range = NSRange(location: 0, length: id.utf16.count)
        return supportedIdentifier.firstMatch(in: id, options: [], range: range) != nil
    }

    private func parseEthrSchemaId(_ schemaId: String) -> (String, String) {
        let parts = schemaId.split(separator: "/")
        let version = String(parts.last ?? "")
        let name = String(parts.dropLast().last ?? "")
        return (name, version)
    }

    private func extractDidEthr(from schemaId: String) -> String? {
        let pattern = #"^did:ethr:[^/]+"#
        return schemaId.range(of: pattern, options: .regularExpression).map { String(schemaId[$0]) }
    }
}
