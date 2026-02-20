//  MessageSenderProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

import Foundation

public protocol MessageSenderProtocol {

    func setOutboundTransport(
        _ outboundTransport: OutboundTransport
    )

    func outboundTransportForEndpoint(
        _ endpoint: String
    ) -> OutboundTransport?

    func decorateMessage(
        _ message: OutboundMessage
    ) -> AgentMessage

    func send(
        message: OutboundMessage,
        endpointPrefix: String?
    ) async throws

    func findDidCommServices(
        connection: ConnectionRecord
    ) throws -> [DidDocService]

    func sendMessageToService(
        message: AgentMessage,
        service: DidDocService,
        senderKey: String,
        connectionId: String
    ) async throws

    func packMessage(
        _ message: AgentMessage,
        keys: EnvelopeKeys,
        endpoint: String,
        connectionId: String
    ) async throws -> OutboundPackage

    func close() async
}

extension MessageSender: MessageSenderProtocol {}



//default values in optionalss
public extension MessageSenderProtocol {

    func send(
        message: OutboundMessage,
        endpointPrefix: String? = nil
    ) async throws {
        try await send(
            message: message,
            endpointPrefix: endpointPrefix
        )
    }
}
