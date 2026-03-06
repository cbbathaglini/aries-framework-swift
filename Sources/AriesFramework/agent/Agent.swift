import Foundation
import askar_uniffi
import os

public class Agent {
    let logger = Logger(subsystem: "AriesFramework", category: "Agent")
    public var agentConfig: AgentConfig
    public var agentDelegate: AgentDelegate?

    var mediationRecipient: MediationRecipient!
    public var connectionRepository: ConnectionRepository!
    public var connectionService: ConnectionService!
    public var didExchangeService: DidExchangeService!
    public var peerDIDService: PeerDIDService!
    public var jwsService: JwsService!
    public var messageSender: MessageSender!
    var messageReceiver: MessageReceiver!
    public var dispatcher: Dispatcher!
    public var connections: ConnectionCommand!
    var outOfBandRepository: OutOfBandRepository!
    var outOfBandService: OutOfBandService!
    public var oob: OutOfBandCommand!
    public var credentialExchangeRepository: CredentialExchangeRepository!
    public var didCommMessageRepository: DidCommMessageRepository!
    public var ledgerService: LedgerService!
    public var credentialDefinitionRepository: CredentialDefinitionRepository!
    public var revocationRegistryRepository: RevocationRegistryRepository!
    public var anoncredsService: AnoncredsService!
    public var revocationService: RevocationService!
    public var credentialService: CredentialService!
    public var credentials: CredentialsCommand!
    public var credentialServiceV2: CredentialServiceV2!
    public var credentialsV2: CredentialsCommandV2!
    public var credentialRepository: CredentialRepository!
    public var proofRepository: ProofRepository!
    public var proofService: ProofService!
    public var proofs: ProofCommand!
    
    public var revocationNotificationService: RevocationNotificationService!
    public var revocationNotificationServiceV2: RevocationNotificationServiceV2!
    
    public var anoncredsModulesConfig: AnonCredsModuleConfig!
    public var anonCredsRegistryService: AnonCredsRegistryService!
    
    /** credential v2 **/
    public var anonCredsIssuerService: AnonCredsRsIssuerService!
    public var anonCredsHolderService: AnonCredsRsHolderService!
    public var anonCredsCredentialRepository: AnonCredsCredentialRepository!
    public var anonCredsCredentialDefinitionRepository: AnonCredsCredentialDefinitionRepository!
    public var anonCredsLinkSecretRepository: AnonCredsLinkSecretRepository!
    public var anonCredsKeyCorrectnessProofRepository: AnonCredsKeyCorrectnessProofRepository!
    public var w3cCredentialRepository: W3cCredentialRepository!
    public var anonCredsRevocationRegistryDefinitionPrivateRepository: AnonCredsRevocationRegistryDefinitionPrivateRepository!
    
    public var basicMessages: BasicMessageCommand!
    public var basicMessageRepository: BasicMessageRepository!
    public var w3cCredentialsModuleConfig : W3cCredentialsModuleConfig!
    public var w3cCredentialService : W3cCredentialService!
    public var w3cJsonLdCredentialService : W3cJsonLdCredentialService!
    
    public var historyRepository : HistoryRepository!
    
    /** proof v2 **/
    public var proofServiceV2 : ProofServiceV2!
    public var proofCommandV2 : ProofCommandV2!
    public var anoncredsVerifierService: AnonCredsVerifierService!
    public var verifierRepository: VerifierRepository!
    
    /** eca **/
    public var ecaService: EcaService!
    public var ecaRepository: EcaRepository!

    public var wallet: Wallet!
    private var _isInitialized = false

    var bleInboundTransport: BleInboundTransport!
    public var isBluetoothOn: Bool {
        return _isBluetoothOn
    }
    private var _isBluetoothOn = false

