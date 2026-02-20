//
//  AnoncredsRsHolderService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import BigInt
import anoncreds_uniffi
import os
import AnyCodable

public class AnonCredsRsHolderService: AnonCredsHolderService {

    let agent: Agent
    
    private let logger = Logger(subsystem: "org.hyperledger.ariesframework", category: "AnonCredsRsHolderService")

    init(agent: Agent) {
        self.agent = agent
    }

    public func storeCredential(
        options: StoreCredentialOptions,
        metadata: [String: Any]?
    ) async throws -> String {

        logDebug("Storing credential: \(String(describing: options.credential))")

        let credential = options.credential
        let credDef = options.credentialDefinition
        let credDefId = options.credentialDefinitionId
        let credReqMetadata = options.credentialRequestMetadata
        let schema = options.schema
        let revocationRegistry = options.revocationRegistry

        var w3cCredential: W3cJsonLdVerifiableCredential

        if let existingW3c = credential as? W3cJsonLdVerifiableCredential {
            w3cCredential = existingW3c
        } else if let anonCredsCredential = credential as? AnonCredsCredential {
            let legacyOptions = LegacyToW3cCredentialOptions(
                credential: anonCredsCredential,
                issuerId: credDef.issuerId,
                processOptions: ProcessOptions(
                    credentialDefinition: credDef,
                    credentialRequestMetadata: credReqMetadata,
                    revocationRegistryDefinition: revocationRegistry?.definition
                )
            )

            w3cCredential = try await legacyToW3cCredential(options: legacyOptions)
        } else {
            throw CredoError("error storing credential")
        }

        let storeOptions = StoreCredentialW3cOptions(
            credential: w3cCredential,
            credentialDefinitionId: credDefId,
            schema: schema,
            schemaId: options.schemaId,
            credentialDefinition: credDef,
            revocationRegistryDefinition: revocationRegistry?.definition,
            revocationRegistryId: revocationRegistry?.id,
            credentialRequestMetadata: credReqMetadata
        )

        let record = try await storeW3cCredential(options: storeOptions)
        return record.id
    }

    public func legacyToW3cCredential(options: LegacyToW3cCredentialOptions) async throws -> W3cJsonLdVerifiableCredential {
        let anonCredsCredential = options.credential
        let issuerId = options.issuerId
        let processOptions = options.processOptions

        let jsonEncoder = JSONEncoder()
        let credentialData = try jsonEncoder.encode(anonCredsCredential)
        guard let credentialJson = String(data: credentialData, encoding: .utf8) else {
            throw CredoError("serialization error")
        }

        let credential = try anoncreds_uniffi.Credential(json: credentialJson)

        let converter = anoncreds_uniffi.CredentialConversions()
        let w3cString = try converter.credentialToW3cJson(credential: credential, issuerIdString: issuerId, versionString: "1.1")

        let w3cCredential = try anoncreds_uniffi.W3cCredential(json: w3cString)
        var jsonLdVC = try convertToW3cJsonLd(w3cCredential: w3cCredential,
                                              credentialW3cStr: w3cString)

        if let options = processOptions {
            jsonLdVC = try await processW3cCredential(
                w3cCredential: w3cCredential,
                crew3cJsonLdVC: jsonLdVC,
                processOptions: options
            )
        }

        return jsonLdVC
    }

