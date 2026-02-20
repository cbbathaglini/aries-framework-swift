//
//  TestAgent.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework


final class TestAgent: DidExchangeAgentProtocol {

    // MARK: - Protocol requirements

    let agentConfig: AgentConfig
    let connectionRepository: ConnectionRepositoryProtocol!
    let peerDIDService: PeerDIDServiceProtocol!
    let jwsService: JwsServiceProtocol!
    let outOfBandService: OutOfBandServiceProtocol!
    let mediationRecipient: MediationRecipientProtocol!
    let connectionService: ConnectionServiceProtocol!
    let agentDelegate: AgentDelegate? = nil

    // MARK: - Init

    init(
        connectionRepository: ConnectionRepositoryProtocol,
        peerDIDService: PeerDIDServiceProtocol = MockPeerDIDService(),
        jwsService: JwsServiceProtocol = MockJwsService(),
        outOfBandService: OutOfBandServiceProtocol = MockOutOfBandService(),
        mediationRecipient: MediationRecipientProtocol = MockMediationRecipient(),
        connectionService: ConnectionServiceProtocol? = nil,
        agentConfig: AgentConfig = .test()
    ) {
        self.agentConfig = agentConfig
        self.connectionRepository = connectionRepository
        self.peerDIDService = peerDIDService
        self.jwsService = jwsService
        self.outOfBandService = outOfBandService
        self.mediationRecipient = mediationRecipient

        self.connectionService =
            connectionService
            ?? MockConnectionService(connectionRepository: connectionRepository)
    }
}

extension AgentConfig {
    static func test() -> AgentConfig {
        AgentConfigBuilder()
            .withLabel("TestAgent")
            .notAutoAcceptCredential()
            .build()
        
    }
}
