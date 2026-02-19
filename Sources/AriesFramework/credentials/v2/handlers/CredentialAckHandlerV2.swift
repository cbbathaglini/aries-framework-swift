
import Foundation
import os

class CredentialAckHandlerV2: CredentialAckHandlerProtocol {
    let logger = Logger(subsystem: "AriesFramework", category: "CredentialAckHandlerV2")
    let agent: Agent
    let messageType = CredentialAckMessageV2.type

    init(agent: Agent) {
        self.agent = agent
    }

    func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        logDebug("[init] CredentialAckHandlerV2")
        _ = try await agent.credentialServiceV2.processAck(messageContext)
        return nil
    }
}
