//
//  PresentationAckHandlerV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 20/03/25.
//

import Foundation
import os

class PresentationAckHandlerV2: MessageHandler {

    let agent: Agent
    let messageType = PresentationAckMessageV2.type

    init(agent: Agent) {
        self.agent = agent
    }

    func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        logDebug("[init] handler of PresentationAckHandlerV2")
        _ = try await agent.proofServiceV2.processAck(messageContext: messageContext)

        return nil
    }
}
