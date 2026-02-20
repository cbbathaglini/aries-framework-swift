//
//  MockMediationRecipient.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework

final class MockMediationRecipient: MediationRecipientProtocol {

    private(set) var getRoutingCalled = false
    var routingToReturn: Routing!

    func getRouting() async throws -> Routing {
        getRoutingCalled = true
        return routingToReturn
    }

    func initialize(mediatorConnectionsInvite: String) async throws { }

    func close() { }

    func assertInvitationUrl() async throws { }

    func requestMediationIfNecessry(
        connection: ConnectionRecord
    ) async throws { }

    func hasSameInvitationUrl(
        record: MediationRecord
    ) -> Bool {
        return false
    }

    func initiateMessagePickup(
        mediator: MediationRecord
    ) async throws { }

    func pickupMessages(
        mediatorConnection: ConnectionRecord
    ) async throws { }

    func pickupMessages() async throws { }

    func getRoutingInfo() async throws -> ([String], [String]) {
    return (
            routingToReturn.endpoints,
            routingToReturn.routingKeys
        )
    }

    func createRequest(
        connection: ConnectionRecord
    ) async throws -> OutboundMessage {
        fatalError()
    }

    func processMediationGrant(
        messageContext: InboundMessageContext
    ) async throws { }

    func processMediationDeny(
        messageContext: InboundMessageContext
    ) async throws { }

    func processBatchMessage(
        messageContext: InboundMessageContext
    ) async throws { }

    func processKeylistUpdateResults(
        messageContext: InboundMessageContext
    ) async throws { }

    func keylistUpdate(
        mediator: MediationRecord,
        verkey: String
    ) async throws { }
}
