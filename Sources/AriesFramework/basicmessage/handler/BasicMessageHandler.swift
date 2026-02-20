//
//  BasicMessageHandler.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/03/25.
//

import Foundation

class BasicMessageHandler: MessageHandler {
    let agent: BasicMessageHandlerAgentProtocol
    let messageType = BasicMessage.type

    init(agent: BasicMessageHandlerAgentProtocol) {
        self.agent = agent
    }

    func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {

        guard let repository = agent.basicMessageRepository else {
            throw AriesFrameworkError.frameworkError(
                "BasicMessageRepository not initialized"
            )
        }

        let basicMessage = try JSONDecoder().decode(
            BasicMessage.self,
            from: Data(messageContext.plaintextMessage.utf8)
        )

        let record = BasicMessageRecord(
            content: basicMessage.content,
            connectionRecord: messageContext.connection
        )

        try await repository.save(record)
        agent.agentDelegate?.onBasicMessageChanged(record: record)

        return nil
    }
}
