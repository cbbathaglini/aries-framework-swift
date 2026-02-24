//
//  RequestCredentialHandlerV2Tests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

import XCTest
@testable import AriesFramework

final class RequestCredentialHandlerV2Tests: XCTestCase {
    
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
        
        let spy = SpyCredentialServiceV2()
        spy.shouldAutoRespondToRequestResult = true

        let agent = makeAgentWithSpy(spy: spy)
        let handler = RequestCredentialHandlerV2(agent: agent)

        let connection = ConnectionRecordTestFactory.readyConnection()

        let messageContext = InboundMessageContextTestFactory.make(
            connection: connection
        )

        
        let outbound = try await handler.handle(messageContext: messageContext)

        
        XCTAssertNotNil(outbound)
        XCTAssertTrue(spy.processRequestCalled)
        XCTAssertTrue(spy.acceptRequestCalled)
        XCTAssertTrue(spy.shouldAutoRespondToRequestCalled)
        XCTAssertEqual(outbound?.connection.id, connection.id)
    }
    
    
    func test_handle_autoRespondFalse_returnsNil() async throws {
        
        let spy = SpyCredentialServiceV2()
        spy.shouldAutoRespondToRequestResult = false

        let agent = makeAgentWithSpy(spy: spy)
        let handler = RequestCredentialHandlerV2(agent: agent)

        let messageContext = InboundMessageContextTestFactory.make()

        
        let outbound = try await handler.handle(messageContext: messageContext)

        
        XCTAssertNil(outbound)
        XCTAssertTrue(spy.processRequestCalled)
        XCTAssertTrue(spy.shouldAutoRespondToRequestCalled)
        XCTAssertFalse(spy.acceptRequestCalled)
    }
}