    public func createProof(options: CreateProofOptions) async throws -> AnonCredsProof {
        let requestMessage = options.requestMessage
        let proofRequest = options.proofRequest
        let proofFormats = options.proofFormats
        let selectedCredentials = options.selectedCredentials
        let credentialDefinitions = options.credentialDefinitions
        let schemas = options.schemas

        var rsCredentialDefinitions = [String: anoncreds_uniffi.CredentialDefinition]()
        var rsSchemas = [String: anoncreds_uniffi.Schema]()
        var retrievedCredentials = [String: Any]()

        // Credential Definitions
        for (credDefId, credDef) in credentialDefinitions.credentialDefinitions {
            let jsonString = try credDef.toJson()
            rsCredentialDefinitions[credDefId] = try anoncreds_uniffi.CredentialDefinition(json: jsonString)
        }

        // Schemas
        for (schemaId, schema) in schemas.schemas {
            let json = try schema.toJson()
            rsSchemas[schemaId] = try anoncreds_uniffi.Schema(json: json)
        }

        // Helpers
        let getCredentialId: (Any) -> String = { attribute in
            if let attr = attribute as? AnonCredsRequestedAttributeMatch {
                return attr.credentialId
            } else if let pred = attribute as? AnonCredsRequestedPredicateMatch {
                return pred.credentialId
            } else {
                fatalError("Unexpected type: \(type(of: attribute))")
            }
        }

        let getTimestamp: (Any) -> UInt64? = { attribute in
            if let attr = attribute as? AnonCredsRequestedAttributeMatch {
                return attr.timestamp
            } else if let pred = attribute as? AnonCredsRequestedPredicateMatch {
                return pred.timestamp
            } else {
                fatalError("Unexpected type: \(type(of: attribute))")
            }
        }

        func credentialEntryFromAttribute(from attribute: Any) async throws -> CredentialEntryResult {
            
            let credentialId = getCredentialId(attribute)
            var record = retrievedCredentials[credentialId]

            if record == nil {
                if let w3c = try await agent.w3cCredentialRepository.findById(credentialId) {
                    retrievedCredentials[credentialId] = w3c
                    record = w3c
                } else {
                    let legacy = try await agent.anonCredsCredentialRepository.getByCredentialId(credentialId)
                    retrievedCredentials[credentialId] = legacy
                    record = legacy
                }
            }

            let proofUsesUnqualified = ProofRequestOperations.proofRequestUsesUnqualifiedIdentifiers(proofRequest: proofRequest)

            let info : AnonCredsCredentialInfo = try getAnoncredsCredentialInfoFromRecord(
                            record!,
                            useUnqualifiedIdentifiersIfPresent: proofUsesUnqualified)

            let timestamp = getTimestamp(attribute)
            var revocationState: CredentialRevocationState? = nil

            if let ts = timestamp,
               let credentialRevocationId = info.credentialRevocationId,
               let revocationRegistryId = info.revocationRegistryId {

                guard let registryData = options.revocationRegistries[revocationRegistryId] else {
                    throw AnonCredsRsError("Revocation Registry \(revocationRegistryId) not found")
                }

                let definition: AnonCredsRevocationRegistryDefinition = registryData.definition
                guard let revocationStatusLists = registryData.revocationStatusLists as? [UInt64: AnonCredsRevocationStatusList] else {
                    fatalError("revocationStatusLists missing")
                }

                guard let statusList = revocationStatusLists[ts] else {
                    throw CredoError(
                        "Revocation status list for registry \(revocationRegistryId) and timestamp \(ts) not found"
                    )
                }
                
                let tag = definition.tag
                
                let valueJsonData = try JSONEncoder().encode(definition.value)
                let valueJson = try JSONSerialization.jsonObject(with: valueJsonData) as? [String: Any]
                
                guard let valueJson = valueJson else {
                    throw CredoError("Failed to convert registry definition value to JSON")
                }


                let jsonDict: [String: Any?] = [
                    "credDefId": definition.credDefId,
                    "revRegDefId": revocationRegistryId,
                    "tag": definition.tag,
                    "value": valueJson,
                    "issuerId": definition.issuerId,
                    "revocDefType": definition.revocDefType
                ]

                let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
                    guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                        throw CredoError("Failed to encode revocation registry JSON")
                    }
                                
                let revocationRegistryDefinition = try RevocationRegistryDefinition(json: jsonString)

                let revocationStatusListJson = try statusList.toJson()
                let statusListUniffi = try anoncreds_uniffi.RevocationStatusList(json:revocationStatusListJson)

                let tailsFile = URL(fileURLWithPath: registryData.tailsFilePath)
                    .appendingPathComponent(registryData.tailsHash!)
                guard FileManager.default.fileExists(atPath: tailsFile.path) else {
                    fatalError("Tails file not found at \(tailsFile.path)")
                }
                logDebug("tails file: \(tailsFile.path)")

                revocationState = try Prover().createOrUpdateRevocationState(
                    revRegDef: revocationRegistryDefinition,
                    revStatusList: statusListUniffi,
                    revRegIdx: UInt32(credentialRevocationId) ?? 0,
                    tailsPath: tailsFile.path,
                    revState: nil,
                    oldRevStatusList: nil
                )
            }

            let credential: Any

            if let w3cRecord = record as? W3cCredentialRecord {
                credential = try W3cUtils.getCredentialUniffiByW3cCredentialRecord(w3cRecord)
            } else if let acRecord = record as? AnonCredsCredentialRecord {
                credential = acRecord.credential
            } else {
                fatalError("Unexpected credential record type: \(type(of: record))")
            }

            let credJsonElement: Any
            
            if let uniffiCred = credential as? anoncreds_uniffi.Credential {
                            
                let jsonString = uniffiCred.toJson()
                var json = try JSONSerialization.jsonObject(
                    with: Data(jsonString.utf8),
                    options: []
                ) as! [String: Any]
                
                if proofUsesUnqualified {
                    json["schema_id"] = info.schemaId
                    json["cred_def_id"] = info.credentialDefinitionId
                    json["rev_reg_id"] = info.revocationRegistryId
                }
                
                credJsonElement = json
                
            } else if let legacyCred = credential as? AnonCredsCredential {
                
                let jsonString = try legacyCred.toJson()
                var json = try JSONSerialization.jsonObject(
                    with: Data(jsonString.utf8),
                    options: []
                ) as! [String: Any]
                
                if proofUsesUnqualified {
                    json["schema_id"] = info.schemaId
                    json["cred_def_id"] = info.credentialDefinitionId
                    json["rev_reg_id"] = info.revocationRegistryId
                }
                
                credJsonElement = json
                
            } else {
                fatalError("Tipo de credential desconhecido.")
            }

//            var revocationStateJsonElement: JsonElement? = nil
//            if let revState = revocationState {
//                revocationStateJsonElement = Json.parseToJsonElement(revState.toJson())
//            }

            return CredentialEntryResult(
                linkSecretId: info.linkSecretId,
                credentialEntry: CredentialEntry(
                    credential: AnyCodable(credJsonElement),
                    timestamp: timestamp,
                    revocationState: AnyCodable(revocationState?.toJson())
                ),
                credentialId: credentialId
            )
        }

