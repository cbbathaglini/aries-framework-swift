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

    public func withMediatorPickupStrategy(_ strategy: MediatorPickupStrategy) -> Self {
        self.mediatorPickupStrategy = strategy
        return self
    }

    public func withAutoAcceptConnections(_ enabled: Bool) -> Self {
        self.autoAcceptConnections = enabled
        return self
    }

    public func withMediatorPollingInterval(_ interval: TimeInterval) -> Self {
        self.mediatorPollingInterval = interval
        return self
    }

    public func withMediatorEmptyReturnRetryInterval(_ interval: TimeInterval) -> Self {
        self.mediatorEmptyReturnRetryInterval = interval
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

    public func withPublicDidSeed(_ seed: String?) -> Self {
        self.publicDidSeed = seed
        return self
    }

    public func withAutoAcceptCredential(_ value: AutoAcceptCredential) -> Self {
        self.autoAcceptCredential = value
        return self
    }

    public func withAutoAcceptProof(_ value: AutoAcceptProof) -> Self {
        self.autoAcceptProof = value
        return self
    }

    public func notAutoAcceptCredential() -> Self {
        self.autoAcceptCredential = .never
        return self
    }

    public func notAutoAcceptProof() -> Self {
        self.autoAcceptProof = .never
        return self
    }

    public func withIgnoreRevocationCheck(_ enabled: Bool) -> Self {
        self.ignoreRevocationCheck = enabled
        return self
    }

    public func enableLedger(_ enabled: Bool) -> Self {
        self.useLedgerService = enabled
        return self
    }

    public func withUseLegacyDidSovPrefix(_ enabled: Bool) -> Self {
        self.useLegacyDidSovPrefix = enabled
        return self
    }

    public func withPreferredHandshakeProtocol(_ protocolValue: HandshakeProtocol) -> Self {
        self.preferredHandshakeProtocol = protocolValue
        return self
    }

    public func withUseBesuLedger(_ enabled: Bool) -> Self {
        self.useBesuLedger = enabled
        return self
    }

    public func withBesuLedgerConfig(_ config: BesuLedgerConfig?) -> Self {
        self.besuLedgerConfig = config
        return self
    }

    public func enableBesuLedger(_ config: BesuLedgerConfig) -> Self {
        self.useBesuLedger = true
        self.besuLedgerConfig = config
        return self
    }

    public func disableBesuLedger() -> Self {
        self.useBesuLedger = false
        self.besuLedgerConfig = nil
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
