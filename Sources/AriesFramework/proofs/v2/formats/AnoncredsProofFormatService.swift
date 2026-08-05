//
//  AnoncredsProofFormatService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation
import os
import AnyCodable
import Anoncreds

public class AnoncredsProofFormatService: ProofFormatService {
    
    private let logger = Logger(subsystem: "org.hyperledger.ariesframework", category: "AnoncredsProofFormatService")
    public let formatKey: String
    public let agent: Agent
    
    public init(agent: Agent) {
        self.formatKey = "anoncreds"
        self.agent = agent
    }
    
    public static let ANONCREDS_PRESENTATION_PROPOSAL = "anoncreds/proof-request@v1.0"
    public static let ANONCREDS_PRESENTATION_REQUEST = "anoncreds/proof-request@v1.0"
    public static let ANONCREDS_PRESENTATION = "anoncreds/proof@v1.0"

    
    public func createProposal(
        profRecord: ProofExchangeRecord,
        attachmentId: String?,
        proofFormats: [String: AnyCodable]
    ) async throws -> ProofFormatCreateReturn {
        
        guard let attachmentId = attachmentId else {
            throw AriesFrameworkError.frameworkError("Attachment ID is required")
        }

        let format = ProofFormatSpec(
            attachmentId: attachmentId,
            format: AnoncredsProofFormatService.ANONCREDS_PRESENTATION_PROPOSAL
        )

        let anoncredsFormat: AnonCredsProposeProofFormat = try FormatGeneric.getAnonCredsFormatGeneric(from: proofFormats)

        let proofRequest = try createRequestFromPreview(
            name: anoncredsFormat.name ?? "Proof request",
            version: anoncredsFormat.version ?? "1.0",
            nonce: agent.anonCredsHolderService.generateNonce(),
            attributes: anoncredsFormat.attributes ?? [],
            predicates: anoncredsFormat.predicates ?? [],
            nonRevokedInterval: anoncredsFormat.nonRevokedInterval
        )

        let attachment = try self.getFormatData(
            proofRequest,
            id: format.attachmentId ?? "not informed")

        return ProofFormatCreateReturn(
            format: format,
            attachment: attachment
        )
    }

    public func processProposal(
        attachment: Attachment,
        proofRecord: ProofExchangeRecord
    ) async throws {
        let jsonString = try attachment.getDataAsString()
        let proposalJson = try JSONDecoder().decode(AnonCredsProofRequest.self, from: Data(jsonString.utf8))
        
        try DuplicateNames.assertNoDuplicateGroupsNamesInProofRequest(proposalJson)
    }

    public func acceptProposal(
        proofRecord: ProofExchangeRecord,
        attachmentId: String?,
        proposalAttachment: Attachment,
        proofFormats: [String: AnyCodable]
    ) async throws -> ProofFormatCreateReturn{
        
        let format = ProofFormatSpec(
            attachmentId: attachmentId ?? UUID().uuidString,
            format: AnoncredsProofFormatService.ANONCREDS_PRESENTATION_REQUEST
        )
        
        let proposalJsonString = try proposalAttachment.getDataAsString()
        let proposalJson = try JSONDecoder().decode(AnonCredsProofRequest.self, from: Data(proposalJsonString.utf8))

        let updatedRequest = proposalJson.copyWith(
            nonce: agent.anonCredsHolderService.generateNonce()
        )
        
        let attachment = try getFormatData(updatedRequest, id: format.attachmentId ?? "not informed")

        return ProofFormatCreateReturn(
            format: format,
            attachment: attachment
        )
    }
    public func createRequest(
        proofRecord: ProofExchangeRecord,
        attachmentId: String?,
        proofFormats: [String: AnyCodable]
    ) async throws -> ProofFormatCreateReturn{
        logDebug("createRequest in anoncredsproof format service")

       let format = ProofFormatSpec(
            attachmentId: attachmentId,
            format: AnoncredsProofFormatService.ANONCREDS_PRESENTATION_REQUEST
       )

       logDebug("format: \(format.format)")
        let anoncredsFormatNormalized = try normalizeProofFormats(proofFormats)
        
        let request : AnonCredsProofRequest = try createRequestFromPreview(
            name: anoncredsFormatNormalized.name ?? "Proof request",
            version: anoncredsFormatNormalized.version ?? "1.0",
            nonce: agent.anonCredsHolderService.generateNonce(),
            attributes: anoncredsFormatNormalized.attributes ?? [],
            predicates: anoncredsFormatNormalized.predicates ?? [],
            nonRevokedInterval: anoncredsFormatNormalized.nonRevokedInterval
        )

    
        try DuplicateNames.assertNoDuplicateGroupsNamesInProofRequest(request)

        let jsonData = try JSONEncoder().encode(request)
        let attachment = Attachment(
            id: format.attachmentId!,
            mimetype: "application/json",
            data: AttachmentData(base64: jsonData.base64EncodedString())
        )

        return ProofFormatCreateReturn(
            format: format,
            attachment: attachment,
        )
    }
    
