//
//  ConnectionServiceTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

import XCTest
@testable import AriesFramework

final class ConnectionServiceTests: XCTestCase {

    var repo: MockConnectionRepository!
    var oob: MockOutOfBandService!
    var mediation: MockMediationRecipient!
    var wallet: MockWallet!
    var agent: MockConnectionServiceAgent!
    var service: ConnectionService!

    override func setUp() {
        super.setUp()

        repo = MockConnectionRepository()
        oob = MockOutOfBandService()
        mediation = MockMediationRecipient()
        wallet = MockWallet()

        mediation.routingToReturn = Routing(
            endpoints: ["https://example.com"],
            verkey: "verkey",
            did: "did:test:123",
            routingKeys: [],
            mediatorId: nil
        )

        agent = MockConnectionServiceAgent(
            agentConfig: AgentConfigBuilder()
                .withLabel("AgentLabel")
                .notAutoAcceptCredential()
                .connectionImageUrl("https://img.test/agent.png")
                .build(),
            connectionRepository: repo,
            mediationRecipient: mediation,
            outOfBandService: oob,
            wallet: wallet
        )

        service = ConnectionService(agent: agent)
    }

    override func tearDown() {
        service = nil
        agent = nil
        wallet = nil
        mediation = nil
        oob = nil
        repo = nil
        super.tearDown()
    }
    
    func test_createConnection_buildsDidDocWithEndpointsAndRoutingKeys() async throws {
        let routing = Routing(
            endpoints: ["https://e1.com", "https://e2.com"],
            verkey: "vk",
            did: "did:test:abc",
            routingKeys: ["rk1", "rk2"],
            mediatorId: "med1"
        )

        let record = try await service.createConnection(
            role: .Inviter,
            state: .Invited,
            alias: "alias",
            routing: routing,
            theirLabel: nil,
            autoAcceptConnection: nil,
            multiUseInvitation: false,
            imageUrl: nil,
            threadId: nil
        )

        XCTAssertEqual(record.did, "did:test:abc")
        XCTAssertEqual(record.verkey, "vk")
        XCTAssertEqual(record.mediatorId, "med1")
        XCTAssertEqual(record.didDoc.service.count, 2)
        XCTAssertEqual(record.didDoc.didCommServices().first?.serviceEndpoint, "https://e2.com")
        XCTAssertEqual(record.didDoc.didCommServices().first?.routingKeys, ["rk1", "rk2"])
    }
    
    func test_processInvitation_throwsWhenBothNil() async throws {
        await XCTAssertThrowsErrorAsync {
            _ = try await self.service.processInvitation(
                nil,
                outOfBandInvitation: nil,
                routing: self.mediation.routingToReturn,
                autoAcceptConnection: nil,
                alias: nil
            )
        }
    }

    func test_processInvitation_throwsWhenBothProvided() async throws {
        await XCTAssertThrowsErrorAsync {
            _ = try await self.service.processInvitation(
                ConnectionInvitationMessage(label: "x"),
                outOfBandInvitation: try OutOfBandInvitationTestFactory.make(),
                routing: self.mediation.routingToReturn
            )
        }
    }
    
    func test_processInvitation_savesConnectionRecordAndReturnsIt() async throws {
        let invitation = ConnectionInvitationMessage(label: "TheirLabel")

        let record = try await service.processInvitation(
            invitation,
            outOfBandInvitation: nil,
            routing: mediation.routingToReturn,
            autoAcceptConnection: false,
            alias: "alias"
        )

        let stored = try await repo.getById(record.id)

        XCTAssertEqual(record.role, .Invitee)
        XCTAssertEqual(record.state, .Invited)
        XCTAssertEqual(record.theirLabel, "TheirLabel")
        XCTAssertEqual(record.alias, "alias")
        XCTAssertEqual(stored.id, record.id)
    }
    
    func test_createRequest_setsRequestedAndThreadIdAndDefaults() async throws {
        let routing = try XCTUnwrap(mediation.routingToReturn)

        let invited = try await service.createConnection(
            role: .Invitee,
            state: .Invited,
            invitation: ConnectionInvitationMessage(label: "x"),
            alias: nil,
            routing: routing,
            theirLabel: "x",
            autoAcceptConnection: nil,
            multiUseInvitation: false,
            imageUrl: nil,
            threadId: nil
        )

        try await repo.save(invited)

        let outbound = try await service.createRequest(connectionId: invited.id)

        XCTAssertEqual(outbound.connection.state, ConnectionState.Requested)
        XCTAssertEqual(outbound.connection.threadId, invited.id)
        XCTAssertEqual((outbound.payload as? ConnectionRequestMessage)?.label, agent.agentConfig.label)
        XCTAssertEqual((outbound.payload as? ConnectionRequestMessage)?.imageUrl, agent.agentConfig.connectionImageUrl)
    }
    
    func test_findByInvitationKey_returnsFirst() async throws {
        var c1 = ConnectionRecordTestFactory.notReadyConnection()
        c1.tags = (c1.tags ?? [:]).merging(["invitationKey": "k1"]) { $1 }
        try await repo.save(c1)

        var c2 = ConnectionRecordTestFactory.notReadyConnection()
        c2.tags = (c2.tags ?? [:]).merging(["invitationKey": "k1"]) { $1 }
        try await repo.save(c2)

        let found = await service.findByInvitationKey("k1")
        XCTAssertNotNil(found)
    }

    func test_findAllByInvitationKey_returnsAll() async throws {
        var c1 = ConnectionRecordTestFactory.notReadyConnection()
        c1.tags = (c1.tags ?? [:]).merging(["invitationKey": "k1"]) { $1 }
        try await repo.save(c1)

        var c2 = ConnectionRecordTestFactory.notReadyConnection()
        c2.tags = (c2.tags ?? [:]).merging(["invitationKey": "k1"]) { $1 }
        try await repo.save(c2)

        let all = await service.findAllByInvitationKey("k1")
        XCTAssertEqual(all.count, 2)
    }
    
    func test_fetchState_returnsCompleteWithoutRepoRead() async throws {
        var record = ConnectionRecordTestFactory.readyConnection(state: .Complete)
        try await repo.save(record)

        let state = try await service.fetchState(connectionRecord: record)
        XCTAssertEqual(state, .Complete)
    }

    func test_fetchState_readsFromRepoWhenNotComplete() async throws {
        var record = ConnectionRecordTestFactory.notReadyConnection(state: .Invited)
        try await repo.save(record)

        record.state = .Requested
        try await repo.update(record)

        let state = try await service.fetchState(connectionRecord: record)
        XCTAssertEqual(state, .Requested)
    }
    
    
    private func XCTAssertThrowsErrorAsync(_ block: @escaping () async throws -> Void) async {
        do {
            try await block()
            XCTFail("Expected to throw, but did not throw.")
        } catch { }
    }
}
