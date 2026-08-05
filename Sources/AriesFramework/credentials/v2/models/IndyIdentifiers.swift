//
//  IndyIdentifiers.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

// Swift conversion of Kotlin class IndyIdentifiers

import Foundation

class IndyIdentifiers {

    // MARK: - Regex Patterns

    static let didIndyAnonCredsBase = try! NSRegularExpression(pattern: "(did:indy:((?:[a-z][_a-z0-9-]*)(?::[a-z][_a-z0-9-]*)?):([1-9A-HJ-NP-Za-km-z]{21,22}))/anoncreds/v0/")
    static let unqualifiedSchemaIdRegex = try! NSRegularExpression(pattern: "^([a-zA-Z0-9]{21,22}):2:(.+):([0-9.]+)$")
    static let didIndySchemaIdRegex = try! NSRegularExpression(pattern: "(did:indy:(?:[a-z][_a-z0-9-]*)(?::[a-z][_a-z0-9-]*)?:([1-9A-HJ-NP-Za-km-z]{21,22}))/anoncreds/v0/SCHEMA/(.+)/([0-9.]+)")
    static let unqualifiedCredentialDefinitionIdRegex = try! NSRegularExpression(pattern: "^([a-zA-Z0-9]{21,22}):3:CL:([1-9][0-9]*):(.+)$")
    static let didIndyCredentialDefinitionIdRegex = try! NSRegularExpression(pattern: "(did:indy:(?:[a-z][_a-z0-9-]*)(?::[a-z][_a-z0-9-]*)?:([1-9A-HJ-NP-Za-km-z]{21,22}))/anoncreds/v0/CLAIM_DEF/([1-9][0-9]*)/(.+)")
    static let unqualifiedRevocationRegistryIdRegex = try! NSRegularExpression(pattern: "^([a-zA-Z0-9]{21,22}):4:[a-zA-Z0-9]{21,22}:3:CL:([1-9][0-9]*):(.+):CL_ACCUM:(.+)$")
    static let didIndyRevocationRegistryIdRegex = try! NSRegularExpression(pattern: "(did:indy:(?:[a-z][_a-z0-9-]*)(?::[a-z][_a-z0-9-]*)?:([1-9A-HJ-NP-Za-km-z]{21,22}))/anoncreds/v0/REV_REG_DEF/([1-9][0-9]*)/(.+)/(.+)")
    static let didIndyRegex = try! NSRegularExpression(pattern: "^did:indy:((?:[a-z][_a-z0-9-]*)(?::[a-z][_a-z0-9-]*)?):([1-9A-HJ-NP-Za-km-z]{21,22})$")

    // MARK: - Identifiers

    static func getUnqualifiedSchemaId(unqualifiedDid: String, name: String, version: String) -> String {
        return "\(unqualifiedDid):2:\(name):\(version)"
    }

    static func getUnqualifiedCredentialDefinitionId(unqualifiedDid: String, schemaSeqNo: String, tag: String) -> String {
        return "\(unqualifiedDid):3:CL:\(schemaSeqNo):\(tag)"
    }

    static func getUnqualifiedRevocationRegistryDefinitionId(unqualifiedDid: String, schemaSeqNo: String, credentialDefinitionTag: String, revocationRegistryTag: String) -> String {
        return "\(unqualifiedDid):4:\(unqualifiedDid):3:CL:\(schemaSeqNo):\(credentialDefinitionTag):CL_ACCUM:\(revocationRegistryTag)"
    }
    
    static func isUnqualifiedDidIndyCredentialDefinition(_ credentialDefinition: AnonCredsCredentialDefinition) -> Bool {
        return isUnqualifiedIndyDid(credentialDefinition.issuerId) &&
               isUnqualifiedSchemaId(credentialDefinition.schemaId)
    }

    static func isUnqualifiedDidIndySchema(_ schema: AnonCredsSchema) -> Bool {
        return isUnqualifiedIndyDid(schema.issuerId)
    }

    static func isUnqualifiedIndyDid(_ did: String) -> Bool {
        return unqualifiedSchemaIdRegex.firstMatch(in: did, options: [], range: NSRange(location: 0, length: did.utf16.count)) != nil
    }

    static func isUnqualifiedSchemaId(_ schemaId: String) -> Bool {
        return unqualifiedSchemaIdRegex.firstMatch(in: schemaId, options: [], range: NSRange(location: 0, length: schemaId.utf16.count)) != nil
    }