    func normalizeProofFormats(_ proofFormats: [String: AnyCodable]) throws -> AnonCredsProposeProofFormat {

        guard let anoncredsRaw = proofFormats["anoncreds"]?.value as? [String: Any] else {
            throw NSError(domain: "ProofFormat", code: 400, userInfo: [NSLocalizedDescriptionKey: "Anoncreds format not found"])
        }

        var normalizedAnoncreds = anoncredsRaw
        
        if var globalNonRevoked = normalizedAnoncreds["non_revoked"] as? [String: Any] {
                
            if let from = globalNonRevoked["from"] {
                if let intFrom = from as? Int64 {
                    globalNonRevoked["from"] = intFrom
                } else if let stringFrom = from as? String, let intFrom = Int64(stringFrom) {
                    globalNonRevoked["from"] = intFrom
                }
            }

            if let to = globalNonRevoked["to"] {
                if let intTo = to as? Int64 {
                    globalNonRevoked["to"] = intTo
                } else if let stringTo = to as? String, let intTo = Int64(stringTo) {
                    globalNonRevoked["to"] = intTo
                }
            }

            normalizedAnoncreds["non_revoked"] = globalNonRevoked
        }

        if var requestedAttributes = normalizedAnoncreds["requested_attributes"] as? [String: Any] {
            for (key, value) in requestedAttributes {
                guard var attrDict = value as? [String: Any] else { continue }
                if let restrictions = attrDict["restrictions"] as? [[String: Any]] {
                    if let firstRestriction = restrictions.first {
                        if let anyCodable = firstRestriction["cred_def_id"] as? AnyCodable,
                           let credDefId = anyCodable.value as? String {
                            attrDict["credentialDefinitionId"] = credDefId
                        }
                    }
                }

                attrDict.removeValue(forKey: "restrictions")

                requestedAttributes[key] = attrDict
            }

            normalizedAnoncreds["requested_attributes"] = requestedAttributes
            normalizedAnoncreds["attributes"] = requestedAttributes.values.map { $0 }
        }
        
        if var requestedPredicates = normalizedAnoncreds["requested_predicates"] as? [String: Any] {
            for (key, value) in requestedPredicates {
                guard var predDict = value as? [String: Any] else { continue }

                if let type = predDict["p_type"] as? String {
                    predDict["p_type"] = type.trimmingCharacters(in: .whitespaces)
                }

                if let value = predDict["p_value"] as? String, let intValue = Int64(value) {
                    predDict["p_value"] = intValue
                }

                if let restrictions = predDict["restrictions"] as? [[String: Any]],
                   let firstRestriction = restrictions.first,
                   let anyCodable = firstRestriction["cred_def_id"] as? AnyCodable,
                   let credDefId = anyCodable.value as? String {
                    predDict["credentialDefinitionId"] = credDefId
                }

                predDict.removeValue(forKey: "restrictions")

                requestedPredicates[key] = predDict
            }

            normalizedAnoncreds["requested_predicates"] = requestedPredicates
            normalizedAnoncreds["predicates"] = requestedPredicates.values.map { $0 }
        }

        let cleaned = jsonCompatible(normalizedAnoncreds)
        let data = try JSONSerialization.data(withJSONObject: cleaned, options: [])
        return try JSONDecoder().decode(AnonCredsProposeProofFormat.self, from: data)
    }
    
