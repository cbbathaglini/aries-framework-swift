//
//  CredentialAckHandlerProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/25.
//

protocol CredentialAckHandlerProtocol: MessageHandler {
    var agent: Agent { get }
    var messageType: String { get }
    func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage?
}
