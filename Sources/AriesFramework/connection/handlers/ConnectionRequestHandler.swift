
import Foundation

class ConnectionRequestHandler: MessageHandler {
    let agent: ConnectionRequestHandlerAgentProtocol
    let messageType = ConnectionRequestMessage.type

    init(agent: ConnectionRequestHandlerAgentProtocol) {
        self.agent = agent
    }

    func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        let connectionRecord =
            try await agent.connectionService.processRequest(messageContext: messageContext)

        if connectionRecord.autoAcceptConnection ?? agent.agentConfig.autoAcceptConnections {
            return try await agent.connectionService.createResponse(
                connectionId: connectionRecord.id
            )
        }

        return nil
    }
}
