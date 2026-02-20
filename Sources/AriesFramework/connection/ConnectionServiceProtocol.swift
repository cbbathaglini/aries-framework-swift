//
//  ConnectionServiceProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

public protocol ConnectionServiceProtocol {

    func processRequest(
        messageContext: InboundMessageContext
    ) async throws -> ConnectionRecord

    func processResponse(
        messageContext: InboundMessageContext
    ) async throws -> ConnectionRecord

    func createResponse(
        connectionId: String
    ) async throws -> OutboundMessage

    func createTrustPing(
        connectionId: String,
        responseRequested: Bool?,
        comment: String?
    ) async throws -> OutboundMessage

    func createInvitation(
        routing: Routing,
        autoAcceptConnection: Bool?,
        alias: String?,
        multiUseInvitation: Bool?,
        label: String?,
        imageUrl: String?
    ) async throws -> OutboundMessage

    func createRequest(
        connectionId: String,
        label: String?,
        imageUrl: String?,
        autoAcceptConnection: Bool?
    ) async throws -> OutboundMessage

    func findByKeys(
        senderKey: String,
        recipientKey: String
    ) async throws -> ConnectionRecord?
    
    func findByInvitationKey(
        _ key: String
    ) async -> ConnectionRecord?
    
    func processInvitation(
        _ invitation: ConnectionInvitationMessage?,
        outOfBandInvitation: OutOfBandInvitation?,
        routing: Routing,
        autoAcceptConnection: Bool?,
        alias: String?
    ) async throws -> ConnectionRecord
    
    func updateState(
        connectionRecord: inout ConnectionRecord,
        newState: ConnectionState
    )async throws
    
    
    func matchIncomingMessageToRequestMessageInOutOfBandExchange(
        messageContext: InboundMessageContext,
        expectedConnectionId: String?
    ) async throws
    
    
    func createConnection(
            role: ConnectionRole,
            state: ConnectionState,
            invitation: ConnectionInvitationMessage?,
            outOfBandInvitation: OutOfBandInvitation?,
            alias: String?,
            routing: Routing,
            theirLabel: String?,
            autoAcceptConnection: Bool?,
            multiUseInvitation: Bool,
            tags: Tags?,
            imageUrl: String?,
            threadId: String?
        ) async throws -> ConnectionRecord
    
    
    func getByThreadId(
        _ threadId: String
    ) async throws -> ConnectionRecord
    
    
    func fetchState(
        connectionRecord: ConnectionRecord
    ) async throws -> ConnectionState
    
    
    func waitForConnection() async throws -> Bool
    
    func getById(id: String) async throws -> ConnectionRecord
    
    func findAllByInvitationKey(_ key: String) async -> [ConnectionRecord]
}
extension ConnectionService: ConnectionServiceProtocol {}


public extension ConnectionServiceProtocol {

    // MARK: - Trust Ping

    func createTrustPing(
        connectionId: String,
        responseRequested: Bool? = nil,
        comment: String? = nil
    ) async throws -> OutboundMessage {
        try await createTrustPing(
            connectionId: connectionId,
            responseRequested: responseRequested,
            comment: comment
        )
    }

    // MARK: - Invitation

    func createInvitation(
        routing: Routing,
        autoAcceptConnection: Bool? = nil,
        alias: String? = nil,
        multiUseInvitation: Bool? = nil,
        label: String? = nil,
        imageUrl: String? = nil
    ) async throws -> OutboundMessage {
        try await createInvitation(
            routing: routing,
            autoAcceptConnection: autoAcceptConnection,
            alias: alias,
            multiUseInvitation: multiUseInvitation,
            label: label,
            imageUrl: imageUrl
        )
    }

    // MARK: - Request

    func createRequest(
        connectionId: String,
        label: String? = nil,
        imageUrl: String? = nil,
        autoAcceptConnection: Bool? = nil
    ) async throws -> OutboundMessage {
        try await createRequest(
            connectionId: connectionId,
            label: label,
            imageUrl: imageUrl,
            autoAcceptConnection: autoAcceptConnection
        )
    }

    // MARK: - Process Invitation

    func processInvitation(
        _ invitation: ConnectionInvitationMessage? = nil,
        outOfBandInvitation: OutOfBandInvitation? = nil,
        routing: Routing,
        autoAcceptConnection: Bool? = nil,
        alias: String? = nil
    ) async throws -> ConnectionRecord {
        try await processInvitation(
            invitation,
            outOfBandInvitation: outOfBandInvitation,
            routing: routing,
            autoAcceptConnection: autoAcceptConnection,
            alias: alias
        )
    }
    
    func matchIncomingMessageToRequestMessageInOutOfBandExchange(
        messageContext: InboundMessageContext,
        expectedConnectionId: String? = nil
    ) async throws{
        try await matchIncomingMessageToRequestMessageInOutOfBandExchange(
            messageContext: messageContext,
            expectedConnectionId: expectedConnectionId)
    }
    
    func createConnection(
            role: ConnectionRole,
            state: ConnectionState,
            invitation: ConnectionInvitationMessage? = nil,
            outOfBandInvitation: OutOfBandInvitation? = nil,
            alias: String? = nil,
            routing: Routing,
            theirLabel: String? = nil,
            autoAcceptConnection: Bool? = nil,
            multiUseInvitation: Bool,
            tags: Tags? = nil,
            imageUrl: String? = nil,
            threadId: String? = nil
        ) async throws -> ConnectionRecord {
            try await createConnection(
                role: role,
                state: state,
                invitation: invitation,
                outOfBandInvitation: outOfBandInvitation,
                alias: alias,
                routing: routing,
                theirLabel: theirLabel,
                autoAcceptConnection: autoAcceptConnection,
                multiUseInvitation: multiUseInvitation,
                tags: tags,
                imageUrl: imageUrl,
                threadId: threadId
            )
        }
    
}
