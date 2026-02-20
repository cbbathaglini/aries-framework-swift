//
//  MockMessageSender.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework

final class MockMessageSender: MessageSenderProtocol {

    private(set) var sentMessages: [OutboundMessage] = []
    private(set) var sentAgentMessages: [AgentMessage] = []

    private(set) var receivedEndpointPrefix: String?
    private(set) var setOutboundTransportCalled = false
    private(set) var closeCalled = false

    var outboundTransportToReturn: OutboundTransport?
    var didCommServicesToReturn: [DidDocService] = []
    var outboundPackageToReturn: OutboundPackage!

    func setOutboundTransport(_ outboundTransport: OutboundTransport) {
        setOutboundTransportCalled = true
    }

    func outboundTransportForEndpoint(_ endpoint: String) -> OutboundTransport? {
        return outboundTransportToReturn
    }

    func decorateMessage(_ message: OutboundMessage) -> AgentMessage {
        let agentMessage = message.payload
        sentAgentMessages.append(agentMessage)
        return agentMessage
    }

    func send(
        message: OutboundMessage,
        endpointPrefix: String?
    ) async throws {
        sentMessages.append(message)
        receivedEndpointPrefix = endpointPrefix
    }

    func findDidCommServices(
        connection: ConnectionRecord
    ) throws -> [DidDocService] {
        return didCommServicesToReturn
    }

    func sendMessageToService(
        message: AgentMessage,
        service: DidDocService,
        senderKey: String,
        connectionId: String
    ) async throws {
        sentAgentMessages.append(message)
    }

    func packMessage(
        _ message: AgentMessage,
        keys: EnvelopeKeys,
        endpoint: String,
        connectionId: String
    ) async throws -> OutboundPackage {
        return outboundPackageToReturn
    }

    func close() async {
        closeCalled = true
    }
}