    public init(agentConfig: AgentConfig, agentDelegate: AgentDelegate?) {
        self.agentConfig = agentConfig
        self.agentDelegate = agentDelegate

        self.wallet = Wallet(agent: self)
        self.historyRepository = HistoryRepository(agent: self)
        self.connectionRepository = ConnectionRepository(agent: self)
        self.connectionService = ConnectionService(agent: self)
        self.didExchangeService = DidExchangeService(agent: self)
        self.peerDIDService = PeerDIDService(agent: self)
        self.jwsService = JwsService(agent: self)
        self.messageSender = MessageSender(agent: self)
        self.messageReceiver = MessageReceiver(agent: self)
        self.dispatcher = Dispatcher(agent: self)
        self.connections = ConnectionCommand(agent: self, dispatcher: self.dispatcher)
        self.mediationRecipient = MediationRecipient(agent: self, dispatcher: self.dispatcher)
        self.outOfBandRepository = OutOfBandRepository(agent: self)
        self.outOfBandService = OutOfBandService(agent: self)
        self.oob = OutOfBandCommand(agent: self, dispatcher: self.dispatcher)
        self.credentialExchangeRepository = CredentialExchangeRepository(agent: self)
        self.didCommMessageRepository = DidCommMessageRepository(agent: self)
        self.ledgerService = initializeLedgerService()
        self.credentialDefinitionRepository = CredentialDefinitionRepository(agent: self)
        self.revocationRegistryRepository = RevocationRegistryRepository(agent: self)
        self.anoncredsService = AnoncredsService(agent: self)
        self.revocationService = RevocationService(agent: self)
        self.credentialService = CredentialService(agent: self)
        self.credentialServiceV2 = CredentialServiceV2(agent: self)
        self.credentials = CredentialsCommand(agent: self, dispatcher: self.dispatcher)
        self.credentialsV2 = CredentialsCommandV2(agent: self, dispatcher: self.dispatcher)
        self.credentialRepository = CredentialRepository(agent: self)
        self.proofRepository = ProofRepository(agent: self)
        self.proofService = ProofService(agent: self)
        self.proofs = ProofCommand(agent: self, dispatcher: self.dispatcher)
        self.bleInboundTransport = BleInboundTransport(agent: self)
        self.revocationNotificationService = RevocationNotificationService(agent: self, dispatcher: self.dispatcher)
        self.revocationNotificationServiceV2 = RevocationNotificationServiceV2(agent: self, dispatcher: self.dispatcher)
        self.basicMessages = BasicMessageCommand(agent: self, dispatcher: self.dispatcher)
        self.basicMessageRepository = BasicMessageRepository(agent: self)
        
        self.anonCredsKeyCorrectnessProofRepository = AnonCredsKeyCorrectnessProofRepository(agent: self)
        self.anonCredsRevocationRegistryDefinitionPrivateRepository = AnonCredsRevocationRegistryDefinitionPrivateRepository(agent: self)
        self.anonCredsCredentialDefinitionRepository = AnonCredsCredentialDefinitionRepository(agent: self)
        self.anonCredsLinkSecretRepository = AnonCredsLinkSecretRepository(agent: self)
        self.anonCredsCredentialRepository = AnonCredsCredentialRepository(agent: self)
        self.w3cCredentialRepository = W3cCredentialRepository(agent: self)
        self.anonCredsIssuerService = AnonCredsRsIssuerService(agent: self)
        self.anonCredsHolderService = AnonCredsRsHolderService(agent: self)
    
        self.anoncredsModulesConfig = AnonCredsModuleConfig(
            agent: self,
            options: AnonCredsModuleConfigOptions(
                registries: [EthrAnonCredsRegistry()] as [AnonCredsRegistry]
            )
        )
        
        self.anonCredsRegistryService = AnonCredsRegistryService(agent: self)
        self.w3cCredentialsModuleConfig = W3cCredentialsModuleConfig()
        self.w3cJsonLdCredentialService = W3cJsonLdCredentialService(
            agent: self,
            config: w3cCredentialsModuleConfig,
            context: agentDelegate)
        
        self.w3cCredentialService = W3cCredentialService(
            w3cCredentialRepository: w3cCredentialRepository,
            w3cJsonLdCredentialService: w3cJsonLdCredentialService
        )
        

        self.proofServiceV2 = ProofServiceV2(agent: self)
        self.proofCommandV2 = ProofCommandV2(agent: self, dispatcher: dispatcher)
        
        self.anoncredsVerifierService = AnonCredsRsVerifierService(agent: self)
        self.verifierRepository = VerifierRepository(agent: self)
        
        /** eca **/
        self.ecaRepository = EcaRepository(agent: self)
        self.ecaService = EcaService(agent: self)
    }
    