    func jsonCompatible(_ object: Any) -> Any {
        if let anyCodable = object as? AnyCodable {
            return jsonCompatible(anyCodable.value)
        } else if let dict = object as? [String: Any] {
            return dict.mapValues { jsonCompatible($0) }
        } else if let array = object as? [Any] {
            return array.map { jsonCompatible($0) }
        } else if object is NSNull || object is String || object is NSNumber {
            return object
        } else {
            return String(describing: object)
        }
    }

    public func processRequest(
        options: ProofFormatProcessOptions
    ) async throws {
    
        logDebug("in processRequest")
        let attachment = options.attachment

        let jsonString = try attachment.getDataAsString()
        logDebug("in jsonString: \(jsonString)")
        let anonCredsProofRequest :AnonCredsProofRequest? = try JSONDecoder().decode(AnonCredsProofRequest.self, from: Data(jsonString.utf8))
        logDebug("in requestJson: \(String(describing: anonCredsProofRequest))")
        
        
        let verifierRecord = VerifierRecord(
            proofRequest: anonCredsProofRequest,
            globalThreadId: options.proofRecord.threadId
        )
        try await agent.verifierRepository.save(verifierRecord)
        print("💾 Salvo verifier id=\(verifierRecord.id) threadid=\(verifierRecord.globalThreadId ?? "nil")")
        
        try DuplicateNames.assertNoDuplicateGroupsNamesInProofRequest(anonCredsProofRequest!)
    }

    public func acceptRequest(
        requestMessage: RequestPresentationMessageV2,
        proofRecord: ProofExchangeRecord,
        proofFormats: [String: AnyCodable],
        attachmentId: String,
        requestAttachment: Attachment,
        proposalAttachment: Attachment?,
        chosenCredentialId: String? = nil
    ) async throws -> ProofFormatCreateReturn {
        
        let jsonString = try requestAttachment.getDataAsString()
        let requestJson = try JSONDecoder().decode(AnonCredsProofRequest.self, from: Data(jsonString.utf8))
        logDebug(" AnonCredsProofRequest: \(requestJson)")
        
        let anoncredsSelected = try await _selectCredentialsForRequest(
            proofRequest: requestJson,
            chosenCredentialId: chosenCredentialId,
            options: AnonCredsGetCredentialsForProofRequestOptions(
                filterByNonRevocationRequirements: true
            )
        )
        
        try await validateCredentialChosen(chosenCredentialId: chosenCredentialId, proofRequest: requestJson)

        let anoncredsFormat = try AnonCredsSelectedCredentials.convert(from: proofFormats)
        logDebug("anoncredsFormat: \(anoncredsFormat)")
        for item in anoncredsFormat.attributes.values {
            print("item::::: \(item.credentialId)")
            print("item::::: \(item.revealed)")
            print("item::::: \(item.credentialInfo.toJsonElement())")
        }
        
        let selectedCredentials = anoncredsFormat ?? anoncredsSelected

        let format = ProofFormatSpec(
            attachmentId: attachmentId,
            format: AnoncredsProofFormatService.ANONCREDS_PRESENTATION
        )

        let proof = try await createProof(
            requestMessage: requestMessage,
            proofRequest: requestJson,
            selectedCredentials: anoncredsSelected,
            proofFormats: proofFormats
        )

        let proofData = try JSONEncoder().encode(proof)
        let base64Encoded = proofData.base64EncodedString()

        let attachment = Attachment(
            id: attachmentId,
            mimetype: "application/json",
            data: AttachmentData(base64: base64Encoded)
        )

        return ProofFormatCreateReturn(
            format: format,
            attachment: attachment
        )
    }
    
    private func validateCredentialChosen(
        chosenCredentialId: String?,
        proofRequest: AnonCredsProofRequest
    ) async throws {

        guard let chosenCredentialId = chosenCredentialId, !chosenCredentialId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CredoError("No credential was selected.")
        }

