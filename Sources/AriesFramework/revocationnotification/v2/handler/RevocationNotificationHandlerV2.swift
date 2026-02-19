//
//  RevocationNotificationHandlerV1.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/25.
//

import Foundation

public class RevocationNotificationHandlerV2: MessageHandler {
    public let messageType = RevocationNotificationMessageV2.type
    private let agent: Agent

    public init(agent: Agent) {
        self.agent = agent
    }

    public func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        try await agent.revocationNotificationServiceV2.processRevocationNotification(messageContext: messageContext)
        return nil
    }
}
