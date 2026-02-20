
import Foundation

final class DidExchangeRequestHandler: MessageHandler {

    let agent: DidExchangeHandlerAgentProtocol
    let messageType = DidExchangeRequestMessage.type

    init(agent: DidExchangeHandlerAgentProtocol) {
        self.agent = agent
    }

    func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        let connectionRecord =
            try await agent.didExchangeService.processRequest(
                messageContext: messageContext
            )

        if connectionRecord.autoAcceptConnection ?? agent.agentConfig.autoAcceptConnections {
            return try await agent.didExchangeService.createResponse(
                connectionId: connectionRecord.id
            )
        }

        return nil
    }
}
