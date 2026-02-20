//
//  AgentConfigTestFactory.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework

enum AgentConfigTestFactory {

    static func minimal(
        label: String = "TestAgent",
        autoAcceptConnections: Bool = true
    ) -> AgentConfig {
        return AgentConfig(
            walletKey: "test-wallet-key",
            genesisPath: "/tmp/genesis.txn",
            label: label,
            autoAcceptConnections: autoAcceptConnections,
            useLedgerService: false,
            useBesuLedger: false
        )
    }

    static func withMediator(
        invite: String = "https://mediator.invite"
    ) -> AgentConfig {
        return AgentConfig(
            walletKey: "test-wallet-key",
            genesisPath: "/tmp/genesis.txn",
            mediatorConnectionsInvite: invite,
            mediatorPickupStrategy: .PickUpV1,
            label: "TestAgent",
            autoAcceptConnections: true,
            useLedgerService: false,
            useBesuLedger: false
        )
    }

    static func withAutoAcceptDisabled() -> AgentConfig {
        return AgentConfig(
            walletKey: "test-wallet-key",
            genesisPath: "/tmp/genesis.txn",
            label: "TestAgent",
            autoAcceptConnections: false,
            useLedgerService: false,
            useBesuLedger: false
        )
    }

    static func full() -> AgentConfig {
        return AgentConfig(
            walletId: "TestWallet",
            walletKey: "test-wallet-key",
            genesisPath: "/tmp/genesis.txn",
            mediatorConnectionsInvite: "https://mediator.invite",
            mediatorPickupStrategy: .PickUpV1,
            label: "TestAgent",
            autoAcceptConnections: true,
            mediatorPollingInterval: 1,
            mediatorEmptyReturnRetryInterval: 1,
            connectionImageUrl: "https://image.test",
            autoAcceptCredential: .always,
            autoAcceptProof: .always,
            ignoreRevocationCheck: false,
            useLedgerService: false,
            useLegacyDidSovPrefix: false,
            preferredHandshakeProtocol: .DidExchange10,
            publicDidSeed: nil,
            agentEndpoints: ["didcomm:transport/queue"],
            useBesuLedger: false,
            besuLedgerConfig: nil
        )
    }
}
