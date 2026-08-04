
import Foundation

class CredentialAckHandler: CredentialAckHandlerProtocol {
    let agent: Agent
    let messageType = CredentialAckMessage.type

    init(agent: Agent) {
        self.agent = agent
    }

    func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        _ = try await agent.credentialService.processAck(messageContext: messageContext)
        return nil
    }
}
