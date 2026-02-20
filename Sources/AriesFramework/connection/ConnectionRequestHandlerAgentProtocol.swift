//
//  ConnectionRequestHandlerAgentProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

public protocol ConnectionRequestHandlerAgentProtocol {
    var connectionService: ConnectionServiceProtocol! { get }
    var agentConfig: AgentConfig { get }
}

extension Agent: ConnectionRequestHandlerAgentProtocol {}
