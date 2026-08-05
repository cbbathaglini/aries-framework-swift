//
//  PresentationHandlerV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 20/03/25.
//
import Foundation
import os

class PresentationHandlerV2: MessageHandler {
    let logger = Logger(subsystem: "AriesFramework", category: "PresentationHandlerV2")
    let agent: Agent
    let messageType = PresentationMessageV2.type

    init(agent: Agent) {
        self.agent = agent
    }

    func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        logDebug("Entering in PresentationHandlerV2")
        var proofRecord = try await agent.proofServiceV2.processPresentation(messageContext: messageContext)

        if (proofRecord.autoAcceptProof != nil &&
            proofRecord.autoAcceptProof! == .always) ||
            agent.agentConfig.autoAcceptProof == .always {
            let (message, _) = try await agent.proofServiceV2.createAck(proofRecord: &proofRecord)
            return OutboundMessage(payload: message, connection: messageContext.connection!)
        }

        return nil
    }
}
