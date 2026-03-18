//
//  InboundMessageContextBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

import Foundation
@testable import AriesFramework

final class InboundMessageContextBuilder {

    private var message: AgentMessage =
        PresentationAckMessageV2Builder().build()

    private var plaintextMessage: String? = nil
    private var connection: ConnectionRecord? = nil
    private var senderVerkey: String? = nil
    private var recipientVerkey: String? = nil

    @discardableResult
    func setMessage(_ value: AgentMessage) -> Self {
        self.message = value
        return self
    }

    @discardableResult
    func setPlaintextMessage(_ value: String) -> Self {
        self.plaintextMessage = value
        return self
    }

    @discardableResult
    func setConnection(_ value: ConnectionRecord?) -> Self {
        self.connection = value
        return self
    }

    @discardableResult
    func setSenderVerkey(_ value: String?) -> Self {
        self.senderVerkey = value
        return self
    }

    @discardableResult
    func setRecipientVerkey(_ value: String?) -> Self {
        self.recipientVerkey = value
        return self
    }

    func build() throws -> InboundMessageContext {

        let resolvedPlaintext = try plaintextMessage ?? message.toJsonString()

        return InboundMessageContext(
            message: message,
            plaintextMessage: resolvedPlaintext,
            connection: connection,
            senderVerkey: senderVerkey,
            recipientVerkey: recipientVerkey
        )
    }
}
