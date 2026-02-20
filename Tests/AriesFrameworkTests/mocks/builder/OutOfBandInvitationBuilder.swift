//
//  OutOfBandInvitationBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework
import Foundation

final class OutOfBandInvitationBuilder {

    private var id = UUID().uuidString
    private var label = "Test Agent"
    private var goalCode: String?
    private var goal: String?
    private var accept: [String]?
    private var handshakeProtocols: [HandshakeProtocol]?
    private var requests: [Attachment]?
    private var services: [OutOfBandDidCommService] = []
    private var imageUrl: String?

    init() {
        withService()
    }

    func withId(_ id: String) -> Self {
        self.id = id
        return self
    }

    func withLabel(_ label: String) -> Self {
        self.label = label
        return self
    }

    func withGoal(code: String, goal: String) -> Self {
        self.goalCode = code
        self.goal = goal
        return self
    }

    func withHandshakeProtocols(_ protocols: [HandshakeProtocol]) -> Self {
        self.handshakeProtocols = protocols
        return self
    }

    func withImageUrl(_ url: String) -> Self {
        self.imageUrl = url
        return self
    }

    func withService(
        endpoint: String = "https://example.com",
        recipientKey: String = "did:key:z6MkTestKey",
        routingKeys: [String] = []
    ) -> Self {

        let service = OutOfBandDidCommService.oobDidDocument(
            OutOfBandDidDocumentService(
                id: "#service-1",
                serviceEndpoint: endpoint,
                recipientKeys: [recipientKey],
                routingKeys: routingKeys
            )
        )

        self.services = [service]
        return self
    }

    func build() -> OutOfBandInvitation {
        return OutOfBandInvitation(
            id: id,
            label: label,
            goalCode: goalCode,
            goal: goal,
            accept: accept,
            handshakeProtocols: handshakeProtocols,
            requests: requests,
            services: services,
            imageUrl: imageUrl
        )
    }
}
