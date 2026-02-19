
import Foundation
import os

class OfferCredentialHandler: MessageHandler {
    let agent: Agent
    let messageType = OfferCredentialMessage.type
    let logger = Logger(subsystem: "AriesFramework", category: "OfferCredentialHandler")

    init(agent: Agent) {
        self.agent = agent
    }

    func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        logDebug("OfferCredentialHandler init")
        let credentialRecord = try await agent.credentialService.processOffer(messageContext: messageContext)

        if (credentialRecord.autoAcceptCredential != nil && credentialRecord.autoAcceptCredential! == .always) || agent.agentConfig.autoAcceptCredential == .always {
            let message = try await agent.credentialService.createRequest(options: AcceptOfferOptions(credentialRecordId: credentialRecord.id))
            return OutboundMessage(payload: message, connection: messageContext.connection!)
        }

        return nil
    }
}
