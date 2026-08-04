//
//  CredentialsV2Test.swift
//  aries-framework-swift
//

import XCTest
import AnyCodable
@testable import AriesFramework

class CredentialsV2Test: XCTestCase {
    var faberAgent: Agent!
    var aliceAgent: Agent!
    var credDefId: String!
    var faberConnection: ConnectionRecord!
    var aliceConnection: ConnectionRecord!

    let credentialPreview = CredentialPreviewV2.fromDictionary([
        "name": "John",
        "age": "99"
    ])

    let credentialFormat: [String: AnyCodable] = [
        "hlindy/cred@v2.0": AnyCodable([
            "credential_definition_id": "cred-def-id"
        ])
    ]

    override func setUp() async throws {
        try await super.setUp()

        (faberAgent, aliceAgent, faberConnection, aliceConnection) = try await TestHelper.setupCredentialTests()
        credDefId = try await TestHelper.prepareForIssuance(faberAgent, ["name", "age"])
    }

    override func tearDown() async throws {
        try await faberAgent?.reset()
        try await aliceAgent?.reset()
        try await super.tearDown()
    }

    func getCredentialRecord(for agent: Agent, threadId: String) async throws -> CredentialExchangeRecord {
        let credentialRecord = try await agent.credentialExchangeRepository.getByThreadAndConnectionId(threadId: threadId, connectionId: nil)
        return credentialRecord
    }

    func testCredentialOffer() async throws {
        // Faber starts with credential offer to Alice.
        var record = try await faberAgent.credentialsV2.offerCredential(
            options: OfferCredentialOptions(
                connectionId: faberConnection.id,
                comment: "Offer to Alice",
                protocolVersion: CredentialsConstants.PROTOCOL_VERSION_V2,
                credentialFormat: credentialFormat
            )
        )
        try await Task.sleep(nanoseconds: UInt64(0.1 * SECOND))

        let threadId = record.threadId
        var aliceCredentialRecord = try await getCredentialRecord(for: aliceAgent, threadId: threadId)
        XCTAssertEqual(aliceCredentialRecord.state, CredentialState.OfferReceived)

        _ = try await aliceAgent.credentialsV2.acceptOffer(
            options: AcceptCredentialOfferOptionsV2(
                credentialExchangeRecord: aliceCredentialRecord
            )
        )
        try await Task.sleep(nanoseconds: UInt64(0.1 * SECOND))

        record = try await getCredentialRecord(for: faberAgent, threadId: threadId)
        XCTAssertEqual(record.state, CredentialState.RequestReceived)

        _ = try await faberAgent.credentialServiceV2.acceptRequest(
            options: AcceptRequestOptionsV2(
                credentialExchangeRecord: record
            )
        )
        try await Task.sleep(nanoseconds: UInt64(0.1 * SECOND))

        aliceCredentialRecord = try await getCredentialRecord(for: aliceAgent, threadId: threadId)
        XCTAssertEqual(aliceCredentialRecord.state, CredentialState.CredentialReceived)

        _ = try await aliceAgent.credentialServiceV2.acceptCredential(aliceCredentialRecord)
        try await Task.sleep(nanoseconds: UInt64(0.1 * SECOND))

        aliceCredentialRecord = try await getCredentialRecord(for: aliceAgent, threadId: threadId)
        XCTAssertEqual(aliceCredentialRecord.state, CredentialState.Done)
        record = try await getCredentialRecord(for: faberAgent, threadId: threadId)
        XCTAssertEqual(record.state, CredentialState.Done)
    }

    func testAutoAcceptAgentConfig() async throws {
        aliceAgent.agentConfig.autoAcceptCredential = .always
        faberAgent.agentConfig.autoAcceptCredential = .always

        var record = try await faberAgent.credentialsV2.offerCredential(
            options: OfferCredentialOptions(
                connectionId: faberConnection.id,
                comment: "Offer to Alice",
                protocolVersion: CredentialsConstants.PROTOCOL_VERSION_V2,
                credentialFormat: credentialFormat
            )
        )
        try await Task.sleep(nanoseconds: UInt64(1 * SECOND)) // Need enough time to finish exchange a credential.

        let threadId = record.threadId
        let aliceCredentialRecord = try await getCredentialRecord(for: aliceAgent, threadId: threadId)
        record = try await getCredentialRecord(for: faberAgent, threadId: threadId)

        XCTAssertEqual(aliceCredentialRecord.state, CredentialState.Done)
        XCTAssertEqual(record.state, CredentialState.Done)
    }
}
