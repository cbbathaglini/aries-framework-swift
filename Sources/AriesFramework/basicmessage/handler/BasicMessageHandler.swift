//
//  BasicMessageHandler.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/03/25.
//

import Foundation

class BasicMessageHandler: MessageHandler {
    let agent: Agent
    let messageType = BasicMessage.type

    init(agent: Agent) {
        self.agent = agent
    }

    func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        let basicMessage = try JSONDecoder().decode(BasicMessage.self, from: Data(messageContext.plaintextMessage.utf8))

        let basicMessageRecord = BasicMessageRecord(
            content: basicMessage.content,
            connectionRecord: messageContext.connection
        )
        
        try await agent.basicMessageRepository.save(basicMessageRecord)
        print("basic messsage: \(basicMessageRecord)")

        agent.agentDelegate?.onBasicMessageChanged(record: basicMessageRecord)
        return nil
    }
}
