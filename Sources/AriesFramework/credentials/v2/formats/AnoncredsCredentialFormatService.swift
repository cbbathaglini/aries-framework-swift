//
//  AnoncredsCredentialFormatService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//
import Foundation
import os
import AnyCodable
import Anoncreds


public class AnoncredsCredentialFormatService: CredentialFormatService {
    
    private let logger = Logger(subsystem: "org.hyperledger.ariesframework", category: "AnoncredsCredentialFormatService")
    public let formatKey: String
    public let credentialRecordType: String
    public let agent: Agent

    public init(agent: Agent) {
        self.formatKey = "anoncreds"
        self.credentialRecordType = "w3c"
        self.agent = agent
    }
    
    static let ANONCREDS_CREDENTIAL_OFFER = "anoncreds/credential-offer@v1.0"
    static let ANONCREDS_CREDENTIAL_REQUEST = "anoncreds/credential-request@v1.0"
    static let ANONCREDS_CREDENTIAL_FILTER = "anoncreds/credential-filter@v1.0"
    static let ANONCREDS_CREDENTIAL = "anoncreds/credential@v1.0"
    
    /**
     * Create a {@link AttachmentFormats} object dependent on the message type.
     *
     * @param options The object containing all the options for the proposed credential
     * @returns object containing associated attachment, format and optionally the credential preview
     *
     */
    public func createProposal(
            credentialFormats: [String: Any]?,
            credentialExchangeRecord: CredentialExchangeRecord
        ) async throws -> CredentialFormatCreateProposalReturn {
        let format = Format(format: AnoncredsCredentialFormatService.ANONCREDS_CREDENTIAL_FILTER)
        
        let credentialExchangeRecord = credentialExchangeRecord
        logDebug("credentialFormats------- \(String(describing: credentialFormats))")
        
        guard let anoncredsFormat: AnonCredsProposeCredentialFormat =
               try FormatGeneric.getAnonCredsFormatGeneric(from: credentialFormats) else {
            throw CredoError("Invalid credential format")
        }
        
        let proposal = AnonCredsCredentialProposal(
            schemaIssuerDid: anoncredsFormat.schemaIssuerDid,
            schemaIssuerId: anoncredsFormat.schemaIssuerId,
            schemaId: anoncredsFormat.schemaId,
            schemaName: anoncredsFormat.schemaName,
            schemaVersion: anoncredsFormat.schemaVersion,
            credentialDefinitionId: anoncredsFormat.credentialDefinitionId,
            issuerDid: anoncredsFormat.issuerDid,
            issuerId: anoncredsFormat.issuerId
        )
        
        do {
            try MessageValidator.validateSync(proposal)
        } catch {
            throw CredoError("Invalid proposal supplied: \(proposal) in AnonCredsFormatService")
        }
        

        let attachment = try FormatDataUtil.getFormatData(
            proposal,
            id: format.attachId)
        
        let credentialLinkedAttachmentsResult = try FormatDataUtil.getCredentialLinkedAttachments(
            attributes: anoncredsFormat.attributes,
            linkedAttachments: anoncredsFormat.linkedAttachments
        )
        
        let metadata = AnonCredsCredentialMetadata(
            schemaId: proposal.schemaId,
            credentialDefinitionId: proposal.credentialDefinitionId
        )
        
      
        let encodedMetadata = try JSONEncoder().encode(metadata)
        let json = try JSONSerialization.jsonObject(with: encodedMetadata, options: [])
        if let jsonValue = json as? [String: Any] {
            for (key, value) in jsonValue {
                credentialExchangeRecord.metadata[key] = value as! AnyCodable
            }
        } else {
            credentialExchangeRecord.metadata[MetadataKeys.anonCredsCredentialMetadataKey] = json as! AnyCodable
        }
        
        return CredentialFormatCreateProposalReturn(
            format: format,
            attachment: attachment,
            previewAttribute: credentialLinkedAttachmentsResult.previewAttributes
        )
    }
    
    
    public func processProposal(
            attachment: Attachment,
            credentialRecord: CredentialExchangeRecord
    ) async throws{
        let proposal: AnonCredsCredentialProposal = try FormatDataUtil.parseAttachmentData(attachment, as: AnonCredsCredentialProposal.self)
        logDebug("Processed proposal schemaid: \(proposal)")
    }
   
