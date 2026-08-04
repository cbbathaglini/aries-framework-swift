
import Foundation
import os
public class CredentialsCommandV2 {
    let agent: Agent
    let logger = Logger(subsystem: "AriesFramework", category: "CredentialsCommandV2")
    
    let historyService : HistoryService
    
    init(agent: Agent, dispatcher: Dispatcher) {
        self.agent = agent
        self.historyService = HistoryService(historyRepository: agent.historyRepository)
        registerHandlers(dispatcher: dispatcher)
        registerMessages()
    }
    
    private func registerHandlers(dispatcher: Dispatcher) {
        dispatcher.registerHandler(handler: CredentialAckHandlerV2(agent: agent))
        dispatcher.registerHandler(handler: RequestCredentialHandlerV2(agent: agent))
        dispatcher.registerHandler(handler: IssueCredentialHandlerV2(agent: agent))
        dispatcher.registerHandler(handler: OfferCredentialHandlerV2(agent: agent))
    }
    
    private func registerMessages() {
        MessageSerializer.registerMessage(type: CredentialAckMessageV2.type, clazz: CredentialAckMessageV2.self)
        MessageSerializer.registerMessage(type: IssueCredentialMessageV2.type, clazz: IssueCredentialMessageV2.self)
        MessageSerializer.registerMessage(type: OfferCredentialMessageV2.type, clazz: OfferCredentialMessageV2.self)
        MessageSerializer.registerMessage(type: ProposeCredentialMessageV2.type, clazz: ProposeCredentialMessageV2.self)
        MessageSerializer.registerMessage(type: RequestCredentialMessageV2.type, clazz: RequestCredentialMessageV2.self)
    }
    
    func proposeCredential(options: CreateProposalOptionsV2) async throws -> CredentialExchangeRecord {
        let connectionRecord = try await agent.connectionService.getById(id: options.connection.id)
        try connectionRecord.assertReady()
        
        let (message, credentialRecord) = try await agent.credentialServiceV2.createProposal(options: options)
        
        try await agent.messageSender.send(
            message: OutboundMessage(
                payload: message,
                connection: options.connection
            )
        )
        
        return credentialRecord
    }
    
    
    func negotiateProposal(options: NegotiateCredentialProposalOptions) async throws -> CredentialExchangeRecord {
        let credentialExchangeRecord = try await getById(id: options.credentialExchangeRecord.id)
        
        guard let connectionId = credentialExchangeRecord.connectionId else {
            throw AriesFrameworkError.frameworkError("No connection id for credential record \(credentialExchangeRecord.id). Connection-less issuance does not support negotiation")
        }
        
        let (credentialExchange, offerCredentialMessage) = try await agent.credentialServiceV2.negotiateProposal(options: options)
        
        let connectionRecord = try await agent.connectionService.getById(id: connectionId)
        
        try await agent.messageSender.send(
            message: OutboundMessage(
                payload: offerCredentialMessage,
                connection: connectionRecord
            )
        )
        
        return credentialExchange
    }
    

    func offerCredential(options: OfferCredentialOptions) async throws -> CredentialExchangeRecord {
        let connectionRecord = try await agent.connectionService.getById(id: options.connectionId)
        logDebug("Got a credentialProtocol object for version \(options.protocolVersion)")
        
        let createOfferOptions = CreateCredentialOfferOptionsV2(
            credentialFormat: options.credentialFormat,
            autoAcceptCredential: options.autoAcceptCredential,
            comment: options.comment,
            goal: options.goal,
            goalCode: options.goalCode,
            connectionRecord: connectionRecord
        )
        
        let result = try await agent.credentialServiceV2.createOffer(options: createOfferOptions)
        let credentialExchangeRecord : CredentialExchangeRecord = result.0
        let offerCredentialMessage : OfferCredentialMessageV2 = result.1
        
        logDebug("Offer Message successfully created: \(offerCredentialMessage)")
        
        try await agent.messageSender.send(
            message: OutboundMessage(
                payload: offerCredentialMessage,
                connection: connectionRecord)
        )
        
        return credentialExchangeRecord
    }
    
    
    func negotiateOffer(options: NegotiateCredentialOfferOptions) async throws -> CredentialExchangeRecord {
        let credentialExchangeRecord = try await getById(id: options.credentialExchangeRecord.id)
        
        guard let connectionId = credentialExchangeRecord.connectionId else {
            throw AriesFrameworkError.frameworkError("No connection id for credential record \(credentialExchangeRecord.id). Connection-less issuance does not support negotiation.")
        }
        
        let connectionRecord = try await agent.connectionService.getById(id: connectionId)
        try connectionRecord.assertReady()
        
        let result = try await agent.credentialServiceV2.negotiateOffer(options: options)
        let credentialExchange = result.0
        let proposeCredentialMessageV2 = result.1
        
        try await agent.messageSender.send(
            message: OutboundMessage(
                payload: proposeCredentialMessageV2,
                connection: connectionRecord
            )
        )
        
        return credentialExchange
    }
    
    public func acceptOffer(options: AcceptCredentialOfferOptionsV2) async throws -> CredentialExchangeRecord {
        let (credentialExchange, message) = try await agent.credentialServiceV2.acceptOffer(options: options)
        
        guard let connectionId = credentialExchange.connectionId else {
            throw AriesFrameworkError.frameworkError("Missing connectionId in CredentialExchangeRecord.")
        }
        let connectionRecord = try await agent.connectionRepository.getById(connectionId)
        
        try await agent.messageSender.send(
            message: OutboundMessage(
                payload: message,
                connection: connectionRecord
            )
        )
        
        let historyRecord = HistoryRecord(
            historyType: HistoryType.credentialOfferAccepted,
            connectionId: connectionRecord.id,
            associatedRecordId: credentialExchange.id,
            theirLabel: connectionRecord.theirLabel,
            credentials: credentialExchange.credentials,
            credentialPreviewAttr: credentialExchange.credentialAttributes
        )
        try await agent.historyRepository.save(historyRecord)
        return credentialExchange
    }
    
    public func declineOffer(credentialRecordId: String, options: DeclineCredentialOfferOptions) async throws -> CredentialExchangeRecord {
        let credentialRecord = try await agent.credentialExchangeRepository.getById(credentialRecordId)
        let _ = try await  agent.credentialServiceV2.declineOffer(credentialRecord: credentialRecord, options: options)
        
        guard let connectionId = credentialRecord.connectionId else {
            throw AriesFrameworkError.frameworkError("Missing connectionId in CredentialExchangeRecord.")
        }
        let connectionRecord = try await agent.connectionRepository.getById(connectionId)

        let historyRecord = HistoryRecord(
            historyType: HistoryType.credentialOfferAccepted,
            connectionId: connectionRecord.id,
            associatedRecordId: credentialRecord.id,
            theirLabel: connectionRecord.theirLabel,
            credentialPreviewAttr: credentialRecord.credentialAttributes
        )
        try await agent.historyRepository.save(historyRecord)
        
        return credentialRecord
    }
    
  
    private func getById(id: String) async throws -> CredentialExchangeRecord {
        return try await agent.credentialExchangeRepository.getById(id)
    }
    
}
