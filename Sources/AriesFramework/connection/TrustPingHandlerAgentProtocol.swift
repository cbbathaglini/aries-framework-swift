//
//  TrustPingHandlerAgentProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

public protocol TrustPingHandlerAgentProtocol {
    var connectionService: ConnectionServiceProtocol! { get }
}

extension Agent: TrustPingHandlerAgentProtocol {}
