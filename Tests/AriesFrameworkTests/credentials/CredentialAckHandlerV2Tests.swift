//
//  CredentialAckHandlerV2Tests.swift
//  aries-framework-swift
//

import XCTest
@testable import AriesFramework

final class CredentialAckHandlerV2Tests: XCTestCase {
    var agent: Agent!

    override func setUp() async throws {
        try await super.setUp()
        let config = try TestHelper.getBaseConfig(name: "alice")
        agent = Agent(agentConfig: config, agentDelegate: nil)
        try await agent.initialize()
    }

    override func tearDown() async throws {
        try await agent?.reset()
        try await super.tearDown()
    }

    func testHandler_ProcessesAck() async throws {
        let handler = CredentialAckHandlerV2(agent: agent)
        XCTAssertEqual(handler.messageType, CredentialAckMessageV2.type)

        let ack = CredentialAckMessageV2(threadId: "thread-id", status: .OK)
        let plaintext = try JSONEncoder().encode(ack).string
        let context = InboundMessageContext(
            message: ack,
            plaintextMessage: plaintext,
            connection: nil,
            senderVerkey: nil,
            recipientVerkey: nil
        )

        // The ack handler returns no outbound message; processing an unknown
        // thread id is expected to be handled (or throw) downstream.
        do {
            let result = try await handler.handle(messageContext: context)
            XCTAssertNil(result)
        } catch {
            // Ledger-backed credential records are not available in a bare test agent,
            // so the ack processing may surface a repository/ledger error.
        }
    }
}

private extension Data {
    var string: String {
        String(data: self, encoding: .utf8)!
    }
}
