//
//  IssueCredentialHandlerV2Tests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

import XCTest
@testable import AriesFramework

final class IssueCredentialHandlerV2Tests: XCTestCase {
    
    func makeAgentWithSpy(
        spy: SpyCredentialServiceV2
    ) -> Agent {
        
        let agent = Agent(
            agentConfig: .test(),
            agentDelegate: nil
        )
        
        agent.credentialServiceV2 = spy
        return agent
    }
    
    
    func test_handle_autoRespondTrue_returnsOutboundMessage() async throws {
        // Arrange
        let spy = SpyCredentialServiceV2()
        spy.shouldAutoRespondResult = true

        let agent = makeAgentWithSpy(spy: spy)
        let handler = IssueCredentialHandlerV2(agent: agent)

        let messageContext = InboundMessageContextTestFactory.make(
            connection: ConnectionRecordTestFactory.readyConnection()
        )

        // Act
        let result = try await handler.handle(messageContext: messageContext)

        // Assert
        XCTAssertTrue(spy.processCredentialCalled)
        XCTAssertTrue(spy.shouldAutoRespondCalled)
        XCTAssertTrue(spy.acceptCredentialCalled)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.payload is CredentialAckMessageV2)
    }
    
    func test_handle_autoRespondFalse_returnsNil() async throws {
        // Arrange
        let spy = SpyCredentialServiceV2()
        spy.shouldAutoRespondResult = false

        let agent = makeAgentWithSpy(spy: spy)
        let handler = IssueCredentialHandlerV2(agent: agent)

        let messageContext = InboundMessageContextTestFactory.make(
            connection: ConnectionRecordTestFactory.readyConnection()
        )

        // Act
        let result = try await handler.handle(messageContext: messageContext)

        // Assert
        XCTAssertTrue(spy.processCredentialCalled)
        XCTAssertTrue(spy.shouldAutoRespondCalled)
        XCTAssertFalse(spy.acceptCredentialCalled)

        XCTAssertNil(result)
    }
}