    static func isUnqualifiedCredentialDefinitionId(_ credentialDefinitionId: String) -> Bool {
        return unqualifiedCredentialDefinitionIdRegex.firstMatch(in: credentialDefinitionId, options: [], range: NSRange(location: 0, length: credentialDefinitionId.utf16.count)) != nil
    }

    static func isUnqualifiedRevocationRegistryId(_ revocationRegistryId: String) -> Bool {
        return unqualifiedRevocationRegistryIdRegex.firstMatch(in: revocationRegistryId, options: [], range: NSRange(location: 0, length: revocationRegistryId.utf16.count)) != nil
    }

    static func isDidIndySchemaId(_ schemaId: String) -> Bool {
        return didIndySchemaIdRegex.firstMatch(in: schemaId, options: [], range: NSRange(location: 0, length: schemaId.utf16.count)) != nil
    }

    static func isDidIndyCredentialDefinitionId(_ credentialDefinitionId: String) -> Bool {
        return didIndyCredentialDefinitionIdRegex.firstMatch(in: credentialDefinitionId, options: [], range: NSRange(location: 0, length: credentialDefinitionId.utf16.count)) != nil
    }

    static func isDidIndyRevocationRegistryId(_ revocationRegistryId: String) -> Bool {
        return didIndyRevocationRegistryIdRegex.firstMatch(in: revocationRegistryId, options: [], range: NSRange(location: 0, length: revocationRegistryId.utf16.count)) != nil
    }

    static func isIndyDid(_ identifier: String) -> Bool {
        return identifier.starts(with: "did:indy:")
    }
    
    static func isQualifiedDidIndySchema(_ schema: AnonCredsSchema) -> Bool {
        return !isUnqualifiedIndyDid(schema.issuerId)
    }

    static func getQualifiedDidIndySchema(schema: AnonCredsSchema, namespace: String) throws -> AnonCredsSchema {
        if isQualifiedDidIndySchema(schema) {
            return schema
        } else {
            var updatedSchema = schema
            updatedSchema.issuerId = try getQualifiedDidIndyDid(identifier: schema.issuerId, namespace: namespace)
            return updatedSchema
        }
    }

    static func isUnqualifiedDidIndyRevocationRegistryDefinition(_ revocationRegistryDefinition: AnonCredsRevocationRegistryDefinition) -> Bool {
        return isUnqualifiedIndyDid(revocationRegistryDefinition.issuerId) &&
               isUnqualifiedCredentialDefinitionId(revocationRegistryDefinition.credDefId)
    }
    
    static func isQualifiedRevocationRegistryDefinition(
        _ revocationRegistryDefinition: AnonCredsRevocationRegistryDefinition
    ) -> Bool {
        return !isUnqualifiedIndyDid(revocationRegistryDefinition.issuerId) &&
               !isUnqualifiedCredentialDefinitionId(revocationRegistryDefinition.credDefId)
    }
    
    static func getQualifiedDidIndyRevocationRegistryDefinition(
        _ revocationRegistryDefinition: AnonCredsRevocationRegistryDefinition,
        namespace: String
    ) throws -> AnonCredsRevocationRegistryDefinition {
        if isQualifiedRevocationRegistryDefinition(revocationRegistryDefinition) {
            return revocationRegistryDefinition
        } else {
            
            return AnonCredsRevocationRegistryDefinition(
                
                issuerId: try getQualifiedDidIndyDid(identifier: revocationRegistryDefinition.issuerId, namespace: namespace),
                credDefId: try getQualifiedDidIndyDid(identifier: revocationRegistryDefinition.credDefId, namespace: namespace),
                tag: revocationRegistryDefinition.tag,
                value: revocationRegistryDefinition.value
            )
        }
    }
    
    // MARK: - Parsers