    public func acceptProposal(
        attachmentId: String?,
        credentialFormats: [String: Any]?,
        credentialRecord: CredentialExchangeRecord,
        proposalAttachments: Attachment
    ) async throws -> CredentialFormatCreateOfferReturn {

       let anoncredsFormat: AnoncredsCredentialFormat = try FormatGeneric.getAnonCredsFormatGeneric(from: credentialFormats)
        
       let proposalJson = try proposalAttachments.getDataAsJson()
       let proposalFormat = try JSONDecoder().decode(AnonCredsCredentialProposalFormat.self, from: Data(proposalJson.utf8))

       let credentialDefinitionId = anoncredsFormat.credentialDefinitionId ?? proposalFormat.credDefId
       let attributes = anoncredsFormat.attributes ?? credentialRecord.credentialAttributes

       guard let credentialDefinitionId else {
           throw CredoError("No credential definition id in proposal or provided as input to accept proposal method.")
       }

       guard let attributes else {
           throw CredoError("No attributes in proposal or provided as input to accept proposal method.")
       }

       let createAnoncredsOffer = CreateAnoncredsOffer(
           credentialExchangeRecord: credentialRecord,
           attachmentId: attachmentId,
           attributes: attributes,
           credentialDefinitionId: credentialDefinitionId,
           revocationRegistryDefinitionId: anoncredsFormat.revocationRegistryDefinitionId,
           revocationRegistryIndex: anoncredsFormat.revocationRegistryIndex,
           linkedAttachments: anoncredsFormat.linkedAttachments
       )

       let credentialFormatCreateOfferReturn = try await createAnonCredsOffer(createAnoncredsOffer)

       return CredentialFormatCreateOfferReturn(
           attachment: credentialFormatCreateOfferReturn.attachment,
           format: credentialFormatCreateOfferReturn.format,
           previewAttributes: credentialFormatCreateOfferReturn.previewAttributes
       )
    }
    
    
    public func createOffer(
        credentialFormats: [String: Any]?,
        credentialExchangeRecord: CredentialExchangeRecord,
        attachmentId: String?
    ) async throws -> CredentialFormatCreateOfferReturn {
        

        let anoncredsFormat: AnoncredsCredentialFormat = try FormatGeneric.getAnonCredsFormatGeneric(from: credentialFormats)

        let createAnoncredsOffer = CreateAnoncredsOffer(
            credentialExchangeRecord: credentialExchangeRecord,
            attachmentId: attachmentId,
            attributes: anoncredsFormat.attributes,
            credentialDefinitionId: anoncredsFormat.credentialDefinitionId,
            revocationRegistryDefinitionId: anoncredsFormat.revocationRegistryDefinitionId,
            revocationRegistryIndex: anoncredsFormat.revocationRegistryIndex,
            linkedAttachments: anoncredsFormat.linkedAttachments
        )

        let credentialFormatCreateOfferReturn = try await createAnonCredsOffer(createAnoncredsOffer)

        return CredentialFormatCreateOfferReturn(
            attachment: credentialFormatCreateOfferReturn.attachment,
            format: credentialFormatCreateOfferReturn.format,
            previewAttributes: credentialFormatCreateOfferReturn.previewAttributes
        )
    }
    