        let credential: CredentialExchangeRecord =
            try await agent.credentialExchangeRepository.getByW3cCredentialId(chosenCredentialId)

        let recordAttrs: [String: String] = credential.credentialAttributes?
            .reduce(into: [String: String]()) { acc, attr in
                acc[attr.name] = attr.value
            } ?? [:]

        let credDefId = credential.credentialDefinitionId

        let requestedAttrNames: Set<String> = Set(
            proofRequest.requestedAttributes.values.flatMap { $0.names ?? [] }
        )

        let missingAttrs = requestedAttrNames.filter { recordAttrs[$0] == nil }

        if !missingAttrs.isEmpty {
            throw CredoError(
                "The selected credential does not contain the required attributes: \(missingAttrs)"
            )
        }

        let requestedCredDefIds: Set<String> = Set(
            proofRequest.requestedAttributes.values.compactMap {
                $0.restrictions?.first?.credDefId
            }
        )

        if !requestedCredDefIds.isEmpty,
           let credDefId = credDefId,
           !requestedCredDefIds.contains(credDefId) {

            throw CredoError(
                "The selected credential has an unexpected credentialDefinitionId. " +
                "Expected: \(requestedCredDefIds) | Found: \(credDefId)"
            )
        }

        try validateLocalRevocationStatus(credential: credential, proofRequest: proofRequest)

        let predicates = proofRequest.requestedPredicates.values

