//
//  ConnectionResponseHandlerAgentProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

protocol ConnectionResponseHandlerAgentProtocol {
    var connectionService: ConnectionServiceProtocol! { get }
    var agentConfig: AgentConfig { get }
}
