//
//  CredentialServiceV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/25.
//

import Foundation
import os
import os.log

public final class CredentialServiceV2 {
    private let logger = Logger(subsystem: "org.hyperledger.ariesframework", category: "CredentialServiceV2")
    private let agent: Agent

    private var credentialExchangeRepository: CredentialExchangeRepository { agent.credentialExchangeRepository }
    private var didCommMessageRepository: DidCommMessageRepository { agent.didCommMessageRepository }

    private let credentialFormats: [any CredentialFormatService]
    private let credentialFormatCoordinator: CredentialFormatCoordinator

    public init(agent: Agent) {
        self.agent = agent
        self.credentialFormats = [
            AnoncredsCredentialFormatService(agent: agent)
        ]
        self.credentialFormatCoordinator = CredentialFormatCoordinator(agent: agent, formatServices: credentialFormats)

        Registers(agent: agent).initialize()
    }


    public func createProposal(options: CreateProposalOptionsV2) async throws
        -> (ProposeCredentialMessageV2, CredentialExchangeRecord)
    {
        logDebug("Get the Format Service and Create Proposal Message")
        let formatServices = getFormatServices(options.credentialFormats)
        guard !formatServices.isEmpty else {
            throw CredoError("Unable to create proposal. No supported formats")
        }

        let credentialExchangeRecord = CredentialExchangeRecord(
                tags: nil,
                connectionId: options.connection.id,
                threadId: CredentialExchangeRecord.generateId(),
                parentThreadId: nil,
                state: .ProposalSent,
                autoAcceptCredential: options.autoAcceptCredential,
                errorMessage: nil,
                protocolVersion: CredentialsConstants.PROTOCOL_VERSION_V2,
                credentials: nil,
                credentialAttributes: nil,
                role: .holder,
                schemaId: nil,
                schemaName: nil,
                schemaVersion: nil,
                schemaIssuerId: nil,
                revRegId: nil,
                revRegDefId: nil,
                formats: nil
        )

        let params = CreateProposalParams(
            credentialFormats: options.credentialFormats,
            formatServices: formatServices,
            credentialRecord: credentialExchangeRecord,
            comment: options.comment,
            goalCode: options.goalCode,
            goal: options.goal
        )

        let proposal = try await credentialFormatCoordinator.createProposal(params: params)
        logDebug("Save record and emit state change event")

        try await credentialExchangeRepository.save(credentialExchangeRecord)
        agent.agentDelegate?.onCredentialStateV2Changed(credentialRecord: credentialExchangeRecord)
        return (proposal, credentialExchangeRecord)
    }

  
    public func processProposal(_ messageContext: InboundMessageContext) async throws -> CredentialExchangeRecord {
        
        let proposalMessage = try JSONDecoder().decode(ProposeCredentialMessageV2.self, from: Data(messageContext.plaintextMessage.utf8))
        logDebug("[2.0] Processing credential proposal with id \(proposalMessage.id)")
        
        let connection = messageContext.connection
        
        let credentialRecord = try await agent.credentialExchangeRepository.getByThreadAndRole(
            threadId: proposalMessage.threadId,
            role: CredentialRole.issuer
        )

        let formatServices = getFormatServicesFromMessage(proposalMessage.formats)
        guard !formatServices.isEmpty else {
            throw CredoError("Unable to process proposal. No supported formats")
        }

        if var rec = credentialRecord {
            try rec.assertProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            try rec.assertState(CredentialState.OfferSent)

            //[TODO]
//                messageContext: messageContext,
//                lastReceivedMessage: proposalMsg,
//                lastSentMessage: offerMsg,
//                expectedConnectionId: rec.connectionId
//            )

            if rec.connectionId == nil {
                try await agent.connectionService.matchIncomingMessageToRequestMessageInOutOfBandExchange(
                    messageContext: messageContext,
                    expectedConnectionId: nil
                )
                rec.connectionId = connection?.id ?? "unknown"
            }

            try await credentialFormatCoordinator.processProposal(
                credentialExchangeRecord: rec,
                message: proposalMessage,
                formatServices: formatServices
            )

            try await credentialExchangeRepository.save(rec)
            try await updateState(credentialRecord: &rec,
                                  newState: .ProposalReceived)
            return rec
        }

        //[TODO]

        let newRecord = CredentialExchangeRecord(
            connectionId: connection?.id ?? "unknown",
            threadId: proposalMessage.threadId,
            parentThreadId: proposalMessage.thread?.parentThreadId,
            state: .ProposalReceived,
            protocolVersion: CredentialsConstants.PROTOCOL_VERSION_V2,
            role: .issuer
        )

        try await credentialFormatCoordinator.processProposal(
            credentialExchangeRecord: newRecord,
            message: proposalMessage,
            formatServices: formatServices
        )

        try await agent.credentialExchangeRepository.save(newRecord)
        agent.agentDelegate?.onCredentialStateV2Changed(credentialRecord: newRecord)
        return newRecord
    }