        let requestedCredentials = try RequestedCredentialsAnoncreds.mapToRequestedCredentials(from:proofFormats!)

        var anoncredsCreds = [RequestedCredential]()
        let credentialIds = requestedCredentials.getCredentialIdentifiers()

        var schemaIds = Set<String>()
        var credentialDefinitionIds = Set<String>()

        for id in credentialIds {
            let record = try await agent.w3cCredentialRepository.getById(id)
            let cred = try W3cUtils.getCredentialUniffiByW3cCredentialRecord(record)

            schemaIds.insert(cred.schemaId())
            credentialDefinitionIds.insert(cred.credDefId())

            var requestedAttributes = [String: Bool]()
            var requestedPredicates = [String]()
            var timestamp: Int? = nil

            for (referent, attr) in requestedCredentials.requestedAttributes {
                if attr.credentialId == id {
                    requestedAttributes[referent] = attr.revealed
                    if let t = attr.timestamp {
                        timestamp = max(t, timestamp ?? 0)
                    }
                }
            }

            for (referent, pred) in requestedCredentials.requestedPredicates {
                if pred.credentialId == id {
                    requestedPredicates.append(referent)
                    if let t = pred.timestamp {
                        timestamp = max(t, timestamp ?? 0)
                    }
                }
            }

            var revocationState: CredentialRevocationState?
            if let ts = timestamp {
                revocationState = try await agent.revocationService.createRevocationState(
                    credential: cred,
                    timestamp: ts
                )
            } else {
                revocationState = nil
            }

            anoncredsCreds.append(
                RequestedCredential(
                    cred: cred,
                    timestamp: timestamp.map { UInt64($0) },
                    revState: revocationState,
                    requestedAttributes: requestedAttributes,
                    requestedPredicates: requestedPredicates
                )
            )
        }

        var credentials = [CredentialEntryResult]()
        var credentialsProve = [CredentialProve]()
        var entryIndex = 0

        // Attributes
        for (referent, attribute) in selectedCredentials.attributes {
            if let existingIndex = credentials.firstIndex(where: {
                $0.credentialId == attribute.credentialId &&
                $0.credentialEntry.timestamp == attribute.timestamp
            }) {
                credentialsProve.append(
                    CredentialProve(
                        entryIndex: existingIndex,
                        referent: referent,
                        isPredicate: false,
                        reveal: attribute.revealed
                    )
                )
            } else {
                let entry = try await credentialEntryFromAttribute(from: attribute)
                credentials.append(entry)

                credentialsProve.append(
                    CredentialProve(
                        entryIndex: entryIndex,
                        referent: referent,
                        isPredicate: false,
                        reveal: attribute.revealed
                    )
                )
                entryIndex += 1
            }
        }

        // Predicates
        for (referent, predicate) in selectedCredentials.predicates {
            if let existingIndex = credentials.firstIndex(where: {
                $0.credentialId == predicate.credentialId &&
                $0.credentialEntry.timestamp == predicate.timestamp
            }) {
                credentialsProve.append(
                    CredentialProve(
                        entryIndex: existingIndex,
                        referent: referent,
                        isPredicate: true,
                        reveal: true
                    )
                )
            } else {
                let entry = try await credentialEntryFromAttribute(from: predicate)
                credentials.append(entry)

                credentialsProve.append(
                    CredentialProve(
                        entryIndex: entryIndex,
                        referent: referent,
                        isPredicate: true,
                        reveal: true
                    )
                )
                entryIndex += 1
            }
        }

        let linkSecretIds = credentials.map { $0.linkSecretId }
        let linkSecretId = try assertLinkSecretsMatch(linkSecretIds: linkSecretIds)
        let linkSecret = try await agent.anoncredsService.getLinkSecret(id: linkSecretId)

        let anoncredsRequest = try requestMessage.anoncredsProofRequest()
        let presentationRequest = try anoncreds_uniffi.PresentationRequest(json: anoncredsRequest)

        let presentation = try Prover().createPresentation(
            presReq: presentationRequest,
            requestedCredentials: anoncredsCreds,
            selfAttestedAttributes: nil,
            linkSecret: linkSecret,
            schemas: rsSchemas,
            credDefs: rsCredentialDefinitions
        )

