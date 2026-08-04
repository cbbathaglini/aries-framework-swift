//
//  CredentialServiceV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/25.
//

import Foundation
import anoncreds_uniffi
import os

public class CredentialServiceV2Old {
    let agent: Agent
    let credentialExchangeRepository: CredentialExchangeRepository
    let didCommMessageRepository: DidCommMessageRepository
    let ledgerService: LedgerService
    let logger = Logger(subsystem: "AriesFramework", category: "CredentialServiceV2")

    init(agent: Agent) {
        self.agent = agent
        self.credentialExchangeRepository = agent.credentialExchangeRepository
        self.didCommMessageRepository = agent.didCommMessageRepository
        self.ledgerService = agent.ledgerService
    }

    /// Create a `ProposeCredentialMessageV2` not bound to an existing credential record.
    public func createProposal(options: CreateProposalOptionsV2) async throws -> (ProposeCredentialMessageV2, CredentialExchangeRecord) {
        logger.debug("[2.0] createProposeCredentialMessage init")

        let credentialRecord = CredentialExchangeRecord(
            connectionId: options.connection.id,
            threadId: CredentialExchangeRecord.generateId(),
            state: .ProposalSent,
            autoAcceptCredential: options.autoAcceptCredential,
            protocolVersion: CredentialConstants.protocolVersionV2,
            role: CredentialRole.holder,
            revocationNotification: nil
        )

        
        let message = ProposeCredentialMessageV2(
            id: credentialRecord.threadId,
            formats: [],
            proposalAttachments: options.proposalAttachments,
            credentialPreview: options.credentialPreview,
            goalCode: options.goalCode,
            goal: options.goal,
            comment: options.comment
        )

        try await agent.didCommMessageRepository.saveAgentMessage(
            role: .Sender,
            agentMessage: message,
            associatedRecordId: credentialRecord.id
        )

        try await credentialExchangeRepository.save(credentialRecord)
        agent.agentDelegate?.onCredentialStateV2Changed(credentialRecord: credentialRecord)

        return (message, credentialRecord)
    }

    /// Create an `OfferCredentialMessageV2` not bound to an existing credential record.
    public func createOffer(options: CreateCredentialOfferOptionsV2) async throws -> (OfferCredentialMessageV2, CredentialExchangeRecord) {
        logger.debug("[2.0] createOfferCredentialMessage init")

        if options.connection == nil {
            logger.info("Creating credential offer without connection. This should be used for out-of-band request message with handshake.")
        }

        var credentialRecord = CredentialExchangeRecord(
            connectionId: options.connection?.id ?? "connectionless-offer",
            threadId: UUID().uuidString,
            state: .OfferSent,
            autoAcceptCredential: options.autoAcceptCredential,
            protocolVersion: CredentialConstants.protocolVersionV2
        )

        let credentialDefinitionRecord = try await agent.credentialDefinitionRepository.getByCredDefId(options.credentialDefinitionId)
        let offer = try Issuer().createCredentialOffer(
            schemaId: credentialDefinitionRecord.schemaId,
            credDefId: credentialDefinitionRecord.credDefId,
            keyProof: try CredentialKeyCorrectnessProof(json: credentialDefinitionRecord.keyCorrectnessProof)
        )

        let attachment = Attachment.fromData(
            offer.toJson().data(using: .utf8)!,
            id: OfferCredentialMessageV2.INDY_CREDENTIAL_OFFER_ATTACHMENT_ID
        )

        let credentialPreview = CredentialPreviewV2(attributes: options.attributes)
    

        
        let message = OfferCredentialMessageV2(
            formats: options.formats,
            offerAttachments: [attachment],
            goalCode: options.goalCode,
            goal: options.goal,
            comment: options.comment,
            credentialPreview: credentialPreview,
            replacementId: options.replacementId
        )

        try await agent.didCommMessageRepository.saveAgentMessage(
            role: .Sender,
            agentMessage: message,
            associatedRecordId: credentialRecord.id
        )

        credentialRecord.credentialAttributes = options.attributes
        try await credentialExchangeRepository.save(credentialRecord)
        agent.agentDelegate?.onCredentialStateV2Changed(credentialRecord: credentialRecord)

        return (message, credentialRecord)
    }

