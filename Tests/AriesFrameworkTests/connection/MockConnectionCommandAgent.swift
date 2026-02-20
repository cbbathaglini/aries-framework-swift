//
//  MockConnectionCommandAgent.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework

final class MockConnectionCommandAgent: ConnectionCommandAgentProtocol {

    var agentConfig: AgentConfig

    var mediationRecipient: MediationRecipientProtocol!

    var connectionService: ConnectionServiceProtocol!

    var didExchangeService: DidExchangeServiceProtocol!

    var messageSender: MessageSenderProtocol!

    init(
        agentConfig: AgentConfig,
        mediationRecipient: MediationRecipientProtocol,
        connectionService: ConnectionServiceProtocol,
        didExchangeService: DidExchangeServiceProtocol,
        messageSender: MessageSenderProtocol
    ) {
        self.agentConfig = agentConfig
        self.mediationRecipient = mediationRecipient
        self.connectionService = connectionService
        self.didExchangeService = didExchangeService
        self.messageSender = messageSender
    }
}
