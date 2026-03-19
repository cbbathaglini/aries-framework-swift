//
//  MockProofCommandAgent.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/26.
//

@testable import AriesFramework

final class MockProofCommandAgent: Agent {

    init(
        agentConfig: AgentConfig,
        connectionRepository: ConnectionRepositoryProtocol,
        messageSender: MessageSenderProtocol
    ) {
        super.init(agentConfig: agentConfig, agentDelegate: nil)

        self.connectionRepository = connectionRepository
        self.messageSender = messageSender
    }
}
