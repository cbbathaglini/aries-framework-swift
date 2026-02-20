//
//  BasicMessageCommand.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/03/25.
//

import Foundation
import os

public class BasicMessageCommand {

    private let agent: BasicMessageHandlerAgentProtocol
    private let logger = Logger(subsystem: "AriesFramework", category: "BasicMessageCommand")

    public init(
        agent: BasicMessageHandlerAgentProtocol,
        dispatcher: DispatcherProtocol
    ) {
        self.agent = agent
        registerHandlers(dispatcher: dispatcher)
        registerMessages()
    }

    private func registerHandlers(dispatcher: DispatcherProtocol) {
        dispatcher.registerHandler(
            handler: BasicMessageHandler(agent: agent)
        )
    }

    private func registerMessages() {
        MessageSerializer.registerMessage(
            type: BasicMessage.type,
            clazz: BasicMessage.self
        )
    }
}