    static func parseIndyDid(_ did: String) throws -> (String, String) {
        let nsrange = NSRange(did.startIndex..<did.endIndex, in: did)
        if let match = didIndyRegex.firstMatch(in: did, options: [], range: nsrange) {
            let ns1 = Range(match.range(at: 1), in: did)!
            let ns2 = Range(match.range(at: 2), in: did)!
            return (String(did[ns1]), String(did[ns2]))
        } else {
            throw NSError(domain: "IndyIdentifiers", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(did) is not a valid did:indy DID"])
        }
    }

    static func parseIndyRevocationRegistryId(_ revocationRegistryId: String) throws -> (
        did: String,
        namespaceIdentifier: String,
        schemaSeqNo: String,
        credentialDefinitionTag: String,
        revocationRegistryTag: String,
        namespace: String?
    ) {
        let nsrange = NSRange(revocationRegistryId.startIndex..<revocationRegistryId.endIndex, in: revocationRegistryId)

        if let match = didIndyRevocationRegistryIdRegex.firstMatch(in: revocationRegistryId, options: [], range: nsrange) {
            let did = (revocationRegistryId as NSString).substring(with: match.range(at: 1))
            let namespace = (revocationRegistryId as NSString).substring(with: match.range(at: 2))
            let namespaceIdentifier = (revocationRegistryId as NSString).substring(with: match.range(at: 3))
            let schemaSeqNo = (revocationRegistryId as NSString).substring(with: match.range(at: 4))
            let credentialDefinitionTag = (revocationRegistryId as NSString).substring(with: match.range(at: 5))
            let revocationRegistryTag = (revocationRegistryId as NSString).substring(with: match.range(at: 6))

            return (did, namespaceIdentifier, schemaSeqNo, credentialDefinitionTag, revocationRegistryTag, namespace)
        }

        if let match = unqualifiedRevocationRegistryIdRegex.firstMatch(in: revocationRegistryId, options: [], range: nsrange) {
            let did = (revocationRegistryId as NSString).substring(with: match.range(at: 1))
            let schemaSeqNo = (revocationRegistryId as NSString).substring(with: match.range(at: 2))
            let credentialDefinitionTag = (revocationRegistryId as NSString).substring(with: match.range(at: 3))
            let revocationRegistryTag = (revocationRegistryId as NSString).substring(with: match.range(at: 4))

            return (did, did, schemaSeqNo, credentialDefinitionTag, revocationRegistryTag, nil)
        }

        throw NSError(domain: "IndyIdentifiers", code: 2, userInfo: [
            NSLocalizedDescriptionKey: "Invalid revocation registry id: \(revocationRegistryId)"
        ])
    }

    static func getUnqualifiedDidIndyDid(identifier: String) throws -> String {
        if isUnqualifiedIndyDid(identifier) {
            return identifier
        } else if isDidIndySchemaId(identifier) {
            let (namespaceIdentifier, schemaName, schemaVersion) = try parseIndySchemaId(identifier)
            return getUnqualifiedSchemaId(unqualifiedDid: namespaceIdentifier, name: schemaName, version: schemaVersion)
        } else if isDidIndyCredentialDefinitionId(identifier) {
            let (namespaceIdentifier, schemaSeqNo, tag) = try parseIndyCredentialDefinitionId(identifier)
            return getUnqualifiedCredentialDefinitionId(unqualifiedDid: namespaceIdentifier, schemaSeqNo: schemaSeqNo, tag: tag)
        } else if isDidIndyRevocationRegistryId(identifier) {
            let parsed = try parseIndyRevocationRegistryId(identifier)
            return getUnqualifiedRevocationRegistryDefinitionId(
                unqualifiedDid: parsed.namespaceIdentifier,
                schemaSeqNo: parsed.schemaSeqNo,
                credentialDefinitionTag: parsed.credentialDefinitionTag,
                revocationRegistryTag: parsed.revocationRegistryTag
            )
        } else {
            let (namespaceIdentifier, _) = try parseIndyDid(identifier)
            return namespaceIdentifier
        }
    }
    
    static func isQualifiedDidIndyCredentialDefinition(
        _ credentialDefinition: AnonCredsCredentialDefinition
    ) -> Bool {
        return !isUnqualifiedIndyDid(credentialDefinition.issuerId) &&
               !isUnqualifiedSchemaId(credentialDefinition.schemaId)
    }
    
    
    static func getQualifiedDidIndyCredentialDefinition(
        credentialDefinition: AnonCredsCredentialDefinition,
        namespace: String
    ) throws -> AnonCredsCredentialDefinition {
        if isQualifiedDidIndyCredentialDefinition(credentialDefinition) {
            return credentialDefinition
        }

        return AnonCredsCredentialDefinition(
            issuerId: try getQualifiedDidIndyDid(identifier: credentialDefinition.issuerId, namespace: namespace),
            schemaId: try getQualifiedDidIndyDid(identifier: credentialDefinition.schemaId, namespace: namespace),
            type: credentialDefinition.type,
            tag: credentialDefinition.tag,
            value: credentialDefinition.value
        )
    }

    static func getQualifiedDidIndyDid(identifier: String, namespace: String) throws -> String {
        if IndyIdentifiers.isIndyDid(identifier) {
            return identifier
        }

        guard !namespace.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "IndyIdentifiers", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Missing required indy namespace"
            ])
        }

        if IndyIdentifiers.isUnqualifiedSchemaId(identifier) {
            let (namespaceIdentifier, schemaName, schemaVersion) = try parseIndySchemaId(identifier)
            return "did:indy:\(namespace):\(namespaceIdentifier)/anoncreds/v0/SCHEMA/\(schemaName)/\(schemaVersion)"
        } else if IndyIdentifiers.isUnqualifiedCredentialDefinitionId(identifier) {
            let (namespaceIdentifier, schemaSeqNo, tag) = try parseIndyCredentialDefinitionId(identifier)
            return "did:indy:\(namespace):\(namespaceIdentifier)/anoncreds/v0/CLAIM_DEF/\(schemaSeqNo)/\(tag)"
        } else if IndyIdentifiers.isUnqualifiedRevocationRegistryId(identifier) {
            let (_, namespaceIdentifier, schemaSeqNo, credentialDefinitionTag, revocationRegistryTag, _) = try parseIndyRevocationRegistryId(identifier)
            return "did:indy:\(namespace):\(namespaceIdentifier)/anoncreds/v0/REV_REG_DEF/\(schemaSeqNo)/\(credentialDefinitionTag)/\(revocationRegistryTag)"
        } else if IndyIdentifiers.isUnqualifiedIndyDid(identifier) {
        
            return "did:indy:\(namespace):\(identifier)"
        } else {
            throw NSError(domain: "IndyIdentifiers", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Cannot create qualified indy identifier for '\(identifier)' with namespace '\(namespace)'"
            ])
        }
    }

    static func parseIndySchemaId(_ schemaId: String) throws -> (String, String, String) {
        let range = NSRange(location: 0, length: schemaId.utf16.count)

        if let match = IndyIdentifiers.didIndySchemaIdRegex.firstMatch(in: schemaId, range: range) {
            let ns = schemaId as NSString
            let namespaceIdentifier = ns.substring(with: match.range(at: 2))
            let schemaName = ns.substring(with: match.range(at: 3))
            let schemaVersion = ns.substring(with: match.range(at: 4))
            return (namespaceIdentifier, schemaName, schemaVersion)
        }

        if let match = IndyIdentifiers.unqualifiedSchemaIdRegex.firstMatch(in: schemaId, range: range) {
            let ns = schemaId as NSString
            let namespaceIdentifier = ns.substring(with: match.range(at: 1))
            let schemaName = ns.substring(with: match.range(at: 2))
            let schemaVersion = ns.substring(with: match.range(at: 3))
            return (namespaceIdentifier, schemaName, schemaVersion)
        }

        throw NSError(
            domain: "IndyIdentifiers",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Invalid schema id: \(schemaId)"]
        )
    }

    static func parseIndyCredentialDefinitionId(_ credentialDefinitionId: String) throws -> (String, String, String) {
        let didIndyPattern = IndyIdentifiers.didIndyCredentialDefinitionIdRegex
        let legacyPattern = IndyIdentifiers.unqualifiedCredentialDefinitionIdRegex
        let range = NSRange(location: 0, length: credentialDefinitionId.utf16.count)

        if let match = didIndyPattern.firstMatch(in: credentialDefinitionId, range: range) {
            let namespaceIdentifier = (credentialDefinitionId as NSString).substring(with: match.range(at: 2))
            let schemaSeqNo = (credentialDefinitionId as NSString).substring(with: match.range(at: 3))
            let tag = (credentialDefinitionId as NSString).substring(with: match.range(at: 4))
            return (namespaceIdentifier, schemaSeqNo, tag)
        }

        if let match = legacyPattern.firstMatch(in: credentialDefinitionId, range: range) {
            let namespaceIdentifier = (credentialDefinitionId as NSString).substring(with: match.range(at: 1))
            let schemaSeqNo = (credentialDefinitionId as NSString).substring(with: match.range(at: 2))
            let tag = (credentialDefinitionId as NSString).substring(with: match.range(at: 3))
            return (namespaceIdentifier, schemaSeqNo, tag)
        }

        throw NSError(
            domain: "IndyIdentifiers",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Invalid credential definition id: \(credentialDefinitionId)"]
        )
    }
}
