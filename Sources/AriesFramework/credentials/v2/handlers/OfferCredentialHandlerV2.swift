
import Foundation
import os

public class OfferCredentialHandlerV2: MessageHandler {
    private let agent: Agent
    private let logger = Logger(subsystem: "org.hyperledger.ariesframework", category: "OfferCredentialHandlerV2")

    public var messageType: String {
        return OfferCredentialMessageV2.type
    }

    public init(agent: Agent) {
        self.agent = agent
    }

    public func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        logDebug("OfferCredentialHandlerV2 init")
        print("OfferCredentialHandlerV2 init: \(messageContext.plaintextMessage)")

        let credentialRecord = try await agent.credentialServiceV2.processOffer(messageContext)

        let shouldAutoRespond = try await agent.credentialServiceV2.shouldAutoRespondToOffer(
            credentialRecord: credentialRecord,
            messageContext: messageContext
        )

        if shouldAutoRespond {
            let requestMessage = try await acceptOffer(credentialRecord: credentialRecord)
            logDebug("accept offer message => \(requestMessage.description)")
            return OutboundMessage(payload: requestMessage, connection: messageContext.connection!)
        }

        return nil
    }

    private func acceptOffer(credentialRecord: CredentialExchangeRecord) async throws -> RequestCredentialMessageV2 {
        logDebug("Automatically sending request with autoAccept")

        let acceptOptions = AcceptCredentialOfferOptionsV2(credentialExchangeRecord: credentialRecord)
        let result = try await agent.credentialServiceV2.acceptOffer(options: acceptOptions)
        logDebug("requestCredentialMessageV2 => \(result.1)")
        return result.1
    }
}
