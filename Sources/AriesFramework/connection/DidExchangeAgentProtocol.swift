//
//  DidExchangeAgentProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

public protocol DidExchangeAgentProtocol: AnyObject {
    var agentConfig: AgentConfig { get }
    var connectionRepository: ConnectionRepositoryProtocol! { get }
    var peerDIDService: PeerDIDServiceProtocol! { get }
    var jwsService: JwsServiceProtocol! { get }
    var outOfBandService: OutOfBandServiceProtocol! { get }
    var mediationRecipient: MediationRecipientProtocol! { get }
    var connectionService: ConnectionServiceProtocol! { get }
    var agentDelegate: AgentDelegate? { get }
}

extension Agent: DidExchangeAgentProtocol {}
