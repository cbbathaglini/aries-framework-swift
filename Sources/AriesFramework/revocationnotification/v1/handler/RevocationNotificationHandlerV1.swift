//
//  RevocationNotificationHandlerV1.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/25.
//

import Foundation

public class RevocationNotificationHandlerV1: MessageHandler {
    public let messageType = RevocationNotificationMessageV1.type
    private let agent: Agent

    public init(agent: Agent) {
        self.agent = agent
    }

    public func handle(messageContext: InboundMessageContext) async throws -> OutboundMessage? {
        try await agent.revocationNotificationService.processRevocationNotification(messageContext: messageContext)
        return nil
    }
}