        return try JSONDecoder().decode(AnonCredsProof.self, from: presentation.toJson().data(using: .utf8)!)
    }
    
    
    
    private func sanitizeProofRequestToString(_ raw: [String: Any]) -> String? {
        var sanitized = raw

        if var requestedAttributes = sanitized["requested_attributes"] as? [String: Any] {
            for (key, value) in requestedAttributes {
                guard var attrDict = value as? [String: Any],
                      var restrictions = attrDict["restrictions"] as? [[String: Any]] else { continue }

                restrictions = restrictions.map { restriction in
                    var cleaned = restriction
                    cleaned.removeValue(forKey: "attributeValues")
                    cleaned.removeValue(forKey: "attributeMarkers")
                    return cleaned
                }

                attrDict["restrictions"] = restrictions
                requestedAttributes[key] = attrDict
            }

            sanitized["requested_attributes"] = requestedAttributes
        }

        sanitized["name"] = sanitized["name"] ?? "proof request"
        sanitized["nonce"] = sanitized["nonce"] ?? UUID().uuidString.prefix(18)
        sanitized["version"] = sanitized["version"] ?? "1.0"
        sanitized["requested_predicates"] = sanitized["requested_predicates"] ?? [:]

        do {
            let data = try JSONSerialization.data(withJSONObject: sanitized, options: [.prettyPrinted])
            if let jsonString = String(data: data, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print("❌ Error convert proof request to JSON: \(error)")
        }

        return nil
    }
    
    private func assertLinkSecretsMatch(linkSecretIds: [String]) throws -> String {
        guard !linkSecretIds.isEmpty else {
            throw NSError(domain: "LinkSecretError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No link secret ids provided"])
        }

        let distinct = Array(Set(linkSecretIds))
        if distinct.count > 1 {
            throw NSError(domain: "LinkSecretError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Multiple different link secret ids found: \(linkSecretIds)"])
        }

        return distinct.first!
    }
    
    fileprivate func filterValidCredentials(_ credentials: [W3cCredentialRecord], _ attributesList: [String]) -> [W3cCredentialRecord] {
        return credentials.filter { rec in
            let tags = rec.getTags()
            let tagKeys = Set(tags.keys)
            let requiredKeys = Set(attributesList)
            
            let missingKeys = requiredKeys.subtracting(tagKeys)
            
            if missingKeys.isEmpty {
                logDebug("✅ Credential \(rec.id) has all required keys")
                return true
            } else {
                logDebug("❌ Credential \(rec.id) has missing keys: \(Array(missingKeys))")
                return false
            }
        }
    }
    
    public func getCredentialsForProofRequest(options: GetCredentialsForProofRequestOptions) async throws -> GetCredentialsForProofRequestReturn {
        let proofRequest = options.proofRequest
        let referent = options.attributeReferent

        guard let requestedAttribute = proofRequest.requestedAttributes[referent]
            ?? proofRequest.requestedPredicates[referent]?.asAnonCredsRequestedAttribute()
        else {
            throw NSError(domain: "ProofError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Referent not found in proof request"])
        }

        let useUnqualifiedIdentifiers = ProofRequestOperations.proofRequestUsesUnqualifiedIdentifiers(proofRequest: proofRequest)

        if requestedAttribute.names == nil && requestedAttribute.name == nil {
            throw NSError(domain: "ProofRequestError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Proof request attribute must have either name or names"])
        }

        if requestedAttribute.names != nil && requestedAttribute.name != nil {
            throw NSError(domain: "ProofRequestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Proof request attribute cannot have both name and names"])
        }

        let attributesList: [String] = (requestedAttribute.names ?? [requestedAttribute.name!])
            .map { "anonCredsAttr::\($0)::value" }

        var tags: [String: String] = [:]
        if let restrictions = requestedAttribute.restrictions {
            tags = queryFromRestrictions(restrictions)
        }

        var jsontags = try tags.toJsonString()
        var credentials: [W3cCredentialRecord] = []

        if let tagsJson = try? tags.toJsonString() {
            credentials = try await agent.w3cCredentialRepository.findByQuery(tagsJson) ?? []
        }

        if let credentialW3cId = options.chosenCredentialId {
            let specificCredential = try await agent.w3cCredentialRepository.getById(credentialW3cId)
            credentials = [specificCredential]
        }

        let filteredCredentials = filterValidCredentials(credentials, attributesList)

        let legacyCredentials = try await getLegacyCredentialsForProofRequest(options: options).credentials

        if !legacyCredentials.isEmpty {
            print("⚠️ Including legacy credentials in proof request. Please migrate to the new W3C format.")
        }

        let credentialWithMetadata: [CredentialForProofRequest] = try filteredCredentials.map { credentialRecord in
            CredentialForProofRequest(
                credentialInfo: try getAnoncredsCredentialInfoFromRecord(
                    credentialRecord,
                    useUnqualifiedIdentifiersIfPresent: useUnqualifiedIdentifiers),
                interval: proofRequest.nonRevoked
            )
        }
        print("sizes: \(credentialWithMetadata + legacyCredentials)")
        return GetCredentialsForProofRequestReturn(credentials: credentialWithMetadata + legacyCredentials)
    }
    
    func convertToW3cJsonLd(w3cCredential: anoncreds_uniffi.W3cCredential, credentialW3cStr: String) throws -> W3cJsonLdVerifiableCredential {
        print("w3cCredential: \(w3cCredential.toJson())")

        var element = try JSONSerialization.jsonObject(with: Data(w3cCredential.toJson().utf8), options: []) as! [String: Any]
        print("element: \(element)")

        if let subject = element["credentialSubject"], !(subject is [Any]) {
            element["credentialSubject"] = [subject]
        }

        if let typeValue = element["type"], !(typeValue is [Any]) {
            element["type"] = [typeValue]
        }

        let normalizedData = try JSONSerialization.data(withJSONObject: element, options: [])
        let normalizedJson = String(data: normalizedData, encoding: .utf8)!

        print("normalized: \(normalizedJson)")

        let vc = try W3cJsonLdVerifiableCredential.fromJson(normalizedJson)
        print("w3cJsonLdVerifiableCredential: \(vc)")

        return vc
    }
    
    func processW3cCredential(
        w3cCredential: anoncreds_uniffi.W3cCredential,
        crew3cJsonLdVC: W3cJsonLdVerifiableCredential,
        processOptions: ProcessOptions
    ) async throws -> W3cJsonLdVerifiableCredential {

        let credentialDefinition = processOptions.credentialDefinition
        let credentialRequestMetadata = processOptions.credentialRequestMetadata
        let revocationRegistryDefinition = processOptions.revocationRegistryDefinition
        
        let processCredentialOptions = ProcessCredentialOptions(
            credentialRequestMetadata: credentialRequestMetadata,
            linkSecret: agent.wallet.linkSecretId!,
            revocationRegistryDefinition: revocationRegistryDefinition,
            credentialDefinition: credentialDefinition
        )

        let credentialDefinitionJson = try credentialDefinition.toJson()

        let credentialDefinitionUniffi = try CredentialDefinition(json: credentialDefinitionJson)

        let jsonData = try JSONEncoder().encode(credentialRequestMetadata)
        var cleaned = String(data: jsonData, encoding: .utf8) ?? ""
        cleaned = cleaned.replacingOccurrences(of: "\\\"", with: "")

        let credentialRequestMetadataUniffi = try CredentialRequestMetadata(json: cleaned)

        var revocationRegistryDefinitionUniffi: RevocationRegistryDefinition? = nil
        if let revRegDef = revocationRegistryDefinition {
            let jsonData = try JSONEncoder().encode(revRegDef)
            let json = String(data: jsonData, encoding: .utf8)!
            revocationRegistryDefinitionUniffi = try RevocationRegistryDefinition(json: json)
        }

        let linkSecret = try await agent.anoncredsService.getLinkSecret(id: processCredentialOptions.linkSecret)

        let processed = try W3cProcess().processCredential(
            cred: w3cCredential,
            credReqMetadata: credentialRequestMetadataUniffi,
            linkSecret: linkSecret,
            credDef: credentialDefinitionUniffi,
            revRegDef: revocationRegistryDefinitionUniffi
        )

        return try convertToW3cJsonLd(w3cCredential: processed, credentialW3cStr: processed.toJson())
    }
    
    func storeW3cCredential(options: StoreCredentialW3cOptions) async throws -> W3cCredentialRecord {
        logDebug("storeW3cCredential")
        let credential = options.credential as W3cJsonLdVerifiableCredential
//        let credentialDefinitionId: String = options.credentialDefinitionId
        //let schema: AnonCredsSchema = options.schema
        let schemaId: String? = options.schemaId
//        let credentialDefinition: AnonCredsCredentialDefinition = options.credentialDefinition
//        let revocationRegistryId: String? = options.revocationRegistryId
//        let credentialRequestMetadata: AnonCredsCredentialRequestMetadata =
//                    options.credentialRequestMetadata
        
        let issuer = credential.issuer //revisar aqui
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]

        var jsonData = try JSONEncoder().encode(credential)
        var encoded = String(data: jsonData, encoding: .utf8)!
        encoded = encoded.replacingOccurrences(of: "\\\"", with: "")
        let regex = try NSRegularExpression(pattern: #""credentialSubject"\s*:\s*\[(\{.*?\})\]"#, options: [])
        encoded = regex.stringByReplacingMatches(in: encoded, options: [], range: NSRange(location: 0, length: encoded.utf16.count), withTemplate: "\"credentialSubject\": $1")

        var credentialUniffi : anoncreds_uniffi.Credential
        
        var credentialW3cStr = ""
        do{
            credentialUniffi = try CredentialConversions().credentialFromW3cJson(w3cCredentialJson:encoded)
            credentialW3cStr = try CredentialConversions().credentialToW3cJson(
                credential: credentialUniffi,
                issuerIdString: "did:sov:\(issuer)",
                versionString: "1.1"
            )
        }catch{
            print("error: \(error)")
            throw CredoError(
                "error"
            )
        }

        let w3cCredential = try anoncreds_uniffi.W3cCredential(json: credentialW3cStr)

        if credential.credentialSubject.count > 1 {
            throw NSError(domain: "CredoError", code: 100, userInfo: [NSLocalizedDescriptionKey: "Credential subject must be an object, not an array."])
        }

        let registry : AnonCredsRegistry = try agent.anonCredsRegistryService.getRegistryForIdentifier(for: schemaId!)
        let methodName = registry.methodName

        let tags = try W3cAnonCredsUtils.getW3cRecordAnonCredsTags(
            credentialSubject: credential.credentialSubject.first!,
            issuerId: issuer.description,
            schemaId: options.credentialDefinition.schemaId,
            schema: options.schema,
            credentialDefinitionId: options.credentialDefinitionId,
            revocationRegistryId: options.revocationRegistryId,
            credentialRevocationId: credentialUniffi.revRegIndex()?.description,
            linkSecretId: options.credentialRequestMetadata.linkSecretName,
            methodName: methodName
        )

        var record = try await agent.w3cCredentialService.storeCredentialW3cJsonLdVerifiableCredential(jsonLdVerifiableCredential: credential)
        record.setTags(tags)

        let metadata = W3cAnonCredsCredentialMetadata(
            methodName: tags["anonCredsMethodName"] ?? "not informed",
            credentialRevocationId: tags["anonCredsCredentialRevocationId"],
            linkSecretId: tags["anonCredsLinkSecretId"]?.replacingOccurrences(of: "\"", with: "") ?? ""
        )

        let metadataData = try JSONEncoder().encode(metadata)
        let metadataJsonObject = try JSONSerialization.jsonObject(with: metadataData, options: []) as? [String: Any]

        record.metadata[MetadataKeys.w3cAnonCredsCredentialMetadataKey] = AnyCodable(metadataJsonObject)
        
        try await agent.w3cCredentialRepository.update(record)
        return record
    }
    
    public func getCredential(
        credentialId: String,
        useUnqualifiedIdentifiersIfPresent: Bool? = nil
    ) async throws -> AnonCredsCredentialInfo {
        if let w3cCredentialRecord = try await agent.w3cCredentialRepository.findById(credentialId) {
            return try getAnoncredsCredentialInfoFromRecord(
                w3cCredentialRecord,
                useUnqualifiedIdentifiersIfPresent: useUnqualifiedIdentifiersIfPresent
            )
        }

        let legacyRecord = try await agent.anonCredsCredentialRepository.getByCredentialId(credentialId)

        print("⚠️ Querying legacy credential repository for credential with id \(credentialId). Please run the migration script to migrate credentials to the new W3C format.")

        return try getAnoncredsCredentialInfoFromRecord(legacyRecord)
    }
    
    public func createCredentialRequest(options: CreateCredentialHolderRequestOptions) async throws -> CreateCredentialRequestReturn {
        let useLegacyProverDid = options.useLegacyProverDid ?? false
        let credDef = options.credentialDefinition
        let credOffer = options.credentialOffer
        let linkSecretId = options.linkSecretId!

        let isLegacyIdentifier = IndyIdentifiers.isUnqualifiedCredentialDefinitionId(credOffer.credDefId)

        if !isLegacyIdentifier && useLegacyProverDid {
            throw CredoError("Cannot use legacy prover_did with non-legacy identifiers")
        }

        let entropy = (!useLegacyProverDid && !isLegacyIdentifier) ? try Verifier().generateNonce() : nil
        let nonce = try Verifier().generateNonce().prefix(16)
        let proverDid: String? = useLegacyProverDid
            ? Base58.encode(Array(String(nonce).utf8))
            : nil

        let linkSecret = try await agent.anoncredsService.getLinkSecret(id: linkSecretId)

        let credentialRequestTuple = try Prover().createCredentialRequest(
            entropy: entropy,
            proverDid: proverDid,
            credDef: anoncreds_uniffi.CredentialDefinition(json: credDef),
            linkSecret: linkSecret,
            linkSecretId: linkSecretId,
            credOffer: CredentialOffer(json: credOffer.toJsonString())
        )

        let credentialRequest = try AnonCredsCredentialRequest.fromJsonString(credentialRequestTuple.request.toJson())
        let credentialRequestMetadata = try AnonCredsCredentialRequestMetadata.fromJsonString(credentialRequestTuple.metadata.toJson())

        return CreateCredentialRequestReturn(
            credentialRequest: credentialRequest,
            credentialRequestMetadata: credentialRequestMetadata
        )
    }
    
    public func deleteCredential(credentialId: String) async throws {
        if let record = try await agent.w3cCredentialRepository.findById(credentialId) {
            try await agent.w3cCredentialRepository.delete(record)
            return
        }

        let legacyRecord = try await agent.anonCredsCredentialRepository.getByCredentialId(credentialId)
        try await agent.anonCredsCredentialRepository.delete(legacyRecord)
    }
    
    public func createLinkSecret(options: CreateLinkSecretOptions? = nil) async throws -> CreateLinkSecretReturn {
        return CreateLinkSecretReturn(
            linkSecretId: options?.linkSecretId ?? RecordUtils.generateId(),
            linkSecret: try anoncreds_uniffi.createLinkSecret()
        )
    }
    
    func storeLinkSecret(options: StoreLinkSecretOptions) async throws -> AnonCredsLinkSecretRecord {
        let linkSecretId = options.linkSecretId
        let linkSecretValue = options.linkSecretValue
        let setAsDefault = options.setAsDefault
        
        let newRecord = AnonCredsLinkSecretRecord(linkSecretId: linkSecretId, value: linkSecretValue)

        if let currentDefault = try await agent.anonCredsLinkSecretRepository.findDefault() {
            if setAsDefault {
                currentDefault.setTag(key: "isDefault", value: "false")
                try await agent.anonCredsLinkSecretRepository.update(currentDefault)
            }
        }

        let isDefaultMissing = try await agent.anonCredsLinkSecretRepository.findDefault() == nil

        if setAsDefault || isDefaultMissing {
            newRecord.setTag(key: "isDefault", value: "true")
        }

        try await agent.anonCredsLinkSecretRepository.save(newRecord)
        return newRecord
    }
    
    public func generateNonce() -> String {
        var bytes = [UInt8](repeating: 0, count: 10)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        let nonce = bytes.reduce(BigUInt(0)) { (result, byte) in
            (result << 8) | BigUInt(byte)
        }

        return nonce.description
    }
    
    func getAnoncredsCredentialInfoFromRecord(
        _ record: Any,
        useUnqualifiedIdentifiersIfPresent: Bool? = nil
    ) throws -> AnonCredsCredentialInfo {
        if let decoded = record as? W3cCredentialRecord {
            return try W3cAnonCredsUtils.anonCredsCredentialInfoFromW3cRecord(
                w3cCredentialRecord: decoded,
                useUnqualifiedIdentifiers: useUnqualifiedIdentifiersIfPresent
            )
        }

        if let decoded = record as? AnonCredsCredentialRecord {
            return W3cAnonCredsUtils.anonCredsCredentialInfoFromAnonCredsRecord(
                anonCredsCredentialRecord: decoded
            )
        }

        fatalError("Unsupported record type: \(type(of: record))")
    }
    
    func queryFromRestrictions(_ restrictions: [AnonCredsProofRequestRestriction]) -> [String: String] {
        var queries: [[String: String]] = []

        for restriction in restrictions {
            var q: [String: String] = [:]

            if let credDefId = restriction.credDefId {
                let key = IndyIdentifiers.isUnqualifiedCredentialDefinitionId(credDefId)
                    ? "anonCredsUnqualifiedCredentialDefinitionId"
                    : "anonCredsCredentialDefinitionId"
                q[key] = credDefId
            }

            if let issuer = restriction.issuerId ?? restriction.issuerDid {
                let key = IndyIdentifiers.isUnqualifiedIndyDid(issuer)
                    ? "anonCredsUnqualifiedIssuerId"
                    : "issuerId"
                q[key] = issuer
            }

            if let schemaId = restriction.schemaId {
                let key = IndyIdentifiers.isUnqualifiedSchemaId(schemaId)
                    ? "anonCredsUnqualifiedSchemaId"
                    : "anonCredsSchemaId"
                q[key] = schemaId
            }

            if let schemaIssuer = restriction.schemaIssuerId ?? restriction.schemaIssuerDid {
                let key = IndyIdentifiers.isUnqualifiedIndyDid(schemaIssuer)
                    ? "anonCredsUnqualifiedSchemaIssuerId"
                    : "anonCredsSchemaIssuerId"
                q[key] = schemaIssuer
            }

            if let schemaName = restriction.schemaName {
                q["anonCredsSchemaName"] = schemaName
            }

            if let schemaVersion = restriction.schemaVersion {
                q["anonCredsSchemaVersion"] = schemaVersion
            }

            for (attrName, attrValue) in restriction.attributeValues {
                q["anonCredsAttr::\(attrName)::value"] = attrValue
            }

            for (attrName, isAvailable) in restriction.attributeMarkers where isAvailable {
                q["anonCredsAttr::\(attrName)::marker"] = "true"
            }

            queries.append(q)
        }

        return queries.first ?? [:]
    }
    
    func getLegacyCredentialsForProofRequest(
        options: GetCredentialsForProofRequestOptions
    ) async throws -> GetCredentialsForProofRequestReturn {
        let proofRequest = options.proofRequest
        let referent = options.attributeReferent as String

        let requestedAttribute : AnonCredsRequestedAttribute? = proofRequest.requestedAttributes[referent]
        let requestedPredicate : AnonCredsRequestedPredicate? = proofRequest.requestedPredicates[referent]
        
        if(requestedAttribute == nil && requestedPredicate == nil){
            throw AnonCredsRsError("Referent not found in proof request")
        }

        var andClauses: [[String: Any?]] = []

        var attributes: [String] = []
        if (requestedAttribute != nil){
            attributes = requestedAttribute?.names ?? [requestedAttribute?.name].compactMap { $0 }
        }else if(requestedPredicate != nil){
            attributes = [requestedPredicate?.name].compactMap { $0 }
        }else{
            fatalError("Unexpected type for requested attribute")
        }

        var attributeQuery: [String: Any?] = [:]
        for attr in attributes {
            attributeQuery["anonCredsAttr::\(attr)::marker"] = "true"
        }
        if !attributeQuery.isEmpty {
            andClauses.append(attributeQuery)
        }
        

        // restrictions
        if let attr = requestedAttribute,
           let restrictions = attr.restrictions,
           !restrictions.isEmpty {
            let restrictionQuery = queryLegacyFromRestrictions(restrictions: restrictions)
            if !restrictionQuery.isEmpty {
                andClauses.append(restrictionQuery)
            }
        }

        if let pred = requestedPredicate,
           let restrictions = pred.restrictions,
           !restrictions.isEmpty {
            let restrictionQuery = queryLegacyFromRestrictions(restrictions: restrictions)
            if !restrictionQuery.isEmpty {
                andClauses.append(restrictionQuery)
            }
        }

        if let extra = options.extraQuery,
           !extra.referents.isEmpty {
            andClauses.append(extra.referents)
        }

        let finalQuery: [String: Any?]
        if andClauses.count == 1 {
            finalQuery = andClauses.first!
        } else {
            finalQuery = ["$and": andClauses]
        }
        
        logDebug("final query: \(finalQuery)")
        
        let jsonData = try JSONSerialization.data(withJSONObject: finalQuery, options: [])
        let jsonString = String(data: jsonData, encoding: .utf8)!

        let credentials = await agent.anonCredsCredentialRepository.findByQuery(jsonString)

        let credentialForProofRequestList: [CredentialForProofRequest] = try credentials.map {
            CredentialForProofRequest(
                credentialInfo: try getAnoncredsCredentialInfoFromRecord($0),
                interval: proofRequest.nonRevoked
            )
        }

        return GetCredentialsForProofRequestReturn(credentials: credentialForProofRequestList)
    }
    
    func queryLegacyFromRestrictions(restrictions: [AnonCredsProofRequestRestriction]) -> [String: Any?] {
        var queries: [[String: Any?]] = []

        for restriction in restrictions {
            var queryElements: [String: Any?] = [:]
            var additionalQueryElements: [String: Any?] = [:]

            // credDefId
            if let credDefId = restriction.credDefId {
                queryElements["credentialDefinitionId"] = credDefId
                if IndyIdentifiers.isUnqualifiedCredentialDefinitionId(credDefId) {
                    additionalQueryElements["credentialDefinitionId"] = credDefId
                }
            }

            // issuerId
            if let issuerId = restriction.issuerId ?? restriction.issuerDid {
                queryElements["issuerId"] = issuerId
                if IndyIdentifiers.isUnqualifiedIndyDid(issuerId) {
                    additionalQueryElements["issuerId"] = issuerId
                }
            }

            // schemaId
            if let schemaId = restriction.schemaId {
                queryElements["schemaId"] = schemaId
                if IndyIdentifiers.isUnqualifiedSchemaId(schemaId) {
                    additionalQueryElements["schemaId"] = schemaId
                }
            }

            // schemaIssuerId
            if let schemaIssuerId = restriction.schemaIssuerId ?? restriction.schemaIssuerDid {
                queryElements["schemaIssuerId"] = schemaIssuerId
                if IndyIdentifiers.isUnqualifiedIndyDid(schemaIssuerId) {
                    additionalQueryElements["schemaIssuerId"] = schemaIssuerId
                }
            }

            // schemaName, schemaVersion
            if let schemaName = restriction.schemaName {
                queryElements["schemaName"] = schemaName
            }
            if let schemaVersion = restriction.schemaVersion {
                queryElements["schemaVersion"] = schemaVersion
            }

            // attributeValues
            for (attrName, attrValue) in restriction.attributeValues {
                queryElements["attr::\(attrName)::value"] = attrValue
            }

            // attributeMarkers
            for (attrName, isAvailable) in restriction.attributeMarkers where isAvailable {
                queryElements["attr::\(attrName)::marker"] = true
            }

            queries.append(queryElements)
            if !additionalQueryElements.isEmpty {
                queries.append(additionalQueryElements)
            }
        }

        return queries.count == 1 ? queries[0] : ["$or": queries]
    }
}
