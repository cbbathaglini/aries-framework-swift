//
//  BasicMessageHandlerAgentProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

public protocol BasicMessageHandlerAgentProtocol {
    var basicMessageRepository: BasicMessageRepositoryProtocol! { get }
    var agentDelegate: AgentDelegate? { get }
}

extension Agent: BasicMessageHandlerAgentProtocol {}
