//
//  DidExchangeServiceProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

public protocol DidExchangeServiceProtocol {

    // MARK: - Incoming messages

    func processRequest(
        messageContext: InboundMessageContext
    ) async throws -> ConnectionRecord

    func processResponse(
        messageContext: InboundMessageContext
    ) async throws -> ConnectionRecord

    // MARK: - Outgoing messages

    func createRequest(
        connectionId: String,
        label: String?,
        autoAcceptConnection: Bool?
    ) async throws -> OutboundMessage

    func createResponse(
        connectionId: String
    ) async throws -> OutboundMessage

    func createComplete(
        connectionId: String
    ) async throws -> OutboundMessage

    func waitForConnection() async throws -> Bool
}

extension DidExchangeService: DidExchangeServiceProtocol {}