    public func acceptProposal(options: AcceptCredentialProposalOptions) async throws
        -> (OfferCredentialMessageV2, CredentialExchangeRecord)
    {
        var rec = options.credentialExchangeRecord

        try rec.assertProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
        try rec.assertState(CredentialState.ProposalReceived)

        var formatServices = getFormatServices(options.credentialFormats ?? [:])
        if formatServices.isEmpty {
            let proposalStr = try await didCommMessageRepository.getAgentMessage(
                associatedRecordId: rec.id,
                messageType: ProposeCredentialMessageV2.type,
                role: DidCommMessageRole.Receiver
            ) ?? { throw CredoError("Proposal message not found") }()
            
            let proposal: ProposeCredentialMessageV2 = try JSONDecoder().decode(ProposeCredentialMessageV2.self, from: Data(proposalStr.utf8))
            
            formatServices = getFormatServicesFromMessage(proposal.formats)
        }
        guard !formatServices.isEmpty else {
            throw CredoError("Unable to accept proposal. No supported formats provided as input or in proposal message")
        }

        let params = AcceptProposalParams(
            credentialRecord: rec,
            formatServices: formatServices,
            comment: options.comment,
            goal: options.goal,
            goalCode: options.goalCode,
            credentialFormats: options.credentialFormats
        )
        
        let offer : OfferCredentialMessageV2 = try await credentialFormatCoordinator.acceptProposal(params: params)

        rec.autoAcceptCredential = options.autoAcceptCredential ?? rec.autoAcceptCredential
    
        try await updateState(credentialRecord: &rec,
                              newState: .OfferSent)
        
        return (offer, rec)
    }

    public func negotiateProposal(options: NegotiateCredentialProposalOptions) async throws
        -> (CredentialExchangeRecord, OfferCredentialMessageV2)
    {
        var rec = options.credentialExchangeRecord

        try rec.assertProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
        try rec.assertState(CredentialState.ProposalReceived)

        guard rec.connectionId != nil else {
            throw CredoError("No connectionId found for credential record '\(rec.id)'. Connection-less issuance does not support negotiation.")
        }

        let formatServices = getFormatServices(options.credentialFormats ?? [:])
        guard !formatServices.isEmpty else { throw CredoError("Unable to create offer. No supported formats.") }

        let params = CreateCredentialParams(
            credentialRecord: rec,
            formatServices: formatServices,
            comment: options.comment,
            goal: options.goal,
            goalCode: options.goalCode,
            credentialFormats: options.credentialFormats
        )
        let offer = try await credentialFormatCoordinator.createOffer(params: params)

        rec.autoAcceptCredential = options.autoAcceptCredential ?? rec.autoAcceptCredential
        
        try await updateState(credentialRecord: &rec,
                              newState: .OfferSent)
        
        return (rec, offer)
    }


    public func createOffer(options: CreateCredentialOfferOptionsV2) async throws
        -> (CredentialExchangeRecord, OfferCredentialMessageV2)
    {
        let formatServices = getFormatServices(options.credentialFormat)
        guard !formatServices.isEmpty else { throw CredoError("Unable to create offer. No supported formats.") }

      
        let rec = CredentialExchangeRecordBuilder()
            .setConnectionId(options.connectionRecord?.id)
            .setThreadId(CredentialExchangeRecord.generateId())
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .setState(CredentialState.OfferSent)
            .setRole(CredentialRole.issuer)
            .setAutoAcceptCredential(options.autoAcceptCredential)
            .build()

        let params = CreateCredentialParams(
            credentialRecord: rec,
            formatServices: formatServices,
            comment: options.comment,
            goal: options.goal,
            goalCode: options.goalCode,
            credentialFormats: options.credentialFormat
        )
        let offer = try await credentialFormatCoordinator.createOffer(params: params)

        logDebug("Saving record and emitting state changed for credential exchange record \(rec.id)")
        try await agent.credentialExchangeRepository.save(rec)
        agent.agentDelegate?.onCredentialStateV2Changed(credentialRecord: rec)
        return (rec, offer)
    }


