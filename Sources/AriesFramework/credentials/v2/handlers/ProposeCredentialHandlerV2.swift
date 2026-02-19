//
//  ProposeCredentialHandlerV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation
import os

class ProposeCredentialHandlerV2: MessageHandler {
    let logger = Logger(subsystem: "AriesFramework", category: "ProposeCredentialHandlerV2")
    let agent: Agent
    let messageType = ProposeCredentialMessageV2.type

    init(agent: Agent) {
        self.agent = agent
    }

    func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        logDebug("ProposeCredentialHandlerV2 init")

        let credentialRecord = try await agent.credentialServiceV2.processProposal(messageContext)

        let shouldAutoRespond = try await agent.credentialServiceV2.shouldAutoRespondToProposal(
            credentialRecord: credentialRecord,
            messageContext: messageContext
        )

        if shouldAutoRespond {
            return try await acceptProposal(
                credentialRecord: credentialRecord,
                messageContext: messageContext
            )
        }

        return nil
    }
    
    private func acceptProposal(
           credentialRecord: CredentialExchangeRecord,
           messageContext: InboundMessageContext
       ) async throws -> OutboundMessage {
           logDebug("Automatically sending offer with autoAccept")

           guard let connection = messageContext.connection else {
               logger.error("No connection on the messageContext, aborting auto accept")
               throw AriesFrameworkError.frameworkError("Missing connection for auto-accept proposal")
           }

        
           let result = try await agent.credentialServiceV2.acceptProposal(
            options: AcceptCredentialProposalOptions(credentialExchangeRecord: credentialRecord)
           )
        

           return OutboundMessage(
            payload: result.0,
               connection: connection
           )
       }
}
