//
//  PeerDIDServiceTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/12/25.
//

import XCTest
@testable import AriesFramework

final class PeerDIDServiceTests: XCTestCase {

    var mediationRecipient: MockMediationRecipient!
    var agent: Agent!
    var service: PeerDIDService!

    override func setUp() {
        super.setUp()

        mediationRecipient = MockMediationRecipient()
        mediationRecipient.routingToReturn = Routing(
            endpoints: ["https://example.com"],
            verkey: "verkey",
            did: "did:test",
            routingKeys: ["rk1"],
            mediatorId: nil
        )

        agent = Agent(
            agentConfig: AgentConfigBuilder()
                .withLabel("TestAgent")
                .build(),
            agentDelegate: nil
        )

        agent.mediationRecipient = mediationRecipient

        service = PeerDIDService(agent: agent)
    }

    override func tearDown() {
        mediationRecipient = nil
        agent = nil
        service = nil
        super.tearDown()
    }

    // MARK: - createPeerDID

    func test_createPeerDID_withLegacyService_returnsPeerDid() async throws {
        let verkey = "6MkqRYqQiSgvZQdn7wGxv8kHc8E3xv6F4Hj3w8Uq9pGJ"

        let did = try await service.createPeerDID(
            verkey: verkey,
            useLegacyService: true
        )

        XCTAssertTrue(did.starts(with: "did:peer:"))
    }

    func test_createPeerDID_withDidCommMessaging_returnsPeerDid() async throws {
        let verkey = "6MkqRYqQiSgvZQdn7wGxv8kHc8E3xv6F4Hj3w8Uq9pGJ"

        let did = try await service.createPeerDID(
            verkey: verkey,
            useLegacyService: false
        )

        XCTAssertTrue(did.starts(with: "did:peer:"))
    }

    func test_createPeerDID_usesEndpointFromMediationRecipient() async throws {
        mediationRecipient.routingToReturn = Routing(
            endpoints: ["https://custom-endpoint.com"],
            verkey: "verkey",
            did: "did:test",
            routingKeys: [],
            mediatorId: nil
        )

        let verkey = "6MkqRYqQiSgvZQdn7wGxv8kHc8E3xv6F4Hj3w8Uq9pGJ"

        let did = try await service.createPeerDID(verkey: verkey)

        let didDoc = try service.parsePeerDID(did)
        let services = didDoc.didCommServices()

        XCTAssertEqual(services.first?.serviceEndpoint, "https://custom-endpoint.com")
    }

    func test_createPeerDID_withInvalidVerkey_throwsError() async {
        let invalidVerkey = "not-a-base58-key"

        do {
            _ = try await service.createPeerDID(verkey: invalidVerkey)
            XCTFail("Expected createPeerDID to throw, but it did not")
        } catch {
            XCTAssertTrue(true)
        }
    }

    // MARK: - parsePeerDID

    func test_parsePeerDID_validPeerDid_returnsDidDoc() async throws {
        let verkey = "6MkqRYqQiSgvZQdn7wGxv8kHc8E3xv6F4Hj3w8Uq9pGJ"
        let did = try await service.createPeerDID(verkey: verkey)

        let didDoc = try service.parsePeerDID(did)

        XCTAssertEqual(didDoc.id, did)
        XCTAssertFalse(didDoc.service.isEmpty)
    }

    func test_parsePeerDID_invalidDid_throwsError() {
        XCTAssertThrowsError(
            try service.parsePeerDID("did:invalid:123")
        )
    }
}