    public func processOffer(_ messageContext: InboundMessageContext) async throws -> CredentialExchangeRecord {
        let connection = messageContext.connection
        
        let offer: OfferCredentialMessageV2 = try JSONDecoder().decode(OfferCredentialMessageV2.self, from: Data(messageContext.plaintextMessage.utf8))
        
        logDebug("Processing credential offer with id \(offer.id)")

        let rec = try await agent.credentialExchangeRepository.findByThreadRoleAndConnectionId(
            threadId: offer.threadId,
            role: .holder,
            connectionId: connection?.id
        )

        let formatServices = getFormatServicesFromMessage(offer.formats)
        guard !formatServices.isEmpty else { throw CredoError("Unable to process offer. No supported formats") }

        if var record = rec {
            try record.assertProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            try record.assertState(CredentialState.ProposalSent)

            //[TODO]
//                messageContext: messageContext,
//                lastReceivedMessage: offerMsg,
//                lastSentMessage: proposeMsg,
//                expectedConnectionId: record.connectionId
//            )

            let params = ProcessOfferParams(
                credentialExchangeRecord: record,
                message: offer,
                formatService: formatServices
            )
            
            try await credentialFormatCoordinator.processOffer(params: params)

            try await credentialExchangeRepository.save(record)
            
            try await updateState(credentialRecord: &record,
                                  newState: .OfferReceived)
            
            return record
        }

        //[TODO]
        
        let newRec = CredentialExchangeRecordBuilder()
            .setConnectionId(connection?.id)
            .setThreadId(offer.threadId)
            .setParentThreadId(offer.thread?.parentThreadId)
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .setState(CredentialState.OfferReceived)
            .setRole(CredentialRole.holder)
            .setFormats(offer.formats)
            .build()

        let params = ProcessOfferParams(
            credentialExchangeRecord: newRec,
            message: offer,
            formatService: formatServices
        )
        try await credentialFormatCoordinator.processOffer(params: params)

        try await agent.credentialExchangeRepository.save(newRec)
        agent.agentDelegate?.onCredentialStateV2Changed(credentialRecord: newRec)
        return newRec
    }

    public func acceptOffer(options: AcceptCredentialOfferOptionsV2) async throws
        -> (CredentialExchangeRecord, RequestCredentialMessageV2)
    {
        var rec = options.credentialExchangeRecord

        try rec.assertProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
        try rec.assertState(CredentialState.OfferReceived)

        var formatServices = getFormatServicesByList(options.credentialFormats ?? [])
        if formatServices.isEmpty {
            let offer: OfferCredentialMessageV2? = try await agent.didCommMessageRepository.getTypedAgentMessage(
                associatedRecordId: rec.id,
                messageType: OfferCredentialMessageV2.type,
                role: DidCommMessageRole.Receiver
            )
            formatServices = offer.map { getFormatServicesFromMessage($0.formats) } ?? []
        }
        guard !formatServices.isEmpty else {
            throw CredoError("Unable to accept offer. No supported formats provided as input or in offer message")
        }

        let params = AcceptOfferParams(
            credentialRecord: rec,
            formatServices: formatServices,
            comment: options.comment,
            goal: options.goal,
            goalCode: options.goalCode,
            credentialFormats: options.credentialFormats
        )
        
        let request = try await credentialFormatCoordinator.acceptOffer(params: params)

        rec.autoAcceptCredential = options.autoAcceptCredential ?? rec.autoAcceptCredential
        
        try await updateState(credentialRecord: &rec,
                              newState: .RequestSent)
        return (rec, request)
    }


