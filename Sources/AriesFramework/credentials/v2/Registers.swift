//
//  Registers.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public final class Registers {
    private let agent: Agent

    public init(agent: Agent) {
        self.agent = agent
    }

    public func initialize() {
        registerHandlers(dispatcher: agent.dispatcher)
        registerMessages()
    }

    private func registerHandlers(dispatcher: Dispatcher) {
        dispatcher.registerHandler(handler: CredentialAckHandlerV2(agent: agent))
        dispatcher.registerHandler(handler: IssueCredentialHandlerV2(agent: agent))
        dispatcher.registerHandler(handler: OfferCredentialHandlerV2(agent: agent))
        dispatcher.registerHandler(handler: RequestCredentialHandlerV2(agent: agent))
    }

    private func registerMessages() {
        MessageSerializer.registerMessage(
            type: CredentialAckMessageV2.type,
            clazz: CredentialAckMessageV2.self
        )
        MessageSerializer.registerMessage(
            type: IssueCredentialMessageV2.type,
            clazz: IssueCredentialMessageV2.self
        )
        MessageSerializer.registerMessage(
            type: OfferCredentialMessageV2.type,
            clazz: OfferCredentialMessageV2.self
        )
        MessageSerializer.registerMessage(
            type: ProposeCredentialMessageV2.type,
            clazz: ProposeCredentialMessageV2.self
        )
        MessageSerializer.registerMessage(
            type: RequestCredentialMessageV2.type,
            clazz: RequestCredentialMessageV2.self
        )
    }
}
