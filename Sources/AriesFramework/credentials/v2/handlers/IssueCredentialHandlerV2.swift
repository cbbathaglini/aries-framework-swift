
import Foundation

public class IssueCredentialHandlerV2: MessageHandler {
    public let messageType = IssueCredentialMessageV2.type
    private let agent: Agent

    public init(agent: Agent) {
        self.agent = agent
    }

    public func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        logDebug("IssueCredentialHandlerV2 init")

        let credentialRecord = try await agent.credentialServiceV2.processCredential(messageContext)

        let shouldAutoRespond = try await agent.credentialServiceV2.shouldAutoRespondToCredential(
            credentialRecord: credentialRecord,
            messageContext: messageContext
        )

        if shouldAutoRespond {
            logDebug("Auto-responding to issued credential")

            let result = try await agent.credentialServiceV2.acceptCredential(credentialRecord)
            let ackMessage = result.1

            logDebug("Generated ackMessage: \(ackMessage)")

            if let requestMessage = await agent.credentialServiceV2.findRequestMessage(credentialExchangeId: credentialRecord.id) {
                logDebug("Found request message: \(requestMessage)")
            } else {
                logDebug("No request message found for credential record ID: \(credentialRecord.id)")
            }

            return OutboundMessage(payload: ackMessage, connection: messageContext.connection!)
        }

        return nil
    }
}