    public func negotiateOffer(options: NegotiateCredentialOfferOptions) async throws
        -> (CredentialExchangeRecord, ProposeCredentialMessageV2)
    {
        var rec = options.credentialExchangeRecord
        try rec.assertProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
        try rec.assertState(CredentialState.OfferReceived)

        guard rec.connectionId != nil else {
            throw CredoError("No connectionId found for credential record '\(rec.id)'. Connection-less issuance does not support negotiation.")
        }

        let formatServices = getFormatServices(options.credentialFormat)
        guard !formatServices.isEmpty else { throw CredoError("Unable to create proposal. No supported formats") }

        let params = CreateProposalParams(
            credentialFormats: options.credentialFormat,
            formatServices: formatServices,
            credentialRecord: rec,
            comment: options.comment,
            goalCode: options.goalCode,
            goal: options.goal
        )
        let proposal = try await credentialFormatCoordinator.createProposal(params: params)

        rec.autoAcceptCredential = options.autoAcceptCredential ?? rec.autoAcceptCredential
        try await updateState(credentialRecord: &rec,
                              newState: .ProposalSent)
        return (rec, proposal)
    }


    public func createRequest(options: CreateCredentialRequestOptions) async throws
        -> (CredentialExchangeRecord, RequestCredentialMessageV2)
    {
        let formatServices = getFormatServicesFromMessage(options.credentialFormats)
        guard !formatServices.isEmpty else { throw CredoError("Unable to create request. No supported formats") }

    
        let rec = CredentialExchangeRecordBuilder()
            .setConnectionId(options.connectionRecord.id)
            .setThreadId(UUID().uuidString)
            .setState(CredentialState.RequestSent)
            .setRole(CredentialRole.holder)
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .setAutoAcceptCredential(options.autoAcceptCredential)
            .build()

        let params = RequestCredentialParams(
            credentialFormats: options.credentialFormats,
            formatServices: formatServices,
            credentialRecord: rec,
            comment: options.comment,
            goalCode: options.goalCode,
            goal: options.goal
        )
        let request = try await credentialFormatCoordinator.createRequest(params: params)

        try await agent.credentialExchangeRepository.save(rec)
        agent.agentDelegate?.onCredentialStateV2Changed(credentialRecord: rec)
        return (rec, request)
    }

   
    public func processRequest(_ messageContext: InboundMessageContext) async throws -> CredentialExchangeRecord {
        let connection = messageContext.connection
        
        let request: RequestCredentialMessageV2 = try JSONDecoder().decode(RequestCredentialMessageV2.self, from: Data(messageContext.plaintextMessage.utf8))
        logDebug("Processing credential request with id \(request.id)")

        let rec = try await agent.credentialExchangeRepository.findSingleByQuery("""
            {"threadId": "\(request.threadId)", "role": "\(CredentialRole.issuer)"}
        """)

        let formatServices = getFormatServicesFromMessage(request.formats)
        guard !formatServices.isEmpty else { throw CredoError("Unable to process proposal. No supported formats") }

        if var record = rec {

            try record.assertProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            try record.assertState(CredentialState.OfferSent)

            //[TODO]
//                messageContext: messageContext,
//                lastReceivedMessage: proposalMsg,
//                lastSentMessage: offerMsg,
//                expectedConnectionId: record.connectionId
//            )

            if record.connectionId == nil {
                try await agent.connectionService.matchIncomingMessageToRequestMessageInOutOfBandExchange(
                    messageContext: messageContext,
                    expectedConnectionId: record.connectionId
                )
                record.connectionId = connection?.id
            }

            let params = ProcessRequestParams(
                credentialExchangeRecord: record,
                message: request,
                formatService: formatServices
            )
            try await credentialFormatCoordinator.processRequest(params: params)

            try await credentialExchangeRepository.save(record)
            try await updateState(credentialRecord: &record,
                                  newState: .RequestReceived)
        
            return record
        }

        //[TODO]

        let newRec = CredentialExchangeRecordBuilder()
            .setConnectionId(connection?.id)
            .setThreadId(request.threadId)
            .setParentThreadId(request.thread?.parentThreadId)
            .setState(CredentialState.RequestReceived)
            .setRole(CredentialRole.issuer)
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .build()

        let params = ProcessRequestParams(
            credentialExchangeRecord: newRec,
            message: request,
            formatService: formatServices
        )
        try await credentialFormatCoordinator.processRequest(params: params)

        try await agent.credentialExchangeRepository.save(newRec)
        agent.agentDelegate?.onCredentialStateV2Changed(credentialRecord: newRec)
        return newRec
    }

    
    public func acceptRequest(options: AcceptRequestOptionsV2) async throws
        -> (CredentialExchangeRecord, IssueCredentialMessageV2)
    {
        var rec = options.credentialExchangeRecord
        
        try rec.assertProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
        try rec.assertState(.RequestReceived)

        var formatServices = getFormatServices(options.credentialFormats ?? [:])
        if formatServices.isEmpty {
            let request: RequestCredentialMessageV2? = try await agent.didCommMessageRepository.getTypedAgentMessage(
                associatedRecordId: rec.id,
                messageType: RequestCredentialMessageV2.type,
                role: .Sender
            )
            formatServices = request.map { getFormatServicesFromMessage($0.formats) } ?? []
        }
        guard !formatServices.isEmpty else {
            throw CredoError("Unable to accept request. No supported formats provided as input or in request message")
        }

        let params = AcceptRequestParams(
            credentialExchangeRecord: rec,
            formatService: formatServices,
            comment: options.comment,
            goal: options.goal,
            goalCode: options.goalCode,
            credentialFormat: options.credentialFormats
        )
        
        let issue = try await credentialFormatCoordinator.acceptRequest(params: params)

        rec.autoAcceptCredential = options.autoAcceptCredential ?? rec.autoAcceptCredential
        
        try await updateState(credentialRecord: &rec,
                              newState: .CredentialIssued)
    
        return (rec, issue)
    }


