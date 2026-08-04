//
//  RequestPresentationHandlerV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 20/03/25.
//

import Foundation
import os

class RequestPresentationHandlerV2: MessageHandler {
    let agent: Agent
    let logger = Logger(subsystem: "app.agent", category: "RequestPresentationHandlerV2")

    var messageType: String {
        return RequestPresentationMessageV2.type
    }

    init(agent: Agent) {
        self.agent = agent
    }

    func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        logDebug("Entering in RequestPresentationHandlerV2")

        let proofRecord = try await agent.proofServiceV2.processRequest(messageContext: messageContext, requestMessage: nil)
        
        if proofRecord.autoAcceptProof == .always || agent.agentConfig.autoAcceptProof == .always {
            return try await createPresentation(record: proofRecord, messageContext: messageContext)
        }

        return nil
    }

    private func createPresentation(record: ProofExchangeRecord, messageContext: InboundMessageContext) async throws -> OutboundMessage? {

        let retrievedCredentials = try await ProofUtils.getRequestedCredentialsForProofRequest(
            proofRecordId: record.id,
            agent: agent
        )

        let requestedCredentials = try await agent.proofServiceV2.autoSelectCredentialsForProofRequest(retrievedCredentials: retrievedCredentials)


        let params = AcceptProofRequestOptions(
            proofRecord: record,
            proofFormats: record.formats ?? [],
            requestedCredentials: requestedCredentials.toMap()
        )

        let (message, _) = try await agent.proofServiceV2.acceptRequest(params: params)
        return OutboundMessage(payload: message, connection: messageContext.connection!)
    }
}