    /// Process a received `OfferCredentialMessageV2`.
    public func processOffer(messageContext: InboundMessageContext) async throws -> CredentialExchangeRecord {
        logger.debug("[2.0] processOfferCredentialMessage init")
        let offerMessage = try JSONDecoder().decode(OfferCredentialMessageV2.self, from: Data(messageContext.plaintextMessage.utf8))
        logger.debug("offer credential message: \(offerMessage.toJsonString())")
        
        guard offerMessage.getOfferAttachmentById(OfferCredentialMessageV2.INDY_CREDENTIAL_OFFER_ATTACHMENT_ID) != nil else {
            throw AriesFrameworkError.frameworkError("Indy attachment with id \(OfferCredentialMessageV2.INDY_CREDENTIAL_OFFER_ATTACHMENT_ID) not found in offer message")
        }

        if var credentialRecord = try await credentialExchangeRepository.findByThreadAndConnectionId(threadId: offerMessage.threadId, connectionId: messageContext.connection?.id) {
            try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
                role: .Receiver,
                agentMessage: offerMessage,
                associatedRecordId: credentialRecord.id
            )
            try await updateState(credentialRecord: &credentialRecord, newState: .OfferReceived)
            return credentialRecord
        } else {
            let connection = try messageContext.assertReadyConnection()
            let credentialRecord = CredentialExchangeRecord(
                connectionId: connection.id,
                threadId: offerMessage.threadId,
                parentThreadId: offerMessage.threadId,
                state: CredentialState.OfferReceived,
                protocolVersion: CredentialConstants.protocolVersionV2,
                role: CredentialRole.holder
            )

            try await agent.didCommMessageRepository.saveAgentMessage(
                role: .Receiver,
                agentMessage: offerMessage,
                associatedRecordId: credentialRecord.id
            )

            try await credentialExchangeRepository.save(credentialRecord)
            agent.agentDelegate?.onCredentialStateV2Changed(credentialRecord: credentialRecord)

            logger.debug("credential record: protocol:\(credentialRecord.protocolVersion)")
            logger.debug("OfferCredentialHandlerV2 finish")
            return credentialRecord
        }
    }

    /// Create an `IssueCredentialMessageV2` as response to a received credential request.
    public func createIssueCredentialMessage(options: AcceptRequestOptions) async throws -> IssueCredentialMessageV2 {
        logger.debug("[2.0] createIssueCredentialMessage init")

        var credentialRecord = try await credentialExchangeRepository.getById(options.credentialRecordId)
        try credentialRecord.assertProtocolVersion(CredentialConstants.protocolVersionV2)
        try credentialRecord.assertState(.RequestReceived)

        let offerMessageJson = try await agent.didCommMessageRepository.getAgentMessage(
            associatedRecordId: credentialRecord.id,
            messageType: OfferCredentialMessageV2.type
        )

        let offerMessage = try JSONDecoder().decode(OfferCredentialMessageV2.self, from: Data(offerMessageJson.utf8))

        let requestMessageJson = try await agent.didCommMessageRepository.getAgentMessage(
            associatedRecordId: credentialRecord.id,
            messageType: RequestCredentialMessageV2.type
        )

        let requestMessage = try JSONDecoder().decode(RequestCredentialMessageV2.self, from: Data(requestMessageJson.utf8))

        guard let offerAttachment = offerMessage.getOfferAttachmentById(OfferCredentialMessageV2.INDY_CREDENTIAL_OFFER_ATTACHMENT_ID),
              let requestAttachment = requestMessage.getRequestAttachmentById(RequestCredentialMessageV2.INDY_CREDENTIAL_REQUEST_ATTACHMENT_ID) else {
            throw AriesFrameworkError.frameworkError("Missing data payload in offer or request attachment in credential record \(credentialRecord.id)")
        }

        let formats = offerMessage.formats
        let goal = offerMessage.goal
        let comment = offerMessage.comment
        let offer = try CredentialOffer(json: offerAttachment.getDataAsString())
        let request = try CredentialRequest(json: requestAttachment.getDataAsString())
        let credDefId = offer.credDefId()
        let credentialDefinitionRecord = try await agent.credentialDefinitionRepository.getByCredDefId(credDefId)

        var revocationConfig: CredentialRevocationConfig?
        if let revocationRecord = try await agent.revocationRegistryRepository.findByCredDefId(credDefId) {
            let registryIndex = try await agent.revocationRegistryRepository.incrementRegistryIndex(credDefId: credDefId)
            logger.debug("Revocation registry index: \(registryIndex)")

            revocationConfig = CredentialRevocationConfig(
                regDef: try RevocationRegistryDefinition(json: revocationRecord.revocRegDef),
                regDefPrivate: try RevocationRegistryDefinitionPrivate(json: revocationRecord.revocRegPrivate),
                statusList: try Anoncreds.RevocationStatusList(json: revocationRecord.revocStatusList),
                registryIndex: UInt32(registryIndex))
        }

        let credential = try Issuer().createCredential(
            credDef: try CredentialDefinition(json: credentialDefinitionRecord.credDef),
            credDefPrivate: try CredentialDefinitionPrivate(json: credentialDefinitionRecord.credDefPriv),
            credOffer: offer,
            credRequest: request,
            attrRawValues: credentialRecord.getCredentialInfo()?.claims ?? [:],
            attrEncValues: nil,
            revocationConfig: revocationConfig
        )

        let attachment = try Attachment.fromData(
            credential.toJson().data(using: .utf8)!,
            id: IssueCredentialMessageV2.INDY_CREDENTIAL_ATTACHMENT_ID
        )

        var issueMessage = IssueCredentialMessageV2(
            formats: formats,
            credentialAttachments: [attachment],
            goal: goal,
            comment: options.comment
        )

        issueMessage.thread = ThreadDecorator(threadId: credentialRecord.threadId)

        try await agent.didCommMessageRepository.saveAgentMessage(
            role: .Sender,
            agentMessage: issueMessage,
            associatedRecordId: credentialRecord.id
        )

        credentialRecord.autoAcceptCredential = options.autoAcceptCredential ?? credentialRecord.autoAcceptCredential
        try await updateState(credentialRecord: &credentialRecord, newState: .CredentialIssued)

        return issueMessage
    }
    
    public func processIssueCredentialMessage(messageContext: InboundMessageContext) async throws -> CredentialExchangeRecord {
        logger.debug("[2.0] processIssueCredentialMessage init")

        let issueMessage = try JSONDecoder().decode(IssueCredentialMessageV2.self, from: Data(messageContext.plaintextMessage.utf8))

        guard let issueAttachment = issueMessage.getCredentialAttachmentById(IssueCredentialMessageV2.INDY_CREDENTIAL_ATTACHMENT_ID) else {
            throw AriesFrameworkError.frameworkError("Indy attachment with id \(IssueCredentialMessageV2.INDY_CREDENTIAL_ATTACHMENT_ID) not found in issue message")
        }
        
        var credentialRecord = try await credentialExchangeRepository.getByThreadAndConnectionId(
            threadId: issueMessage.threadId,
            connectionId: messageContext.connection?.id
        )

        let credential = try Credential(json: issueAttachment.getDataAsString())
        let (schemaJson, _) = try await ledgerService.getSchema(schemaId: credential.schemaId())
        let schema = try Schema(json: schemaJson)
        let credentialDefinition = try CredentialDefinition(json: try await ledgerService.getCredentialDefinition(id: credential.credDefId()))

        let revocationRegistryJson = credential.revRegId() != nil ? try await ledgerService.getRevocationRegistryDefinition(id: credential.revRegId()!) : nil
        let revocationRegistry = revocationRegistryJson != nil ? try RevocationRegistryDefinition(json: revocationRegistryJson!) : nil

        if let revocationRegistry = revocationRegistry {
            Task {
                _ = try agent.revocationService.downloadTails(revocationRegistryDefinition: revocationRegistry)
            }
        }

        let linkSecret = try await agent.anoncredsService.getLinkSecret(id: agent.wallet.linkSecretId!)

        let processedCredential = try Prover().processCredential(
            cred: credential,
            credReqMetadata: CredentialRequestMetadata(json: credentialRecord.indyRequestMetadata!),
            linkSecret: linkSecret,
            credDef: credentialDefinition,
            revRegDef: revocationRegistry
        )

        let credentialId = UUID().uuidString

        try await agent.credentialRepository.save(
            CredentialRecord(
                credentialId: credentialId,
                credentialRevocationId: processedCredential.revRegIndex().map { String($0) },
                revocationRegistryId: processedCredential.revRegId(),
                linkSecretId: agent.wallet.linkSecretId!,
                credential: processedCredential,
                schemaId: processedCredential.schemaId(),
                schemaName: schema.name(),
                schemaVersion: schema.version(),
                schemaIssuerId: schema.issuerId(),
                issuerId: credentialDefinition.issuerId(),
                credentialDefinitionId: processedCredential.credDefId(),
                revocationNotification: nil
            )
        )

        credentialRecord.credentials.append(CredentialRecordBinding(credentialRecordType: "indy", credentialRecordId: credentialId))
        try await agent.didCommMessageRepository.saveAgentMessage(
            role: DidCommMessageRole.Receiver,
            agentMessage: issueMessage,
            associatedRecordId: credentialRecord.id
        )

        try await updateState(credentialRecord: &credentialRecord, newState: .CredentialReceived)

        return credentialRecord
    }

    public func createRequest(options: AcceptOfferOptions) async throws -> RequestCredentialMessageV2 {
        logger.debug("[2.0] createRequestCredentialMessage init")

        var credentialRecord = try await credentialExchangeRepository.getById(options.credentialRecordId)
        try credentialRecord.assertProtocolVersion(CredentialConstants.protocolVersionV2)
        try credentialRecord.assertState(CredentialState.OfferReceived)

        let offerMessageJson = try await didCommMessageRepository.getAgentMessage(
            associatedRecordId: credentialRecord.id,
            messageType: OfferCredentialMessageV2.type
        )

        let offerMessage = try JSONDecoder().decode(OfferCredentialMessageV2.self, from: Data(offerMessageJson.utf8))
        try offerMessage.validateIndyAttachId()

        let holderDid = try await resolveHolderDid(holderDid: options.holderDid, credentialRecord: credentialRecord)
        let formats = offerMessage.formats
        let goal = offerMessage.goal
        let goalCode = offerMessage.goalCode
        let comment = offerMessage.comment

        let credentialOfferJson = try offerMessage.getCredentialOffer()
        let credentialOffer = try CredentialOffer(json: credentialOfferJson)
        let credentialDefinition = try await ledgerService.getCredentialDefinition(id: credentialOffer.credDefId())
        let linkSecret = try await agent.anoncredsService.getLinkSecret(id: agent.wallet.linkSecretId!)

        let credReqTuple = try Prover().createCredentialRequest(
            entropy: nil,
            proverDid: holderDid,
            credDef: try CredentialDefinition(json: credentialDefinition),
            linkSecret: linkSecret,
            linkSecretId: agent.wallet.linkSecretId!,
            credOffer: credentialOffer
        )

        credentialRecord.indyRequestMetadata = credReqTuple.metadata.toJson()
        credentialRecord.credentialDefinitionId = credentialOffer.credDefId()

        let attachment = try Attachment.fromData(
            credReqTuple.request.toJson().data(using: .utf8)!,
            id: RequestCredentialMessageV2.INDY_CREDENTIAL_REQUEST_ATTACHMENT_ID
        )

        var requestMessage = RequestCredentialMessageV2(
            formats: formats,
            requestAttachments: [attachment],
            goalCode: goalCode,
            goal: goal,
            comment: comment
        )

        requestMessage.thread = ThreadDecorator(threadId: credentialRecord.threadId)

        credentialRecord.credentialAttributes = offerMessage.credentialPreview?.attributes
        credentialRecord.autoAcceptCredential = options.autoAcceptCredential ?? credentialRecord.autoAcceptCredential

        try await didCommMessageRepository.saveAgentMessage(
            role: .Sender,
            agentMessage: requestMessage,
            associatedRecordId: credentialRecord.id
        )

        try await updateState(credentialRecord: &credentialRecord, newState: .RequestSent)

        return requestMessage
    }
    
    public func processRequestCredentialMessage(messageContext: InboundMessageContext) async throws -> CredentialExchangeRecord {
        logger.debug("[2.0] processRequestCredentialMessage init")

        let requestMessage = try JSONDecoder().decode(RequestCredentialMessageV2.self, from: Data(messageContext.plaintextMessage.utf8))

        guard requestMessage.getRequestAttachmentById(RequestCredentialMessageV2.INDY_CREDENTIAL_REQUEST_ATTACHMENT_ID) != nil else {
            throw AriesFrameworkError.frameworkError("Indy attachment with id \(RequestCredentialMessageV2.INDY_CREDENTIAL_REQUEST_ATTACHMENT_ID) not found in request message")
        }

        var credentialRecord = try await credentialExchangeRepository.getByThreadAndConnectionId(
            threadId: requestMessage.threadId,
            connectionId: nil
        )

        let connection = try messageContext.assertReadyConnection()
        credentialRecord.connectionId = connection.id

        try await agent.didCommMessageRepository.saveAgentMessage(
            role: DidCommMessageRole.Receiver,
            agentMessage: requestMessage,
            associatedRecordId: credentialRecord.id
        )

        try await updateState(credentialRecord: &credentialRecord, newState: .RequestReceived)

        return credentialRecord
    }
    
    public func processAck(messageContext: InboundMessageContext) async throws -> CredentialExchangeRecord {
        let ackMessage = try JSONDecoder().decode(CredentialAckMessageV2.self, from: Data(messageContext.plaintextMessage.utf8))

        var credentialRecord = try await credentialExchangeRepository.getByThreadAndConnectionId(
            threadId: ackMessage.threadId,
            connectionId: messageContext.connection?.id
        )

        try await updateState(credentialRecord: &credentialRecord, newState: .Done)

        return credentialRecord
    }
    
    public func createOfferDeclinedProblemReport(options: AcceptOfferOptions) async throws -> CredentialProblemReportMessage {
        var credentialRecord = try await credentialExchangeRepository.getById(options.credentialRecordId)
        try credentialRecord.assertProtocolVersion(CredentialConstants.protocolVersionV2)
        try credentialRecord.assertState(CredentialState.OfferReceived)

        try await updateState(credentialRecord: &credentialRecord, newState: .Declined)

        return CredentialProblemReportMessage(threadId: credentialRecord.threadId)
    }
    
    public func createCredentialAckMessage(options: AcceptCredentialOptions) async throws -> CredentialAckMessageV2 {
        var credentialRecord = try await credentialExchangeRepository.getById(options.credentialRecordId)
        try credentialRecord.assertProtocolVersion(CredentialConstants.protocolVersionV2)
        try credentialRecord.assertState(.CredentialReceived)

        try await updateState(credentialRecord: &credentialRecord, newState: .Done)

        return CredentialAckMessageV2(threadId: credentialRecord.threadId, status: .OK)
    }
    
    /// Updates the state of the credential record.
    private func updateState(credentialRecord: inout CredentialExchangeRecord, newState: CredentialState) async throws {
        credentialRecord.state = newState
        try await credentialExchangeRepository.update(credentialRecord)
        agent.agentDelegate?.onCredentialStateV2Changed(credentialRecord: credentialRecord)
    }
    
    private func getHolderDid(credentialRecord: CredentialExchangeRecord) async throws -> String {
        let connection = try await agent.connectionRepository.getById(credentialRecord.connectionId)
        return connection.did
    }
    
    private func resolveHolderDid(holderDid: String?, credentialRecord: CredentialExchangeRecord) async throws -> String {
        if let providedHolderDid = holderDid {
            return providedHolderDid
        } else {
            return try await getHolderDid(credentialRecord: credentialRecord)
        }
    }
}