    public func processCredential(_ messageContext: InboundMessageContext) async throws -> CredentialExchangeRecord {
        let connection = messageContext.connection
        
        let issue: IssueCredentialMessageV2 = try JSONDecoder().decode(IssueCredentialMessageV2.self, from: Data(messageContext.plaintextMessage.utf8))
        logDebug("Processing credential with id \(issue.id)")
        
        var rec = try await agent.credentialExchangeRepository.findByThreadRoleAndConnectionId(
            threadId: issue.threadId,
            role: .holder,
            connectionId: connection?.id
        ) ?? { throw CredoError("Credential exchange record not found") }()
        

        let request: RequestCredentialMessageV2 = try await agent.didCommMessageRepository.getTypedAgentMessage(
            associatedRecordId: rec.id,
            messageType: RequestCredentialMessageV2.type,
            role: .Sender
        ) ?? { throw CredoError("Request message not found") }()

        try rec.assertProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
        try rec.assertState(.RequestSent)

        
        //[TODO]
//            messageContext: messageContext,
//            lastReceivedMessage: request,
//            lastSentMessage: offer,
//            expectedConnectionId: rec.connectionId
//        )

        let formatServices = getFormatServicesFromMessage(issue.formats)
        guard !formatServices.isEmpty else { throw CredoError("Unable to process credential. No supported formats") }

        let params = ProcessCredentialParams(
            credentialExchangeRecord: rec,
            formatService: formatServices,
            requestCredentialMessageV2: request,
            message: issue
        )
        try await credentialFormatCoordinator.processCredential(params: params)
        try await updateState(credentialRecord: &rec,
                              newState: .CredentialReceived)
        return rec
    }

    public func acceptCredential(_ rec: CredentialExchangeRecord) async throws
        -> (CredentialExchangeRecord, CredentialAckMessageV2)
    {
        var record = rec
        try record.assertProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
        try record.assertState(.CredentialReceived)

        let ack = CredentialAckMessageV2(
            threadId: record.threadId,
            status: .OK
        )
        ack.setThread(threadId: record.threadId, parentThreadId: record.parentThreadId)
        
        try await updateState(credentialRecord: &record,
                              newState: .Done)
        logDebug("credential issued done: \(rec)")
        return (rec, ack)
    }

   
    public func processAck(_ messageContext: InboundMessageContext) async throws -> CredentialExchangeRecord {
        let connection = messageContext.connection
        
        let ack: CredentialAckMessageV2 = try JSONDecoder().decode(CredentialAckMessageV2.self, from: Data(messageContext.plaintextMessage.utf8))
        logDebug("Processing credential ack with id \(ack.id)")

        var rec = try await agent.credentialExchangeRepository.getSingleByQuery("""
            {"threadId": "\(ack.threadId)", "role": "\(CredentialRole.issuer)", "connectionId": "\(connection?.id ?? "")"}
        """)
        rec.connectionId = connection?.id

        try rec.assertState(.CredentialIssued)

        //[TODO]
//            messageContext: messageContext,
//            lastReceivedMessage: request,
//            lastSentMessage: issue,
//            expectedConnectionId: rec.connectionId
//        )

        try await updateState(credentialRecord: &rec,
                              newState: .Done)
        
        logDebug("credential issued done: \(rec)")
        return rec
    }


