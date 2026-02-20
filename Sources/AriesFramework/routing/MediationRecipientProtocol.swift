//
//  MediationRecipientProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

import Foundation

public protocol MediationRecipientProtocol {

    func initialize(
        mediatorConnectionsInvite: String
    ) async throws

    func close()

    func assertInvitationUrl() async throws

    func requestMediationIfNecessry(
        connection: ConnectionRecord
    ) async throws

    func hasSameInvitationUrl(
        record: MediationRecord
    ) -> Bool

    func initiateMessagePickup(
        mediator: MediationRecord
    ) async throws

    func pickupMessages(
        mediatorConnection: ConnectionRecord
    ) async throws

    func pickupMessages() async throws

    func getRoutingInfo() async throws -> ([String], [String])

    func getRouting() async throws -> Routing

    func createRequest(
        connection: ConnectionRecord
    ) async throws -> OutboundMessage

    func processMediationGrant(
        messageContext: InboundMessageContext
    ) async throws

    func processMediationDeny(
        messageContext: InboundMessageContext
    ) async throws

    func processBatchMessage(
        messageContext: InboundMessageContext
    ) async throws

    func processKeylistUpdateResults(
        messageContext: InboundMessageContext
    ) async throws

    func keylistUpdate(
        mediator: MediationRecord,
        verkey: String
    ) async throws
}

extension MediationRecipient: MediationRecipientProtocol {}