        for predicate in predicates {
            let attrName = predicate.name

            guard let rawValue = recordAttrs[attrName] else {
                throw CredoError(
                    "The credential does not contain the required attribute for predicate: \(attrName)"
                )
            }

            guard let attrValue = Int(rawValue) else {
                throw CredoError(
                    "The attribute '\(attrName)' is not numeric, making predicate validation impossible."
                )
            }

            let satisfied: Bool

            switch predicate.pType {
            case .GreaterThanOrEqualTo:
                satisfied = attrValue >= predicate.pValue
            case .GreaterThan:
                satisfied = attrValue > predicate.pValue
            case .LessThanOrEqualTo:
                satisfied = attrValue <= predicate.pValue
            case .LessThan:
                satisfied = attrValue < predicate.pValue
            default:
                satisfied = false
            }

            if !satisfied {
                throw CredoError(
                    "Predicate failed for attribute '\(attrName)'. " +
                    "Value: \(attrValue) | Rule: \(predicate.pType) \(predicate.pValue)"
                )
            }
        }
    }

    private func validateLocalRevocationStatus(
        credential: CredentialExchangeRecord,
        proofRequest: AnonCredsProofRequest
    ) throws {
        guard let revocationDate = credential.revocationNotification?.revocationDate else {
            return
        }

        let intervals = revocationIntervals(from: proofRequest)
        guard !intervals.isEmpty else {
            return
        }

        let revocationTimestamp = UInt64(revocationDate.timeIntervalSince1970)

        for interval in intervals {
            let to = interval.to ?? UInt64(Date().timeIntervalSince1970)
            if revocationTimestamp <= to {
                throw CredoError("The selected credential was revoked within the requested non-revocation interval.")
            }
        }
    }

    private func revocationIntervals(from proofRequest: AnonCredsProofRequest) -> [AnonCredsNonRevokedInterval] {
        var intervals: [AnonCredsNonRevokedInterval] = []

        if let global = proofRequest.nonRevoked {
            intervals.append(global)
        }

        intervals.append(contentsOf: proofRequest.requestedAttributes.values.compactMap { $0.nonRevoked })
        intervals.append(contentsOf: proofRequest.requestedPredicates.values.compactMap { $0.nonRevoked })

        return intervals
    }

    public func processPresentation(
        requestAttachment: Attachment,
        presentationAttachment: Attachment,
        proofRecord: inout ProofExchangeRecord,
        presentationMessage: PresentationMessageV2,
        requestMessage: RequestPresentationMessageV2,
    ) async throws -> Bool {
        
        
        let jsonStringRequest = try requestAttachment.getDataAsJson()
        guard let jsonData = jsonStringRequest.data(using: .utf8) else {
            throw CredoError("Unable to convert the JSON String to Data.")
        }

        let requestJson = try JSONDecoder().decode(
            AnonCredsProofRequest.self,
            from: jsonData
        )
        
        logDebug("request json: \(jsonStringRequest)")

        
        let jsonStringProof = try presentationAttachment.getDataAsJson()
        guard let jsonDataProof = jsonStringProof.data(using: .utf8) else {
            throw CredoError("Unable to convert the JSON String to Data.")
        }

        let anonCredsProof : AnonCredsProof = try JSONDecoder().decode(
            AnonCredsProof.self,
            from: jsonDataProof
        )
        
        logDebug("anonCredsProof: \(jsonStringProof)")
        
        
        try AnonCredsEncoder.checkEncodes(anonCredsProof: anonCredsProof)

        let schemaIds = Set(anonCredsProof.identifiers.map { $0.schemaId })
        let schemasMap = try await agent.ledgerService.getSchemas(schemaIds: schemaIds)
        let schemas = AnonCredsSchemas(schemas: schemasMap)
        logDebug("schemas: \(schemas.schemas)")

        let credDefIds = Set(anonCredsProof.identifiers.map { $0.credDefId })
        let credentialDefinitionsMap = try await ProofUtils.getCredentialDefinitions(agent: agent, credentialDefinitionIds: credDefIds)
        logDebug("credentialDefinitionsMap: \(credentialDefinitionsMap)")

        let credentialDefinitionUniffiMap = try await convert(input: credentialDefinitionsMap)
        logDebug("credentialDefinitionUniffiMap: \(credentialDefinitionUniffiMap)")

        
        let revocationRegistries : [String: RevocationRegistryEntry] =
            (try? await RevocationRegistries(agent: agent)
                .getRevocationRegistriesForProof(proof: anonCredsProof)) ?? [:]

        
        let anonCredsCredentialDefinitions = AnonCredsCredentialDefinitions(
            credentialDefinitions: credentialDefinitionsMap
        )
        logDebug("anonCredsCredentialDefinitions: \(anonCredsCredentialDefinitions.credentialDefinitions)")

       
        var isVerified = false
        do{
            isVerified = try await agent.anoncredsVerifierService.verifyProof(
                options: VerifyProofOptions(
                    proofRequest: requestJson,
                    presentationMessage: presentationMessage,
                    requestMessage: requestMessage,
                    proof: anonCredsProof,
                    schemas: schemas,
                    credentialDefinitions: anonCredsCredentialDefinitions,
                    revocationRegistries: revocationRegistries,
                )
            )
        }catch{
            logDebug("Error: \(error)")
        }
        
        
        proofRecord.isVerified = isVerified
                    
        return isVerified
    
    }
    
    private func getRevocationRegistriesForProof(proof: AnonCredsProof){
        
    }

    public func getCredentialsForRequest(
        proofRecord: ProofExchangeRecord,
        proofFormats: [String: AnyCodable],
        requestAttachment: Attachment,
        proposalAttachment: Attachment?
    ) async throws -> AnonCredsCredentialsForProofRequest {
        
        let requestJsonString = try requestAttachment.getDataAsJson()
        print("requestJsonString: \(requestJsonString)")
        let proofRequest = try JSONDecoder().decode(AnonCredsProofRequest.self, from: Data(requestJsonString.utf8))

        let anoncredsFormat: AnonCredsSelectedCredentials? = try FormatGeneric.getAnonCredsFormatGeneric(
            from: proofFormats
        )
        
        let options = AnonCredsGetCredentialsForProofRequestOptions(
            filterByNonRevocationRequirements: true
        )

        let anonCredsCredentialsForProofRequest = try await GetCredentialsForProofRequestReferent
            .getCredentialsForAnonCredsProofRequest(
                agent: agent,
                proofRequest: proofRequest,
                options: options
            )

        return anonCredsCredentialsForProofRequest
    }

    public func selectCredentialsForRequest(
        proofRecord: ProofExchangeRecord,
        proofFormats: [String: AnyCodable],
        requestAttachment: Attachment,
        proposalAttachment: Attachment?
    ) async throws -> AnonCredsSelectedCredentials {

        let jsonString = try requestAttachment.getDataAsJson()
        let proofRequest = try JSONDecoder().decode(AnonCredsProofRequest.self, from: Data(jsonString.utf8))
        let anoncredsFormat: AnonCredsSelectedCredentials? = try FormatGeneric.getAnonCredsFormatGeneric(
            from: proofFormats
        )
        let options = AnonCredsGetCredentialsForProofRequestOptions(
            filterByNonRevocationRequirements: true
        )

        let selectedCredentials = try await _selectCredentialsForRequest(
            proofRequest: proofRequest,
            options: options
        )

        return selectedCredentials
    }

    public func shouldAutoRespondToProposal(
        proofRecord: ProofExchangeRecord,
        proposalAttachment: Attachment,
        requestAttachment: Attachment
    ) async throws -> Bool {
        let proposalJsonString = try proposalAttachment.getDataAsJson()
        let requestJsonString = try requestAttachment.getDataAsJson()

        let decoder = JSONDecoder()
        let proposalJson = try decoder.decode(AnonCredsProofRequest.self, from: Data(proposalJsonString.utf8))
        let requestJson = try decoder.decode(AnonCredsProofRequest.self, from: Data(requestJsonString.utf8))

        let areRequestsEqual = RequestsEquals.areAnonCredsProofRequestsEqual(
            proposalJson,
            requestJson
        )

        logDebug("AnonCreds request and proposal are equal: \(areRequestsEqual) > proposal: \(proposalJson) || request: \(requestJson)")

        return areRequestsEqual
    }

    public func shouldAutoRespondToRequest(
        proofRecord: ProofExchangeRecord,
        requestAttachment: Attachment,
        proposalAttachment: Attachment
    ) async throws -> Bool {
        let proposalJsonString = try proposalAttachment.getDataAsJson()
        let requestJsonString = try requestAttachment.getDataAsJson()

        let decoder = JSONDecoder()
        let proposalJson = try decoder.decode(AnonCredsProofRequest.self, from: Data(proposalJsonString.utf8))
        let requestJson = try decoder.decode(AnonCredsProofRequest.self, from: Data(requestJsonString.utf8))

        return RequestsEquals.areAnonCredsProofRequestsEqual(proposalJson, requestJson)
    }

    public func shouldAutoRespondToPresentation(
        proofRecord: ProofExchangeRecord,
        proposalAttachment: Attachment?,
        requestAttachment: Attachment,
        presentationAttachment: Attachment
    ) async throws -> Bool{
        return true
    }

    public func supportsFormat(formatIdentifier: String) -> Bool{
        let supportedFormats = [
            AnoncredsProofFormatService.ANONCREDS_PRESENTATION_PROPOSAL,
            AnoncredsProofFormatService.ANONCREDS_PRESENTATION_REQUEST,
            AnoncredsProofFormatService.ANONCREDS_PRESENTATION
        ]
        return supportedFormats.contains(formatIdentifier)
    }
    
    /* auxiliar functions */
    private func getFormatData<T: Encodable>(_ data: T, id: String) throws -> Attachment {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(data)
        let base64String = jsonData.base64EncodedString()

        let attachmentData = AttachmentData(base64: base64String)

        return Attachment(
            id: id,
            mimetype: "application/json",
            data: attachmentData
        )
    }
    
    private func createRequestFromPreview(
        name: String,
        version: String,
        nonce: String,
        attributes: [AnonCredsPresentationPreviewAttribute] = [],
        predicates: [AnonCredsPresentationPreviewPredicate] = [],
        nonRevokedInterval: AnonCredsNonRevokedInterval? = nil
    ) throws -> AnonCredsProofRequest {
        
        var attributesByReferent: [String: [AnonCredsPresentationPreviewAttribute]] = [:]
        for attr in attributes {
            let referent = attr.referent ?? attr.name
            attributesByReferent[referent, default: []].append(attr)
        }

        var requestedAttributes: [String: AnonCredsRequestedAttribute] = [:]
        for (referent, props) in attributesByReferent {
            let attributeName = props.count == 1 ? props[0].name : nil
            let attributeNames = props.count > 1 ? props.map { $0.name } : nil

            requestedAttributes[referent] = AnonCredsRequestedAttribute(
                name: attributeName,
                names: attributeNames,
                restrictions: [AnonCredsProofRequestRestriction(credDefId: props.first?.credentialDefinitionId)],
                nonRevoked: nil
            )
        }

        var requestedPredicates: [String: AnonCredsRequestedPredicate] = [:]
        for pred in predicates {
            let restrictions = [
                AnonCredsProofRequestRestriction(credDefId: pred.credentialDefinitionId)
            ]

            requestedPredicates[pred.name] = AnonCredsRequestedPredicate(
                name: pred.name,
                pType: try PredicateType.fromString(pred.predicateType),
                pValue: pred.threshold,
                restrictions: restrictions,
                nonRevoked: nil
            )
        }

        return AnonCredsProofRequest(
            name: name,
            version: version,
            nonce: nonce,
            requestedAttributes: requestedAttributes,
            requestedPredicates: requestedPredicates,
            nonRevoked: nonRevokedInterval
        )
    }
    
    private func _selectCredentialsForRequest(
        proofRequest: AnonCredsProofRequest,
        chosenCredentialId: String? = nil,
        options: AnonCredsGetCredentialsForProofRequestOptions
    ) async throws -> AnonCredsSelectedCredentials {

        
        let credentialsForRequest = try await GetCredentialsForProofRequestReferent.getCredentialsForAnonCredsProofRequest(
                agent: agent,
                proofRequest: proofRequest,
                chosenCredentialId: chosenCredentialId,
                options: options)

        var selectedAttributes: [String: AnonCredsRequestedAttributeMatch] = [:]
        var selectedPredicates: [String: AnonCredsRequestedPredicateMatch] = [:]

        for (name, matches) in credentialsForRequest.attributes {
            guard let first = matches.first else {
                throw AriesFrameworkError.frameworkError(options.filterByNonRevocationRequirements == true ? "No non-revoked credential found for the requested attribute (\(name)). Make sure there is a valid, active credential with this attribute." : "No credential found for the requested attribute (\(name)). Make sure the credential was issued and contains this attribute.")
            }
            selectedAttributes[name] = first
        }

        for (name, matches) in credentialsForRequest.predicates {
            guard let first = matches.first else {
                throw AriesFrameworkError.frameworkError(options.filterByNonRevocationRequirements == true ? "No non-revoked credential found that satisfies the requested predicate (\(name)). Make sure there is a valid, active credential matching the predicate." : "No credential found that satisfies the requested predicate (\(name)).")
            }
            selectedPredicates[name] = first
        }

        return AnonCredsSelectedCredentials(
            attributes: selectedAttributes,
            predicates: selectedPredicates,
            selfAttestedAttributes: [:]
        )
    }
    
    func createProof(
        requestMessage: RequestPresentationMessageV2,
        proofRequest: AnonCredsProofRequest,
        selectedCredentials: AnonCredsSelectedCredentials,
        proofFormats: [String: AnyCodable]? = nil
    ) async throws -> AnonCredsProof {
        
        let attributeValues = selectedCredentials.attributes.values.map { $0 as Any }
        let predicateValues = selectedCredentials.predicates.values.map { $0 as Any }
        let selectedEntries: [Any] = attributeValues + predicateValues

        let credentialObjects: [AnonCredsCredentialInfo] = try await withThrowingTaskGroup(of: AnonCredsCredentialInfo.self) { group in
            for entry in selectedEntries {
                group.addTask {
                    let credentialId: String
                    if let attr = entry as? AnonCredsRequestedAttributeMatch {
                        credentialId = attr.credentialId
                    } else if let pred = entry as? AnonCredsRequestedPredicateMatch {
                        credentialId = pred.credentialId
                    } else {
                        throw CredoError("invalidType of proof")
                    }

                    return try await self.agent.anonCredsHolderService.getCredential(
                        credentialId: credentialId,
                        useUnqualifiedIdentifiersIfPresent: ProofRequestOperations.proofRequestUsesUnqualifiedIdentifiers(proofRequest: proofRequest)
                    )
                }
            }

            return try await group.reduce(into: []) { $0.append($1) }
        }

        let schemaIds = Set(credentialObjects.map { $0.schemaId })
        let credDefIds = Set(credentialObjects.map { $0.credentialDefinitionId })

        let schemas = try await ProofUtils.getSchemas(agent: agent, schemaIds: schemaIds)
        let credentialDefinitions = try await ProofUtils.getCredentialDefinitions(agent: agent, credentialDefinitionIds: credDefIds)
        
        let revocationAnoncredsRegistries : RevocationAnoncredsRegistries = try await getRevocationRegistries(proofRequest: proofRequest, selectedCredentials: selectedCredentials)

        let anonCredsSchema = AnonCredsSchemas(schemas: schemas)
        let anonCredsCredentialDefinitions = AnonCredsCredentialDefinitions(credentialDefinitions: credentialDefinitions)

        
        let proof =  try await agent.anonCredsHolderService.createProof(
            options: CreateProofOptions(
                requestMessage: requestMessage,
                proofRequest: proofRequest,
                selectedCredentials: revocationAnoncredsRegistries.updatedSelectedCredentials,
                schemas: anonCredsSchema,
                credentialDefinitions: anonCredsCredentialDefinitions,
                revocationRegistries: revocationAnoncredsRegistries.registries,
                proofFormats: proofFormats
            )
        )
        
        return proof
    }
    
    private func getRevocationRegistries(proofRequest: AnonCredsProofRequest,
                                         selectedCredentials: AnonCredsSelectedCredentials
    ) async throws -> RevocationAnoncredsRegistries {
        let revocationResult : RevocationRegistriesForRequestResult = try await RevocationRegistries(agent: agent).getRevocationRegistriesForRequest(
            proofRequest: proofRequest,
            selectedCredentials: selectedCredentials
        )
    
        let updatedSelectedCredentials = revocationResult.updatedSelectedCredentials
        let revocationRegistries = revocationResult.revocationRegistries

        var anonCredsRevocationRegistries: [String: AnonCredsRevocationRegistryEntry] = [:]

        for (key, value) in revocationRegistries {
            let jsonString = value.definition.value

            guard let jsonData = jsonString.data(using: .utf8) else {
                throw CredoError("Failed to convert JsonValue to Data")
            }

            let revRegValue = try JSONDecoder().decode(RevocationRegistryValue.self, from: jsonData)

            let registryDefinition : AnonCredsRevocationRegistryDefinition = AnonCredsRevocationRegistryDefinition(
                issuerId: value.definition.issuerId,
                revocDefType: value.definition.revocDefType,
                credDefId: value.definition.credDefId,
                tag: value.definition.tag,
                value: revRegValue
            )

            let statusLists = value.revocationStatusLists?.reduce(
                into: [UInt64: AnonCredsRevocationStatusList]()
            ) { acc, entry in
                guard entry.key >= 0 else { return }
                acc[UInt64(entry.key)] = AnonCredsRevocationStatusList.fromRevocationStatusList(entry.value)
            } ?? [:]

            anonCredsRevocationRegistries[key] = AnonCredsRevocationRegistryEntry(
                tailsFilePath: try await agent.ledgerService.getTailsPath(),
                tailsHash: value.tailsHash,
                definition: registryDefinition,
                revocationStatusLists: statusLists
            )
        }
        
        return RevocationAnoncredsRegistries(
            registries: anonCredsRevocationRegistries,
            updatedSelectedCredentials: updatedSelectedCredentials
        )
        
    }
    
    private func checkValidCredentialValueEncoding(raw: Any, encoded: String) -> Bool {
        return encoded == AnonCredsEncoder.encodeCredentialValue(raw)
    }
    
    private func convert(input: [String: AnonCredsCredentialDefinition]) async throws -> [String: CredentialDefinition] {
        var result: [String: CredentialDefinition] = [:]

        for (credDefId, _) in input {
            let credDef = try await agent.ledgerService.getCredentialDefinition(id: credDefId)
            result[credDefId] = try CredentialDefinition(json: credDef)
        }

        return result
    }
    
}
