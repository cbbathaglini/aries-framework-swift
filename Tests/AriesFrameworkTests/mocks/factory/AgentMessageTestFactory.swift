//
//  AgentMessageTestFactory.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework
import Foundation

enum AgentMessageTestFactory {


    static func make(
        type: String = "test/dummy-message",
        id: String? = nil
    ) -> AgentMessage {
        AgentMessage(
            id: id,
            type: type
        )
    }

    static func withThread(
        type: String = "test/dummy-message",
        threadId: String = UUID().uuidString,
        parentThreadId: String? = nil
    ) -> AgentMessage {

        let message = AgentMessage(type: type)
        message.setThread(
            threadId: threadId,
            parentThreadId: parentThreadId
        )
        return message
    }


    static func credentialAckV2(
        threadId: String
    ) -> AgentMessage {

        let message = AgentMessage(
            type: CredentialAckMessageV2.type
        )
        message.setThread(threadId: threadId)
        return message
    }
}
