//
//  ConnectionServiceAgentProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//


public protocol ConnectionServiceAgentProtocol: AnyObject {
    
    var agentConfig: AgentConfig { get }

    var connectionRepository: ConnectionRepositoryProtocol! { get }

    var mediationRecipient: MediationRecipientProtocol! { get }
    var outOfBandService: OutOfBandServiceProtocol! { get }

    var wallet: WalletProtocol! { get }
    var agentDelegate: AgentDelegate? { get }

    var isBluetoothOn: Bool { get }
    
}


extension Agent: ConnectionServiceAgentProtocol {}