    public func createProblemReport(options: CreateCredentialProblemReportOptions) async throws
        -> (CredentialExchangeRecord, CredentialProblemReportMessageV2)
    {
        let rec = options.credentialExchangeRecord
        let msg = CredentialProblemReportMessageV2(
            description: DescriptionOptions(
                en: options.description,
                code: CredentialProblemReportReason.issuanceAbandoned.rawValue
            )
        )
        msg.setThread(threadId: rec.threadId, parentThreadId: rec.parentThreadId)
        return (rec, msg)
    }

  
    public func declineOffer(credentialRecord record: CredentialExchangeRecord,
                             options: DeclineCredentialOfferOptions) async throws -> CredentialExchangeRecord {
        
        var rec = record
        try rec.assertProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
        try rec.assertState(.OfferReceived)

        if options.sendProblemReport == true {
            let sendOpts = SendCredentialProblemReportOptions(
                credentialRecordId: rec.id,
                description: options.problemReportDescription ?? "offer declined"
            )
            _ = try await sendProblemReport(sendOpts)
        }

        try await updateState(credentialRecord: &rec,
                              newState: .Declined)
        return rec
    }

  
    public func sendProblemReport(_ options: SendCredentialProblemReportOptions) async throws -> CredentialExchangeRecord {
        let rec = try await agent.credentialExchangeRepository.getById(options.credentialRecordId)
        let _ = await agent.credentialServiceV2.findOfferMessage(credentialExchangeId: rec.id)

        let (_, problem) = try await createProblemReport(
            options: CreateCredentialProblemReportOptions(credentialExchangeRecord: rec, description: options.description)
        )

        var connection: ConnectionRecord? = nil
        if let id = rec.connectionId {
            connection = try await agent.connectionService.getById(id: id)
        }
        try connection?.assertReady()

        if connection == nil {
            try rec.assertState(.OfferReceived)
        }

        try await agent.messageSender.send(message:
                                            OutboundMessage(
                                                payload: problem,
                                                connection: connection!
                                            )
        )
        return rec
    }



    public func shouldAutoRespondToProposal(credentialRecord rec: CredentialExchangeRecord,
                                            messageContext: InboundMessageContext) async throws -> Bool {
        
        let proposal: ProposeCredentialMessageV2 = try JSONDecoder().decode(ProposeCredentialMessageV2.self, from: Data(messageContext.plaintextMessage.utf8))

        let autoAccept = composeAutoAccept(
            recordConfig: rec.autoAcceptCredential,
            agentConfig: agent.agentConfig.autoAcceptCredential)
        
        if autoAccept == .always { return true }
        if autoAccept == .never  { return false }

        guard let offer = await findOfferMessage(credentialExchangeId: rec.id) else { return false }

        let formatServices = getFormatServicesFromMessage(offer.formats)
        for formatService in formatServices {
            let offerAtt = try credentialFormatCoordinator.getAttachmentForService(
                credentialFormatService: formatService,
                formats: offer.formats,
                attachments: offer.offerAttachments
            )
          
            let proposalAtt = try credentialFormatCoordinator.getAttachmentForService(
                credentialFormatService: formatService,
                formats: proposal.formats,
                attachments: proposal.proposalAttachments
            )
            let ok = try await formatService.shouldAutoRespondToProposal(
                credentialRecord: rec, offerAttachment: offerAtt, proposalAttachment: proposalAtt
            )
            if !ok { return false }
        }

        if proposal.credentialPreview != nil || offer.credentialPreview != nil {
            guard let p = proposal.credentialPreview, let o = offer.credentialPreview else { return false }
            return arePreviewAttributesEqual(p.attributes, o.attributes)
        }
        return true
    }