    private func initializeLedgerService() -> LedgerService {
        if(agentConfig.useBesuLedger && agentConfig.besuLedgerConfig != nil) {
            return BesuLedgerService(agent: self)
        }
        return IndyLedgerService(agent: self)
    }

    /**
     Initialize the agent. This will create a wallet if necessary and open it.
     It will also connect to the mediator if configured and connect to the ledger.
    */
    public func initialize() async throws {
        if ProcessInfo.processInfo.environment["RUST_LOG"] != nil {
            logDebug("RUST_LOG is set. Setting default logger to debug.")
            try? askar_uniffi.setDefaultLogger()
        }

        try await wallet.initialize()

        if let publicDidSeed = agentConfig.publicDidSeed {
            try await wallet.initPublicDid(seed: publicDidSeed)
        }

        if agentConfig.useLedgerService  || agentConfig.useBesuLedger {
            try await ledgerService.initialize()
        }

        if let mediatorConnectionsInvite = agentConfig.mediatorConnectionsInvite {
            try await mediationRecipient.initialize(mediatorConnectionsInvite: mediatorConnectionsInvite)
        } else {
            setInitialized()
        }
    }

    /**
     Whether the agent is initialized. Agent should make new connections after it is initialized.
    */
    public func isInitialized() -> Bool {
        return self._isInitialized
    }

    /**
     Remove the wallet and ledger data. This makes the agent as if it was never initialized.
    */
    public func reset() async throws {
        if isInitialized() {
            try await shutdown()
        }
        try await wallet.delete()
    }

    /**
     Shutdown the agent. This will close the wallet, disconnect from the ledger, disconnect from the mediator and close open websockets.
    */
    public func shutdown() async throws {
        mediationRecipient.close()
        try await ledgerService.close()
        await messageSender.close()
        if wallet.session != nil {
            try await wallet.close()
        }
        self._isInitialized = false
    }

    func setInitialized() {
        self._isInitialized = true
    }

    func receiveMessage(_ encryptedMessage: EncryptedMessage) async throws {
        try await messageReceiver.receiveMessage(encryptedMessage)
    }

    /**
     Set the outbound transport for the agent. This will override the default http/websocket transport.
     It is useful for testing.
    */
    public func setOutboundTransport(_ outboundTransport: OutboundTransport) {
        self.messageSender.setOutboundTransport(outboundTransport)
    }

    /**
     Generate a key to encrypt the wallet.
    */
    public static func generateWalletKey() throws -> String {
        return try AskarStoreManager().generateRawStoreKey(seed: nil)
    }

    /**
     Start the BLE inbound transport. This enables message exchange via Bluetooth.
     Call this before creating a connection invitation.
     Note that the BLE outbound transport is available regardless of the state of BLE.
    */
    public func startBLE() async throws {
        if _isBluetoothOn {
            return
        }
        try await bleInboundTransport.start()
        _isBluetoothOn = true
    }

    /**
     Stop the BLE inbound transport.
    */
    public func stopBLE() async throws {
        if !_isBluetoothOn {
            return
        }
        try await bleInboundTransport.stop()
        _isBluetoothOn = false
    }
}
