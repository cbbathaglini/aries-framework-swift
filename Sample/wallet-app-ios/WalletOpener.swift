//
//  WalletOpener.swift
//  wallet-app-ios
//

import SwiftUI
import AriesFramework
import AnyCodable

final class WalletState: ObservableObject {
    @Published var walletOpened = false
    @Published var loggedOut = false
}

var agent: Agent?

class WalletOpener : ObservableObject {

    func openWallet(walletState: WalletState) async {
        
        let userDefaults = UserDefaults.standard
        var key = userDefaults.value(forKey:"walletKey") as? String
        if (key == nil) {
            do {
                key = try Agent.generateWalletKey()
                userDefaults.set(key, forKey: "walletKey")
            } catch {
                if let err = error as NSError? {
                    print("Cannot generate key: \(err.userInfo["message"] ?? "Unknown error")")
                    return
                }
            }
        }

        let genesisPath = Bundle(for: WalletOpener.self).path(forResource: "genesiscpqd", ofType: "txn")
      
//        guard var invitationUrl = Bundle.main.object(forInfoDictionaryKey: "MEDIATOR_URL") as? String else {
//            fatalError("MEDIATOR_URL not founded in Info.plist")
//        }
        
        var invitationUrl = ProcessInfo.processInfo.environment["MEDIATOR_URL"] ?? AppConfig.string("MEDIATOR_URL")

        if invitationUrl.isEmpty || URL(string: invitationUrl) == nil {
            print("⚠️ MEDIATOR_URL is not configured, mediator connection will be skipped")
            invitationUrl = ""
        }
        
        let besuLedgerConfig = BesuLedgerConfig(
            configFile: "besu_config.json",
            multiledger: true
        )

            
        var deviceId: String = "HolderSampleApp"
        if let idfv = await UIDevice.current.identifierForVendor?.uuidString {
            deviceId = "HolderDevice_\(idfv)"
        }
    
        let config = AgentConfig(walletKey: key!,
                                 genesisPath: genesisPath!,
                                 mediatorConnectionsInvite: invitationUrl,
                                 mediatorPickupStrategy: .Implicit,
                                 label: deviceId,
                                 autoAcceptCredential: .never,
                                 autoAcceptProof: .never,
                                 useLedgerService: false,
                                 useBesuLedger: true,
                                 besuLedgerConfig: besuLedgerConfig,
        )

        do {
            agent = Agent(agentConfig: config, agentDelegate: await CredentialHandler.shared)
            try await agent!.initialize()
            await CacheOperations.updateCache(agent: agent!)
            print("✅ Wallet initialized successfully")
        } catch {
            print("❌ Cannot initialize agent: \(error)")
        }
        DispatchQueue.main.async {
            withAnimation { walletState.walletOpened = true }
        }
    }
}