    public func shouldAutoRespondToOffer(credentialRecord rec: CredentialExchangeRecord,
                                         messageContext: InboundMessageContext) async throws -> Bool {
    
        let offer: OfferCredentialMessageV2 = try JSONDecoder().decode(OfferCredentialMessageV2.self, from: Data(messageContext.plaintextMessage.utf8))
        
        let autoAccept = composeAutoAccept(
            recordConfig: rec.autoAcceptCredential,
            agentConfig: agent.agentConfig.autoAcceptCredential)
        
        switch autoAccept {
            case .always: return true
            case .never:  return false
        }

        guard let proposal = await findProposalMessage(credentialExchangeId: rec.id) else { return false }
        let formatServices = getFormatServicesFromMessage(proposal.formats)

        for formatService in formatServices {
            let offerAtt = try credentialFormatCoordinator.getAttachmentForService(
                credentialFormatService: formatService,
                formats: offer.formats,
                attachments: offer.offerAttachments
            )
            let proposalAtt = try credentialFormatCoordinator.getAttachmentForService(
                credentialFormatService: formatService,
                formats: proposal.formats,
                attachments: proposal.proposalAttachments
            )
            
            let ok = try await formatService.shouldAutoRespondToOffer(
                credentialRecord: rec,
                offerAttachment: offerAtt,
                proposalAttachment: proposalAtt)
            if !ok { return false }
        }

        let offerPreview = offer.credentialPreview?.attributes ?? []
        let proposalPreview = proposal.credentialPreview?.attributes ?? []
        return arePreviewAttributesEqual(proposalPreview, offerPreview)
    }

    public func shouldAutoRespondToRequest(credentialRecord rec: CredentialExchangeRecord,
                                           messageContext: InboundMessageContext) async throws -> Bool {
       
        let request: RequestCredentialMessageV2 = try JSONDecoder().decode(RequestCredentialMessageV2.self, from: Data(messageContext.plaintextMessage.utf8))
        
        let autoAccept = composeAutoAccept(
            recordConfig: rec.autoAcceptCredential,
            agentConfig: agent.agentConfig.autoAcceptCredential)
        
        if autoAccept == .always { return true }
        if autoAccept == .never  { return false }

        guard
            let proposal = await findProposalMessage(credentialExchangeId: rec.id),
            let offer    = await findOfferMessage(credentialExchangeId: rec.id)
        else { return false }

        let services = getFormatServicesFromMessage(offer.formats)
        for svc in services {
            let offerAtt = try credentialFormatCoordinator.getAttachmentForService(
                credentialFormatService: svc,
                formats: offer.formats,
                attachments: offer.offerAttachments)
            
            let proposalAtt = try credentialFormatCoordinator.getAttachmentForService(
                credentialFormatService: svc,
                formats: proposal.formats,
                attachments: proposal.proposalAttachments)
            
            let requestAtt = try credentialFormatCoordinator.getAttachmentForService(
                credentialFormatService: svc,
                formats: request.formats,
                attachments: request.requestAttachments)

            let ok = try await svc.shouldAutoRespondToRequest(
                credentialRecord: rec,
                offerAttachment: offerAtt,
                requestAttachment: requestAtt,
                proposalAttachment: proposalAtt)
            if !ok { return false }
        }
        return true
    }

    public func shouldAutoRespondToCredential(credentialRecord rec: CredentialExchangeRecord,
                                              messageContext: InboundMessageContext) async throws -> Bool {
        
        let issue: IssueCredentialMessageV2 = try JSONDecoder().decode(IssueCredentialMessageV2.self, from: Data(messageContext.plaintextMessage.utf8))
        
        let autoAccept = composeAutoAccept(
            recordConfig: rec.autoAcceptCredential,
            agentConfig: agent.agentConfig.autoAcceptCredential)
        
        if autoAccept == .always { return true }
        if autoAccept == .never  { return false }

        guard
            let proposal = await findProposalMessage(credentialExchangeId: rec.id),
            let offer    = await findOfferMessage(credentialExchangeId: rec.id),
            let request  = await findRequestMessage(credentialExchangeId: rec.id)
        else { return false }

        let services = getFormatServicesFromMessage(offer.formats)
        for svc in services {
            
            let offerAtt = try credentialFormatCoordinator.getAttachmentForService(
                credentialFormatService: svc,
                formats: offer.formats,
                attachments: offer.offerAttachments)
            let proposalAtt = try credentialFormatCoordinator.getAttachmentForService(
                credentialFormatService: svc,
                formats: proposal.formats,
                attachments: proposal.proposalAttachments)
            let requestAtt = try credentialFormatCoordinator.getAttachmentForService(
                credentialFormatService: svc,
                formats: request.formats,
                attachments: request.requestAttachments)
            let issueAtt   = try credentialFormatCoordinator.getAttachmentForService(
                credentialFormatService: svc,
                formats: issue.formats,
                attachments: issue.credentialAttachments)

            let ok = try await svc.shouldAutoRespondToCredential(
                credentialRecord: rec,
                offerAttachment: offerAtt,
                issueAttachment: issueAtt,
                requestAttachment: requestAtt,
                proposalAttachment: proposalAtt)
            if !ok { return false }
        }
        return true
    }

