//
//  AgentConfigBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework
import Foundation

public final class AgentConfigBuilder {

    // MARK: - Stored properties (defaults)

    private var walletId: String = "AFSDefaultWallet"
    private var walletKey: String = "test-wallet-key"
    private var genesisPath: String = "/tmp/genesis.txn"

    private var mediatorConnectionsInvite: String? = nil
    private var mediatorPickupStrategy: MediatorPickupStrategy = .PickUpV1

    private var label: String = "TestAgent"
    private var autoAcceptConnections: Bool = true

    private var mediatorPollingInterval: TimeInterval = 10
    private var mediatorEmptyReturnRetryInterval: TimeInterval = 3

    private var connectionImageUrl: String? = nil

    private var autoAcceptCredential: AutoAcceptCredential = .always
    private var autoAcceptProof: AutoAcceptProof = .always

    private var ignoreRevocationCheck: Bool = false
    private var useLedgerService: Bool = false
    private var useLegacyDidSovPrefix: Bool = false

    private var preferredHandshakeProtocol: HandshakeProtocol = .DidExchange10

    private var publicDidSeed: String? = nil
    private var agentEndpoints: [String]? = nil

    private var useBesuLedger: Bool = false
    private var besuLedgerConfig: BesuLedgerConfig? = nil

    // MARK: - Fluent setters

    public func withWallet(
        id: String,
        key: String,
        genesisPath: String
    ) -> Self {
        self.walletId = id
        self.walletKey = key
        self.genesisPath = genesisPath
        return self
    }

    public func withLabel(_ label: String) -> Self {
        self.label = label
        return self
    }

    public func withMediatorInvite(_ invite: String?) -> Self {
        self.mediatorConnectionsInvite = invite
        return self
    }
    
    
    public func connectionImageUrl(_ url: String?) -> Self {
        self.connectionImageUrl = url
        return self
    }
    
    

    public func withEndpoints(_ endpoints: [String]) -> Self {
        self.agentEndpoints = endpoints
        return self
    }
    
    public func notAutoAcceptCredential() -> Self {
        self.autoAcceptCredential = AutoAcceptCredential.never
        return self
    }

    public func withPublicDidSeed(_ seed: String?) -> Self {
        self.publicDidSeed = seed
        return self
    }

    public func enableLedger(_ enabled: Bool) -> Self {
        self.useLedgerService = enabled
        return self
    }

    // MARK: - Build

    public func build() -> AgentConfig {
        AgentConfig(
            walletId: walletId,
            walletKey: walletKey,
            genesisPath: genesisPath,
            mediatorConnectionsInvite: mediatorConnectionsInvite,
            mediatorPickupStrategy: mediatorPickupStrategy,
            label: label,
            autoAcceptConnections: autoAcceptConnections,
            mediatorPollingInterval: mediatorPollingInterval,
            mediatorEmptyReturnRetryInterval: mediatorEmptyReturnRetryInterval,
            connectionImageUrl: connectionImageUrl,
            autoAcceptCredential: autoAcceptCredential,
            autoAcceptProof: autoAcceptProof,
            ignoreRevocationCheck: ignoreRevocationCheck,
            useLedgerService: useLedgerService,
            useLegacyDidSovPrefix: useLegacyDidSovPrefix,
            preferredHandshakeProtocol: preferredHandshakeProtocol,
            publicDidSeed: publicDidSeed,
            agentEndpoints: agentEndpoints,
            useBesuLedger: useBesuLedger,
            besuLedgerConfig: besuLedgerConfig
        )
    }
}
