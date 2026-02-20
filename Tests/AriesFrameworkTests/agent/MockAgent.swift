//
//  MockAgent.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework


final class MockAgent: BasicMessageHandlerAgentProtocol {

    var basicMessageRepository: BasicMessageRepositoryProtocol!
    var agentDelegate: AgentDelegate?

    init(
        repository: BasicMessageRepositoryProtocol = MockBasicMessageRepository(),
        delegate: AgentDelegate? = nil
    ) {
        self.basicMessageRepository = repository
        self.agentDelegate = delegate
    }
}
