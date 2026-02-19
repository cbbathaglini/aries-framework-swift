//
//  ConnectionHandler.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 10/10/25.
//

import Foundation
import SwiftUI
import AriesFramework

@MainActor
class ConnectionHandler: ObservableObject {
    static let shared = ConnectionHandler()
    
    @Published var connections: [ConnectionRecord] = []
    @Published var connectionStatusMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var menu: MainMenu?

    
    private init() {}
    
    func refreshConnections() {
        Task {
            guard let agent = agent else { return }
            let all = await agent.connectionRepository.getAll()
            await MainActor.run {
                self.connections = all
            }
            print("✅ \(all.count) loaded connections.")
        }
    }
    
    func onConnectionStateChanged(connectionRecord: ConnectionRecord) {
        print("🔗 Connection state changed: \(connectionRecord.state.rawValue)")
        
        switch connectionRecord.state {
        case .Invited:
            connectionStatusMessage = "Connection request invited"
        case .Requested:
            connectionStatusMessage = "Connection requested"
        case .Complete:
            connectionStatusMessage = "Connection established with \(connectionRecord.theirLabel ?? "unknown")"
        default:
            connectionStatusMessage = "Connection updated: \(connectionRecord.state.rawValue)"
        }
        
        showSimpleAlert(message: connectionStatusMessage)
    }
    
   
    func getAllConnections() async -> [ConnectionRecord]? {
        return await agent!.connectionRepository.getAll()
    }
    
    private func showSimpleAlert(message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.connectionStatusMessage = message
            self.showAlert = true
        }
    }
}
