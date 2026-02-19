import Foundation
import os

public class ProofCommand {
    let agent: Agent
    let logger = Logger(subsystem: "AriesFramework", category: "ProofCommand")

    init(agent: Agent, dispatcher: Dispatcher) {
        self.agent = agent
        registerHandlers(dispatcher: dispatcher)
        registerMessages()
    }

    private func registerHandlers(dispatcher: Dispatcher) {
        dispatcher.registerHandler(handler: RequestPresentationHandler(agent: agent))
        dispatcher.registerHandler(handler: PresentationHandler(agent: agent))
        dispatcher.registerHandler(handler: PresentationAckHandler(agent: agent))
        dispatcher.registerHandler(handler: RequestPresentationHandlerV2(agent: agent))
        dispatcher.registerHandler(handler: PresentationHandlerV2(agent: agent))
        dispatcher.registerHandler(handler: PresentationAckHandlerV2(agent: agent))
    }
    
    private func registerMessages() {
        MessageSerializer.registerMessage(type: RequestPresentationMessage.type, clazz: RequestPresentationMessage.self)
        MessageSerializer.registerMessage(type: PresentationMessage.type, clazz: PresentationMessage.self)
        MessageSerializer.registerMessage(type: RequestPresentationMessage.type, clazz: RequestPresentationMessage.self)
        MessageSerializer.registerMessage(type: PresentationAckMessage.type, clazz: PresentationAckMessage.self)
        MessageSerializer.registerMessage(type: PresentationMessageV2.type, clazz: PresentationMessageV2.self)
        MessageSerializer.registerMessage(type: RequestPresentationMessageV2.type, clazz: RequestPresentationMessageV2.self)
        
    }

    /**
     Initiate a new presentation exchange as verifier by sending a presentation request message
     to the connection with the specified connection id.

     - Parameters:
        - connectionId: the connection to send the proof request to.
        - proofRequest: the proof request to send.
        - comment: a comment to include in the proof request message.
        - autoAcceptProof: whether to automatically accept the proof message.
     - Returns: a new proof record for the proof exchange.
    */
    public func requestProof(
        connectionId: String,
        proofRequest: ProofRequest,
        comment: String? = nil,
        autoAcceptProof: AutoAcceptProof? = nil) async throws -> ProofExchangeRecord {

        let connection = try await agent.connectionRepository.getById(connectionId)
        let (message, record) = try await agent.proofService.createRequest(
            proofRequest: proofRequest,
            connectionRecord: connection,
            comment: comment,
            autoAcceptProof: autoAcceptProof)

        try await agent.messageSender.send(message: OutboundMessage(payload: message, connection: connection))

        return record
    }

    /**
     Accept a presentation request as prover (by sending a presentation message) to the connection
     associated with the proof record.

     - Parameters:
        - proofRecordId: the id of the proof record for which to accept the request.
        - requestedCredentials: the requested credentials object specifying which credentials to use for the proof.
        - comment: a comment to include in the presentation message.
     - Returns: proof record associated with the sent presentation message.
    */
    public func acceptRequest(
        proofRecordId: String,
        requestedCredentials: RequestedCredentials,
        comment: String? = nil) async throws -> ProofExchangeRecord {
            
    do {
        try await agent.didCommMessageRepository.getAgentMessage(
            associatedRecordId: proofRecordId,
            messageType: RequestPresentationMessageV2.type)
        let record = try await agent.proofRepository.getById(proofRecordId)
        let (message, proofRecord) = try await agent.proofService.createPresentation(
            proofRecord: record,
            requestedCredentials: requestedCredentials,
            comment: comment)

        let connection = try await agent.connectionRepository.getById(record.connectionId)

        try await agent.messageSender.send(message: OutboundMessage(payload: message, connection: connection))

        return proofRecord
    } catch {
        let record = try await agent.proofRepository.getById(proofRecordId)
        let (message, proofRecord) = try await agent.proofService.createPresentationV1(
            proofRecord: record,
            requestedCredentials: requestedCredentials,
            comment: comment)

        let connection = try await agent.connectionRepository.getById(record.connectionId)
        
        try await agent.messageSender.send(message: OutboundMessage(payload: message, connection: connection))

        return proofRecord
    }
}

    /**
     Decline a presentation request as prover (by sending a presentation problem report message) to the connection
     associated with the proof record.

     - Parameter proofRecordId: the id of the proof record for which to decline the request.
     - Returns: proof record associated with the sent presentation problem report message.
    */
    public func declineRequest(proofRecordId: String) async throws -> ProofExchangeRecord {
        let record = try await agent.proofRepository.getById(proofRecordId)
        let (message, proofRecord) = try await agent.proofService.createPresentationDeclinedProblemReport(proofRecord: record)

        let connection = try await agent.connectionRepository.getById(record.connectionId)
        try await agent.messageSender.send(message: OutboundMessage(payload: message, connection: connection))
        return proofRecord
    }

    /**
     Accept a presentation as verifier (by sending a presentation acknowledgement message) to the connection
     associated with the proof record.

     - Parameter proofRecordId: the id of the proof record for which to accept the presentation.
     - Returns: proof record associated with the sent presentation acknowledgement message.
    */
    public func acceptPresentation(proofRecordId: String) async throws -> ProofExchangeRecord {
        let record = try await agent.proofRepository.getById(proofRecordId)
        let connection = try await agent.connectionRepository.getById(record.connectionId)
        let (message, proofRecord) = try await agent.proofService.createAck(proofRecord: record)
        try await agent.messageSender.send(message: OutboundMessage(payload: message, connection: connection))
        return proofRecord
    }

    /**
     Create a ``RetrievedCredentials`` object. Given input proof request,
     use credentials in the wallet to build indy requested credentials object for proof creation.

     - Parameters proofRecordId: the id of the proof request to get the matching credentials for.
     - Returns: ``RetrievedCredentials`` object.
    */
    public func getRequestedCredentialsForProofRequest(proofRecordId: String) async throws -> RetrievedCredentials {
        let record = try await agent.proofRepository.getById(proofRecordId)
        
        let recordMessageType = try await agent.didCommMessageRepository.getSingleByQuery("{\"associatedRecordId\": \"\(proofRecordId)\"}")
        
        logDebug("Select Version 1.0")
        let proofRequestMessageJson = try await agent.didCommMessageRepository.getAgentMessage(
            associatedRecordId: record.id,
            messageType: RequestPresentationMessage.type
        )
        
        let proofRequestMessage = try JSONDecoder().decode(RequestPresentationMessage.self, from: proofRequestMessageJson.data(using: .utf8)!)
        let proofRequestJson = try proofRequestMessage.indyProofRequest()
        
        logDebug("Proof request json: \(proofRequestJson)")
        
        let proofRequest = try JSONDecoder().decode(ProofRequest.self, from: Data(proofRequestJson.utf8))
        return try await agent.proofService.getRequestedCredentialsForProofRequest(proofRequest: proofRequest)
    }

}
