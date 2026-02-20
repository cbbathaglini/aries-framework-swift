
import Foundation

class TrustPingMessageHandler: MessageHandler {
    let agent: TrustPingHandlerAgentProtocol
    let messageType = TrustPingMessage.type

    init(agent: TrustPingHandlerAgentProtocol) {
        self.agent = agent
    }

    func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        if var connection = messageContext.connection,
           connection.state == .Responded {

            try await agent.connectionService.updateState(
                connectionRecord: &connection,
                newState: .Complete
            )
        }
        return nil
    }
}
