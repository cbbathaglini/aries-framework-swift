//
//  DidExchangeHandlerAgentProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

public protocol DidExchangeHandlerAgentProtocol {
    var didExchangeService: DidExchangeServiceProtocol! { get }
    var agentConfig: AgentConfig { get }
}


extension Agent: DidExchangeHandlerAgentProtocol {}
