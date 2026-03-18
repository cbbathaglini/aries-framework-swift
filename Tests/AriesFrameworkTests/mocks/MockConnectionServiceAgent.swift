//
//  MockConnectionServiceAgent.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework

final class MockConnectionServiceAgent: ConnectionServiceAgentProtocol {

    let agentConfig: AgentConfig

    let connectionRepository: ConnectionRepositoryProtocol!
    let mediationRecipient: MediationRecipientProtocol!
    let outOfBandService: OutOfBandServiceProtocol!
    let wallet: WalletProtocol!

    var agentDelegate: AgentDelegate?
    var isBluetoothOn: Bool = false

    init(
        agentConfig: AgentConfig,
        connectionRepository: ConnectionRepositoryProtocol,
        mediationRecipient: MediationRecipientProtocol,
        outOfBandService: OutOfBandServiceProtocol,
        wallet: WalletProtocol,
        agentDelegate: AgentDelegate? = nil
    ) {
        self.agentConfig = agentConfig
        self.connectionRepository = connectionRepository
        self.mediationRecipient = mediationRecipient
        self.outOfBandService = outOfBandService
        self.wallet = wallet
        self.agentDelegate = agentDelegate
    }
}