    public func processOffer(
        attachment: Attachment,
        credentialExchangeRecord: CredentialExchangeRecord
    ) async throws {

        let offer = try AnonCredsCredentialOffer.fromAttachment(attachment)

        if offer.schemaId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            offer.credDefId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ProblemReportError(
                message: "Invalid credential offer",
                problemCode: CredentialProblemReportReason.issuanceAbandoned.rawValue
            )
        }
    }
    
    public func acceptOffer(
        attachment: Attachment,
        credentialExchangeRecord: CredentialExchangeRecord,
        credentialFormats: [Format]?,
        attachmentId: String?,
        offerCredentialMessageV2: OfferCredentialMessageV2
    ) async throws -> CredentialFormatCreateReturn{
        
        logDebug("Processing anoncreds credential offer for credential record \(credentialExchangeRecord.id)")

        let credentialExchangeRecord = credentialExchangeRecord
        let offer = try AnonCredsCredentialOffer.fromAttachment(attachment)

        guard !offer.schemaId.isEmpty, !offer.credDefId.isEmpty else {
            throw ProblemReportError(
                message: "Invalid credential offer",
                problemCode: CredentialProblemReportReason.issuanceAbandoned.rawValue
            )
        }

        let credentialOfferJson = try offerCredentialMessageV2.getCredentialOfferAttach(attachment.id)
        let credentialOffer = try CredentialOffer(json: credentialOfferJson)

        let cd = try await agent.ledgerService.getCredentialDefinition(id: offer.credDefId)
        
        let credentialDefinitionJson = cd.replacingOccurrences(of: "\\\"", with: "\"")

        let linkSecret = try await agent.anoncredsService.getLinkSecret(id: agent.wallet.linkSecretId!)

        let credentialDefinitionUniffi: CredentialDefinition
        do {
            credentialDefinitionUniffi = try CredentialDefinition(json: credentialDefinitionJson)
        } catch {
            //logger.error("error anoncred uniffi: \(error.localizedDescription)")
            throw error
        }

        let entropy = try Verifier().generateNonce()

        let credReqTuple: CredentialRequestTuple
        do {
    
            credReqTuple = try Prover().createCredentialRequest(
                entropy: entropy,
                proverDid: nil,
                credDef: credentialDefinitionUniffi,
                linkSecret: linkSecret,
                linkSecretId: agent.wallet.linkSecretId!,
                credOffer: credentialOffer
            )
        } catch {
            //logger.error("error --->>>>> : \(error.localizedDescription)")
            throw error
        }


        do {
            let credentialRequestTupleJsonElement = try convertJsonStringToJsonObject(credReqTuple.metadata.toJson())
            credentialExchangeRecord.metadata[MetadataKeys.anonCredsCredentialRequestMetadataKey] = credentialRequestTupleJsonElement
            
            let encodedMetadata = try JSONEncoder().encode(AnonCredsCredentialMetadata(
                schemaId: offer.schemaId,
                credentialDefinitionId: offer.credDefId
            ))
            
            let anonCredsCredentialMetadataJson = try JSONSerialization.jsonObject(with: encodedMetadata, options: [])
            credentialExchangeRecord.metadata[MetadataKeys.anonCredsCredentialMetadataKey] = AnyCodable(anonCredsCredentialMetadataJson)
            
        } catch {
            throw CredoError("Error converting to JsonElement: \(error)")
        }
        
    

        let format = Format(
            attachId: attachmentId ?? CredentialExchangeRecord.generateId(),
            format: AnoncredsCredentialFormatService.ANONCREDS_CREDENTIAL_REQUEST
        )

        let attach = Attachment.fromData(
            credReqTuple.request.toJson().data(using: .utf8)!,
            id: format.attachId
        )

        
        return CredentialFormatCreateReturn(
            attachment: attach,
            format: format
        )
    }
    
    public func createRequest(
        credentialFormats: [Format]?,
        credentialExchangeRecord: CredentialExchangeRecord
    ) async throws -> CredentialFormatCreateReturn{
        throw CredoError("Starting from a request is not supported for anoncreds credentials")
    }
    
    public func processRequest(
        attachment: Attachment,
        credentialExchangeRecord: CredentialExchangeRecord
    ) async throws{
        throw CredoError("not needed for anoncreds")
    }
    
    public func acceptRequest(
        requestAttachment: Attachment,
        offerAttachment: Attachment?,
        credentialExchangeRecord: CredentialExchangeRecord,
        credentialFormats: [String: Any]?,
        requestAppendAttachments: [Attachment]?,
        attachmentId: String?
    ) async throws -> CredentialFormatCreateReturn {

        let credentialExchangeRecord = credentialExchangeRecord
        
        guard let credentialAttributes = credentialExchangeRecord.credentialAttributes else {
            throw CredoError("Missing required credential attribute values on credential record with id \(credentialExchangeRecord.id)")
        }

        guard let offerAttachment = offerAttachment else {
            throw CredoError("Missing offer attachments in accept request")
        }

        guard let credentialOffer = try? FormatDataUtil.parseAttachmentData(offerAttachment, as: AnonCredsCredentialOffer.self) else {
            throw CredoError("Missing anoncreds credential offer in createCredential")
        }

        guard let credentialRequest = try? FormatDataUtil.parseAttachmentData(requestAttachment, as: AnonCredsCredentialRequest.self) else {
            throw CredoError("Missing anoncreds credential request in createCredential")
        }

        let anonCredsCredentialDefinitionRecord = try await agent.anonCredsCredentialDefinitionRepository
            .getByCredentialDefinitionId(credentialRequest.credDefId)

        let credentialDefinition = anonCredsCredentialDefinitionRecord.credentialDefinition
        let revocation = credentialDefinition.value.primary["revocation"] as? [String: AnyCodable]

        var revocationRegistryDefinitionId: String?
        var revocationRegistryIndex: Int?
        var revocationStatusList: AnonCredsRevocationStatusList?

        if revocation != nil {
            let metadata = credentialExchangeRecord.metadata
            let credentialMetadataDict = metadata[MetadataKeys.anonCredsCredentialMetadataKey] as? [String: Any]
            let credentialMetadata = try? JSONDecoder().decode(AnonCredsCredentialMetadata.self, from: JSONSerialization.data(withJSONObject: credentialMetadataDict ?? [:]))

            revocationRegistryDefinitionId = credentialMetadata?.revocationRegistryId
            revocationRegistryIndex = Int(credentialMetadata?.credentialRevocationId ?? "")
            
    
            if revocationRegistryDefinitionId == nil || revocationRegistryIndex == nil {
                throw CredoError("Revocation registry definition id and revocation index are mandatory to issue AnonCreds revocable credentials")
            }

            let registryPrivateRecord = try await agent.anonCredsRevocationRegistryDefinitionPrivateRepository
                .getByRevocationRegistryDefinitionId(revocationRegistryDefinitionId: revocationRegistryDefinitionId!)

            if registryPrivateRecord.state != AnonCredsRevocationRegistryState.active {
                throw CredoError("Revocation registry \(revocationRegistryDefinitionId!) is in \(registryPrivateRecord.state) state")
            }

            let timestamp = UInt64(Date().timeIntervalSince1970)
            revocationStatusList = try await AnonCredsObjects.fetchRevocationStatusList(
                agent: agent,
                revocationRegistryId: revocationRegistryDefinitionId!,
                timestamp: timestamp
            )
           
        }

        let createCredentialOptions = CreateCredentialOptions(
            credentialOffer: credentialOffer,
            credentialRequest: credentialRequest,
            credentialValues: Credential.convertAttributesToCredentialValues(credentialAttributes),
            revocationRegistryDefinitionId: revocationRegistryDefinitionId,
            revocationStatusList: revocationStatusList,
            revocationRegistryIndex: revocationRegistryIndex
        )

        let createCredentialReturn = try await agent.anonCredsIssuerService.createCredential(options: createCredentialOptions)

        if createCredentialReturn.credential.revRegId != nil {
            let metadata = AnonCredsCredentialMetadata(
                revocationRegistryId: revocationRegistryDefinitionId,
                credentialRevocationId: createCredentialReturn.credentialRevocationId
            )

            do {
                let encodedMetadata = try JSONEncoder().encode(metadata)
                let anonCredsCredentialMetadataJson = try JSONSerialization.jsonObject(with: encodedMetadata, options: [])
                credentialExchangeRecord.metadata[MetadataKeys.anonCredsCredentialMetadataKey] = anonCredsCredentialMetadataJson as! AnyCodable
                
            } catch {
                throw CredoError("Error converting to JsonElement: \(error)")
            }
            

            if let registryId = revocationRegistryDefinitionId,
               let revocationId = createCredentialReturn.credentialRevocationId {
                credentialExchangeRecord.setTags([
                    "anonCredsRevocationRegistryId": registryId,
                    "anonCredsCredentialRevocationId": revocationId
                ])
            }
        }

        let format = Format(
            attachId: attachmentId ?? CredentialExchangeRecord.generateId(),
            format: AnoncredsCredentialFormatService.ANONCREDS_CREDENTIAL
        )

        let attachment = try FormatDataUtil.getFormatData(
            createCredentialReturn.credential,
            id: format.attachId
        )

        return CredentialFormatCreateReturn(
            attachment: attachment,
            format: format
        )
    }
    
    public func processCredential(
        attachment: Attachment,
        offerAttachment: Attachment,
        requestAttachment: Attachment,
        credentialExchangeRecord: CredentialExchangeRecord,
        requestAppendAttachments: [Attachment]?
    ) async throws{
        
        let credentialExchangeRecord = credentialExchangeRecord
       
        guard let credentialRequestMetadata = credentialExchangeRecord.metadata[MetadataKeys.anonCredsCredentialRequestMetadataKey] else {
           throw CredoError("Missing required request metadata for credential exchange with id \(credentialExchangeRecord.id)")
        }
       
        
       guard let credentialAttributes = credentialExchangeRecord.credentialAttributes, !credentialAttributes.isEmpty else {
           throw CredoError("Missing credential attributes on credential record. Unable to check credential attributes")
       }

       let decodedData = fromBase64ToString(attachment.data.base64)
       let anonCredsCredential = try JSONDecoder().decode(AnonCredsCredential.self, from: Data(decodedData.utf8))

       let credDefJson = try await agent.ledgerService.getCredentialDefinition(id: anonCredsCredential.credDefId)
       let anoncredsCredentialDefinition : AnonCredsCredentialDefinition = try JSONDecoder().decode(AnonCredsCredentialDefinition.self, from: Data(credDefJson.utf8))
        
       let schemaTuple = try await agent.ledgerService.getSchema(schemaId: anonCredsCredential.schemaId)
       let schemaData = Data(schemaTuple.0.utf8)
       let jsonElementSchema = try JSONSerialization.jsonObject(with: schemaData)
       guard let schema = FetchSchemaReturn.fromJson(jsonElementSchema,
                                               schemaId: anonCredsCredential.schemaId) else {
            throw CredoError("Schema not found")
        }
        
       var revocationRegistryResult: FetchIntermediateRevocationRegistryDefinitionResult?
       if let revRegId = anonCredsCredential.revRegId {
           let revocationJson = try await agent.ledgerService.getRevocationRegistryDefinition(id: revRegId)
           revocationRegistryResult = try JSONDecoder().decode(FetchIntermediateRevocationRegistryDefinitionResult.self, from: Data(revocationJson.utf8))
           revocationRegistryResult?.revocationRegistryDefinitionId = revRegId
           credentialExchangeRecord.updateRevocationInfos(
            credRevId: nil, //TODO
            revRegId: revRegId,
            revRegDefId: revocationRegistryResult?.revocationRegistryDefinitionId)
           
           credentialExchangeRecord.setRevRegId(revRegId)
           credentialExchangeRecord.setRevRegDefId(revocationRegistryResult?.revocationRegistryDefinitionId)
       }

       credentialExchangeRecord.setCredentialDefinitionId(anonCredsCredential.credDefId)
        
       var revocationRegistry: RevocationRegistryDefinition?
       if let revRegId = anonCredsCredential.revRegId {
           let revocationJson = try await agent.ledgerService.getRevocationRegistryDefinition(id: revRegId)
           revocationRegistry = try? RevocationRegistryDefinition(json: revocationJson)
           if let registry = revocationRegistry {
               Task {
                   try agent.revocationService.downloadTails(revocationRegistryDefinition: registry)
               }
           }
       }

       let recordCredentialValues = Credential.convertAttributesToCredentialValues(credentialAttributes)

       try Credential.assertCredentialValuesMatch(anonCredsCredential.values, recordCredentialValues)

        var credentialRequestMetadataAnoncreds: AnonCredsCredentialRequestMetadata?

        if let metadataDict = credentialRequestMetadata.value as? [String: Any],
           let linkSecretRaw = metadataDict["link_secret_blinding_data"] {

            if let linkSecretDict = linkSecretRaw as? [String: Any] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: linkSecretDict, options: [])
                    let decoder = JSONDecoder()
                    let linkSecretBlindingData = try decoder.decode(AnonCredsLinkSecretBlindingData.self, from: jsonData)

                    credentialRequestMetadataAnoncreds = AnonCredsCredentialRequestMetadata(
                        linkSecretBlindingData: linkSecretBlindingData,
                        linkSecretName: metadataDict["link_secret_name"] as? String ?? "",
                        nonce: metadataDict["nonce"] as? String ?? ""
                    )

                    print("✅ Metadata successfully built: \(credentialRequestMetadataAnoncreds!)")
                } catch {
                    throw CredoError("❌ Error decoding or building metadata: \(error)")
                }
            } else {
                throw CredoError("❌ 'link_secret_blinding_data' is not a valid dictionary")
            }

        } else {
            throw CredoError("❌ Invalid credentialRequestMetadata or missing key")
        }


       var revocationRegistryInfo: RevocationRegistryInfo?
       if let revRegResult = revocationRegistryResult,
          let revRegId = revRegResult.revocationRegistryDefinitionId {

           let revDef = AnonCredsRevocationRegistryDefinition(
               issuerId: revRegResult.issuerId,
               revocDefType: revRegResult.revocDefType,
               credDefId: revRegResult.credDefId,
               tag: revRegResult.tag,
               value: revRegResult.value
           )

           revocationRegistryInfo = RevocationRegistryInfo(id: revRegId, definition: revDef)
       }

       let storeCredential = StoreCredentialOptions(
           credential: anonCredsCredential,
           credentialRequestMetadata: credentialRequestMetadataAnoncreds!,
           credentialDefinition: anoncredsCredentialDefinition, //<<<
           schema: schema.schema,
           schemaId: anonCredsCredential.schemaId,
           credentialDefinitionId: anonCredsCredential.credDefId,
           credentialId: UUID().uuidString,
           revocationRegistry: revocationRegistryInfo
       )

        credentialExchangeRecord.updateSchema(schemaId: anonCredsCredential.schemaId,
                                              schema: schema.schema)

       let storeOptions = try StoreCredential.getStoreCredentialOptions(options: storeCredential)
       let credentialId = try await agent.anonCredsHolderService.storeCredential(
                                    options: storeOptions,
                                    metadata: nil
                               )

        if anonCredsCredential.revRegId != nil {
            let credential = try await agent.anonCredsHolderService.getCredential(credentialId: credentialId)

            let metadata = AnonCredsCredentialMetadata(
                revocationRegistryId: credential.revocationRegistryId,
                credentialRevocationId: credential.credentialRevocationId
            )
            let metadataData = try JSONEncoder().encode(metadata)

            let metadataDict = try JSONSerialization.jsonObject(with: metadataData, options: []) as? [String: Any]
            let anyCodableDict = metadataDict?.mapValues { AnyCodable($0) }

            if let safeDict = anyCodableDict {
                credentialExchangeRecord.addMetadata(
                    key: MetadataKeys.anonCredsCredentialMetadataKey,
                    value: AnyCodable(safeDict)
                )
            }

            if let revocationId = credential.credentialRevocationId {
                credentialExchangeRecord.setTags([
                    "anonCredsRevocationRegistryId": credential.revocationRegistryId ?? "",
                    "anonCredsCredentialRevocationId": revocationId
                ])
            }
        }
        
       credentialExchangeRecord.w3cCredentialId = credentialId
       credentialExchangeRecord.credentials.append(
           CredentialRecordBinding(
               credentialRecordType: credentialRecordType,
               credentialRecordId: credentialId
           )
       )

       do {
           try await agent.credentialExchangeRepository.update(credentialExchangeRecord)
       } catch {
           throw CredoError("Failed to save credential exchange record: \(error.localizedDescription)")
       }
    }
    
    public func shouldAutoRespondToProposal(
        credentialRecord: CredentialExchangeRecord,
        offerAttachment: Attachment,
        proposalAttachment: Attachment
    ) async throws -> Bool {
        guard let credentialOffer: AnonCredsCredentialOffer = try? FormatDataUtil.parseAttachmentData(offerAttachment, as: AnonCredsCredentialOffer.self) else {
            throw CredoError("Missing anoncreds credential offer in shouldAutoRespondToProposal")
        }
        
        guard let proposal: AnonCredsCredentialProposalFormat = try? FormatDataUtil.parseAttachmentData(proposalAttachment, as: AnonCredsCredentialProposalFormat.self) else {
            throw CredoError("Missing anoncreds credential proposal in shouldAutoRespondToProposal")
        }
        
        return proposal.credDefId == credentialOffer.credDefId
    }
    
    public func shouldAutoRespondToOffer(
        credentialRecord: CredentialExchangeRecord,
        offerAttachment: Attachment,
        proposalAttachment: Attachment
    ) async throws -> Bool {
        guard let credentialOffer: AnonCredsCredentialOffer = try? FormatDataUtil.parseAttachmentData(offerAttachment, as: AnonCredsCredentialOffer.self) else {
            throw CredoError("Missing anoncreds credential offer in shouldAutoRespondToProposal")
        }
        
        guard let proposal: AnonCredsCredentialProposalFormat = try? FormatDataUtil.parseAttachmentData(proposalAttachment, as: AnonCredsCredentialProposalFormat.self) else {
            throw CredoError("Missing anoncreds credential proposal in shouldAutoRespondToProposal")
        }
        
        return proposal.credDefId == credentialOffer.credDefId
    }
    
    public func shouldAutoRespondToRequest(
        credentialRecord: CredentialExchangeRecord,
        offerAttachment: Attachment,
        requestAttachment: Attachment,
        proposalAttachment: Attachment
    ) async throws -> Bool {
        guard let credentialOffer: AnonCredsCredentialOffer = try? FormatDataUtil.parseAttachmentData(offerAttachment, as: AnonCredsCredentialOffer.self) else {
            throw CredoError("Missing anoncreds credential offer in shouldAutoRespondToProposal")
        }
        
        guard let requestOffer: AnonCredsCredentialRequest = try? FormatDataUtil.parseAttachmentData(requestAttachment, as: AnonCredsCredentialRequest.self) else {
            throw CredoError("Missing anoncreds credential request in shouldAutoRespondToProposal")
        }
        
        return requestOffer.credDefId == credentialOffer.credDefId
    }
    
    
    public func shouldAutoRespondToCredential(
        credentialRecord: CredentialExchangeRecord,
        offerAttachment: Attachment,
        issueAttachment: Attachment,
        requestAttachment: Attachment,
        proposalAttachment: Attachment
    ) async throws -> Bool {
        guard let credential: AnonCredsCredential = try? FormatDataUtil.parseAttachmentData(offerAttachment, as: AnonCredsCredential.self) else {
            throw CredoError("Missing anoncreds credential offer in shouldAutoRespondToProposal")
        }
        
        guard (try? FormatDataUtil.parseAttachmentData(requestAttachment, as: AnonCredsCredentialRequest.self)) != nil else {
            throw CredoError("Missing anoncreds credential request in shouldAutoRespondToProposal")
        }
        
        guard let attributes = credentialRecord.credentialAttributes else {
            return false
        }
        
        let attributeValues = Credential.convertAttributesToCredentialValues(attributes)
        return Credential.checkCredentialValuesMatch(attributeValues, credential.values)
    }
    
    public func deleteCredentialById(credentialId: String) async throws{
        try await agent.anonCredsHolderService.deleteCredential(credentialId: credentialId)
    }
    
    public func supportsFormat(_ formatIdentifier: String) -> Bool{
        let supportedFormats = [
            "anoncreds/credential-request@v1.0",
            "anoncreds/credential-offer@v1.0",
            "anoncreds/credential-filter@v1.0",
            "anoncreds/credential@v1.0"
        ]
        
        return supportedFormats.contains(formatIdentifier)
    }
    
    func dateToTimestamp(_ date: Date) -> Int {
        return Int(date.timeIntervalSince1970)
    }
    
    private func getHolderDid(
        credentialRecord: CredentialExchangeRecord
    ) async throws -> String {
        let connectionId : String? = credentialRecord.connectionId
        
        if(connectionId == nil){
            throw CredoError("Connection id not found")
        }
        
        let connection = try await agent.connectionRepository.getById(connectionId!)
        return connection.did
    }
    
    
    private func createAnonCredsOffer(_ input: CreateAnoncredsOffer) async throws -> CredentialFormatCreateOfferReturn {
        let credentialExchangeRecord = input.credentialExchangeRecord
        let revocationRegistryDefinitionId = input.revocationRegistryDefinitionId
        let credentialDefinitionId = input.credentialDefinitionId
        let revocationRegistryIndex = input.revocationRegistryIndex

        let format = Format(
            attachId: input.attachmentId ?? CredentialExchangeRecord.generateId(),
            format: AnoncredsCredentialFormatService.ANONCREDS_CREDENTIAL_OFFER
        )

        let anoncredsCredentialOffer = try await agent.anonCredsIssuerService.createCredentialOffer(credentialDefinitionId: credentialDefinitionId)

        let credentialLinkedAttachmentsResult : CredentialLinkedAttachmentsResult = try FormatDataUtil.getCredentialLinkedAttachments(
            attributes: input.attributes,
            linkedAttachments: input.linkedAttachments
        )
        
        let previewAttributes = credentialLinkedAttachmentsResult.previewAttributes

        guard let previewAttributes else {
            throw CredoError("Missing required preview attributes for anoncreds offer")
        }

        try await FormatDataUtil.assertPreviewAttributesMatchSchemaAttributes(
            agent: agent,
            offer: anoncredsCredentialOffer,
            attributes: previewAttributes
        )

        let credDefRecord = try await agent.anonCredsCredentialDefinitionRepository.getByCredentialDefinitionId(credentialDefinitionId)
        
        let credentialDefinition = credDefRecord.credentialDefinition.value

        if credentialDefinition.revocation != nil {
            guard let revRegDefId = revocationRegistryDefinitionId,
                  let revRegIndex = revocationRegistryIndex else {
                throw CredoError("AnonCreds revocable credentials require revocationRegistryDefinitionId and revocationRegistryIndex")
            }

            let tags: Tags = [
                "anonCredsRevocationRegistryId": revRegDefId,
                "anonCredsCredentialRevocationId": String(revRegIndex)
            ]
            credentialExchangeRecord.setTags(tags)
        }

        let metadata = AnonCredsCredentialMetadata(
            schemaId: anoncredsCredentialOffer.schemaId,
            credentialDefinitionId: anoncredsCredentialOffer.credDefId,
            revocationRegistryId: revocationRegistryDefinitionId,
            credentialRevocationId: revocationRegistryIndex?.description
        )
        
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(metadata)
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
            credentialExchangeRecord.metadata[MetadataKeys.anonCredsCredentialMetadataKey] = jsonObject as! AnyCodable

        } catch {
            throw CredoError("Error convertig to JsonElement: \(error)")
        }

        let attachment = try FormatDataUtil.getFormatData(
            anoncredsCredentialOffer,
            id: format.attachId
        )

        return CredentialFormatCreateOfferReturn(
            attachment: attachment,
            format: format,
            previewAttributes: previewAttributes
        )
    }
    
}
