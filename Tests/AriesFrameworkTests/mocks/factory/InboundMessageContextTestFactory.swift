//
//  InboundMessageContextTestFactory.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework

enum InboundMessageContextTestFactory {

    static func make(
        message: AgentMessage = AgentMessageTestFactory.credentialAckV2(threadId: "t1"),
        plaintextMessage: String = "{}",
        connection: ConnectionRecord? = ConnectionRecordTestFactory.readyConnection(),
        senderVerkey: String? = "sender-verkey",
        recipientVerkey: String? = "recipient-verkey"
    ) -> InboundMessageContext {

        InboundMessageContext(
            message: message,
            plaintextMessage: plaintextMessage,
            connection: connection,
            senderVerkey: senderVerkey,
            recipientVerkey: recipientVerkey
        )
    }

    static func withoutConnection(
        message: AgentMessage = AgentMessageTestFactory.credentialAckV2(threadId: "t1")
    ) -> InboundMessageContext {

        InboundMessageContext(
            message: message,
            plaintextMessage: "{}",
            connection: nil,
            senderVerkey: nil,
            recipientVerkey: nil
        )
    }
}
