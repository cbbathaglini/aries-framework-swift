//
//  JwsTestAgent.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework

enum AgentTestFactory {

    static func jwsAgent(
        wallet: WalletProtocol = MockWallet()
    ) -> Agent {

        let agent = Agent(
            agentConfig: .test(),
            agentDelegate: nil
        )

        agent.wallet = wallet

        return agent
    }
}
