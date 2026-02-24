//
//  ConnectionInvitationMessageTestFactory.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 23/02/26.
//
@testable import AriesFramework

enum ConnectionInvitationMessageTestFactory {
    static func minimal(label: String = "test") -> ConnectionInvitationMessage {
        ConnectionInvitationMessage(
            label: label,
            recipientKeys: ["GJ1SzoWzavQYfNL9XkaJdrQejfztN4XqdsiV4ct3LXKL"],
            serviceEndpoint: "http://localhost",
            routingKeys: []
        )
    }
}
