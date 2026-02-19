//
//  BasicMessageCommand.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/03/25.
//

import Foundation
import os
public class BasicMessageCommand {
    let agent: Agent
    let logger = Logger(subsystem: "AriesFramework", category: "BasicMessageCommand")
    
    init(agent: Agent, dispatcher: Dispatcher) {
        self.agent = agent
        registerHandlers(dispatcher: dispatcher)
        registerMessages()
    }
    
    private func registerHandlers(dispatcher: Dispatcher) {
        dispatcher.registerHandler(handler: BasicMessageHandler(agent: agent))
    }
    
    private func registerMessages() {
        MessageSerializer.registerMessage(type: BasicMessage.type, clazz: BasicMessage.self)
    }
    
}
