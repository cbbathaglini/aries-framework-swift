
import Foundation

final class DidExchangeCompleteHandler: MessageHandler {

    let agent: DidExchangeCompleteHandlerAgentProtocol
    let messageType = DidExchangeCompleteMessage.type

    init(agent: DidExchangeCompleteHandlerAgentProtocol) {
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
