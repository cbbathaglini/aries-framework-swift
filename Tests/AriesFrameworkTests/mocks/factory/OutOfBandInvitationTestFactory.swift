//
//  OutOfBandInvitationTestFactory.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework
import Foundation

enum OutOfBandInvitationTestFactory {

    static func make(
        id: String = UUID().uuidString,
        label: String = "Test Out Of Band Invitation",
        goalCode: String? = nil,
        goal: String? = nil,
        accept: [String]? = nil,
        handshakeProtocols: [HandshakeProtocol]? = [.DidExchange10],
        services: [OutOfBandDidCommService] = [didCommService()],
        imageUrl: String? = nil
    ) -> OutOfBandInvitation {
        OutOfBandInvitation(
            id: id,
            label: label,
            goalCode: goalCode,
            goal: goal,
            accept: accept,
            handshakeProtocols: handshakeProtocols,
            requests: nil,
            services: services,
            imageUrl: imageUrl
        )
    }

    static func withDidExchangeOnly() -> OutOfBandInvitation {
        make(
            handshakeProtocols: [.DidExchange10],
            services: [didCommService()]
        )
    }

    static func reusable() -> OutOfBandInvitation {
        make(
            handshakeProtocols: [.DidExchange10],
            services: [didCommService()],
            imageUrl: "https://example.com/image.png"
        )
    }

    private static func didCommService(
        id: String = "didcomm-1",
        serviceEndpoint: String = "https://example.com",
        recipientKeys: [String] = ["did:key:z6MkpTestKey"],
        routingKeys: [String]? = nil
    ) -> OutOfBandDidCommService {
        .oobDidDocument(
            OutOfBandDidDocumentService(
                id: id,
                serviceEndpoint: serviceEndpoint,
                recipientKeys: recipientKeys,
                routingKeys: routingKeys
            )
        )
    }
}
