
import Foundation
import os


class RequestCredentialHandlerV2: MessageHandler {
    let logger = Logger(subsystem: "AriesFramework", category: "RequestCredentialHandlerV2")
    let agent: Agent
    let messageType = RequestCredentialMessageV2.type

    init(agent: Agent) {
        self.agent = agent
    }

    func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        logDebug("RequestCredentialHandlerV2 init")

        let credentialRecord = try await agent.credentialServiceV2.processRequest(messageContext)

        let shouldAutoRespond = try await agent.credentialServiceV2.shouldAutoRespondToRequest(
            credentialRecord: credentialRecord,
            messageContext: messageContext
        )

        if shouldAutoRespond {
            let message = try await acceptRequest(credentialRecord: credentialRecord)
            guard let connection = messageContext.connection else {
                throw AriesFrameworkError.frameworkError("Missing connection for auto-accept request")
            }
            return OutboundMessage(payload: message, connection: connection)
        }

        return nil
    }

    private func acceptRequest(credentialRecord: CredentialExchangeRecord) async throws -> IssueCredentialMessageV2 {
        logDebug("Automatically sending credential with autoAccept")

        guard let _ = await agent.credentialServiceV2.findOfferMessage(credentialExchangeId: credentialRecord.id) else {
            throw AriesFrameworkError.frameworkError("Could not find offer message for credential record with id \(credentialRecord.id)")
        }

        let options = AcceptRequestOptionsV2(credentialExchangeRecord: credentialRecord)
        let result = try await agent.credentialServiceV2.acceptRequest(options: options)

        return result.1
    }
}