    // MARK: - Find Messages
    public func findProposalMessage(credentialExchangeId: String) async -> ProposeCredentialMessageV2? {
        await findMessage(credentialExchangeId: credentialExchangeId, messageType: ProposeCredentialMessageV2.type)
    }


    public func findRequestMessage(credentialExchangeId: String) async -> RequestCredentialMessageV2? {
        await findMessage(credentialExchangeId: credentialExchangeId, messageType: RequestCredentialMessageV2.type)
    }

    public func findOfferMessage(credentialExchangeId: String) async -> OfferCredentialMessageV2? {
        await findMessage(credentialExchangeId: credentialExchangeId, messageType: OfferCredentialMessageV2.type)
    }

    private func findMessage<T: Decodable>(
        credentialExchangeId: String,
        messageType: String
    ) async -> T? {
        do {
        
            let messageStr = try await agent.didCommMessageRepository.getAgentMessage(
                associatedRecordId: credentialExchangeId,
                messageType: messageType
            )

            logDebug("messageStr: \(messageStr)")

            let data = Data(messageStr.utf8)
            let message = try JSONDecoder().decode(T.self, from: data)
            return message
        } catch {
            logger.warning("Failed to deserialize \(String(describing: T.self)) for record ID \(credentialExchangeId): \(error.localizedDescription)")
            return nil
        }
    }

    private func getFormatServices(_ credentialFormats: [String: Any]) -> [any CredentialFormatService] {
        var seen = Set<String>()
            return credentialFormats.keys.compactMap { getFormatServiceForFormatKey($0) }
                .filter { service in
                    guard !seen.contains(service.formatKey) else { return false }
                    seen.insert(service.formatKey)
                    return true
                }
    }

    private func getFormatServicesByList(_ credentialFormats: [Format]) -> [any CredentialFormatService] {
        var seen = Set<String>()
            return credentialFormats.compactMap { getFormatServiceForFormat($0.attachId) }
                .filter { service in
                    guard !seen.contains(service.formatKey) else { return false }
                    seen.insert(service.formatKey)
                    return true
                }
    }

    private func getFormatServiceForFormatKey(_ formatKey: String) -> (any CredentialFormatService)? {
        credentialFormats.first { $0.formatKey == formatKey }
    }

    private func getFormatServiceForFormat(_ format: String) -> (any CredentialFormatService)? {
        credentialFormats.first { $0.supportsFormat(format) }
    }

    internal func getFormatServiceForRecordType(_ recordType: String) throws -> (any CredentialFormatService) {
        guard let svc = credentialFormats.first(where: { $0.credentialRecordType == recordType }) else {
            throw CredoError("No format service found for credential record type \(recordType) in v2 credential protocol")
        }
        return svc
    }

    private func getFormatServicesFromMessage(_ messageFormats: [Format]) -> [any CredentialFormatService] {
        var seenKeys = Set<String>()
        return messageFormats.compactMap { getFormatServiceForFormat($0.format) }
            .filter { service in
                let key = service.formatKey
                guard !seenKeys.contains(key) else { return false }
                seenKeys.insert(key)
                return true
            }
    }

    private func arePreviewAttributesEqual(
        _ first: [CredentialPreviewAttribute],
        _ second: [CredentialPreviewAttribute]
    ) -> Bool {
        guard first.count == second.count else { return false }

        if Set(first.map(\.name)).count != first.count { return false }
        if Set(second.map(\.name)).count != second.count { return false }

        let secondMap = Dictionary(uniqueKeysWithValues: second.map { ($0.name, $0) })
        for a in first {
            guard let b = secondMap[a.name] else { return false }
            if a.value != b.value { return false }
            if a.mimeType != b.mimeType { return false }
        }
        return true
    }

    private func updateState(credentialRecord: inout CredentialExchangeRecord, newState: CredentialState) async throws {
        credentialRecord.state = newState
        try await credentialExchangeRepository.update(credentialRecord)
        agent.agentDelegate?.onCredentialStateV2Changed(credentialRecord: credentialRecord)
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>(); return filter { set.insert($0).inserted }
    }
}
