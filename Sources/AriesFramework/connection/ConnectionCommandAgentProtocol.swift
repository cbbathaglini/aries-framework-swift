//
//  ConnectionCommandAgentProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

protocol ConnectionCommandAgentProtocol:
    ConnectionRequestHandlerAgentProtocol,
    ConnectionResponseHandlerAgentProtocol,
    TrustPingHandlerAgentProtocol,
    DidExchangeHandlerAgentProtocol,
    DidExchangeCompleteHandlerAgentProtocol
{
    var messageSender: MessageSenderProtocol! { get }
    var mediationRecipient: MediationRecipientProtocol! { get }
}

extension Agent: ConnectionCommandAgentProtocol {}
