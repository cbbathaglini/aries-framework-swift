//
//  ProposeCredentialHandlerV2Tests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

import XCTest
@testable import AriesFramework

final class ProposeCredentialHandlerV2Tests: XCTestCase {
    
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
    
    func test_handle_autoAccept_returnsOutboundMessage() async throws {
        let spy = SpyCredentialServiceV2()
        spy.autoRespond = true

        let agent = makeAgentWithSpy(spy: spy)
        let handler = ProposeCredentialHandlerV2(agent: agent)

        let messageContext = InboundMessageContextTestFactory.make(
            connection: ConnectionRecordBuilder()
                .withId("conn-1")
                .withState(.Complete)
                .build()
        )

        let outbound = try await handler.handle(messageContext: messageContext)

        XCTAssertTrue(spy.processProposalCalled)
        XCTAssertTrue(spy.shouldAutoRespondCalled)
        XCTAssertTrue(spy.acceptProposalCalled)
        XCTAssertNotNil(outbound)
    }
    
    func test_handle_noAutoAccept_returnsNil() async throws {
        let spy = SpyCredentialServiceV2()
        spy.autoRespond = false

        let agent = makeAgentWithSpy(spy: spy)
        let handler = ProposeCredentialHandlerV2(agent: agent)

        let messageContext = InboundMessageContextTestFactory.make()

        let outbound = try await handler.handle(messageContext: messageContext)

        XCTAssertTrue(spy.processProposalCalled)
        XCTAssertTrue(spy.shouldAutoRespondCalled)
        XCTAssertFalse(spy.acceptProposalCalled)
        XCTAssertNil(outbound)
    }
    
}
