//
//  OfferCredentialHandlerV2Tests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

import XCTest
@testable import AriesFramework

final class OfferCredentialHandlerV2Tests: XCTestCase {
    
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
    
    func test_handle_autoRespondTrue_returnsRequestMessage() async throws {
        
        let spy = SpyCredentialServiceV2()
        spy.shouldAutoRespondToOfferResult = true

        let agent = makeAgentWithSpy(spy: spy)
        let handler = OfferCredentialHandlerV2(agent: agent)

        let messageContext = InboundMessageContextTestFactory.make(
            connection: ConnectionRecordTestFactory.readyConnection()
        )

        
        let result = try await handler.handle(messageContext: messageContext)

        
        XCTAssertTrue(spy.processOfferCalled)
        XCTAssertTrue(spy.shouldAutoRespondToOfferCalled)
        XCTAssertTrue(spy.acceptOfferCalled)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.payload is RequestCredentialMessageV2)
    }
    
    func test_handle_autoRespondFalse_returnsNil() async throws {
        
        let spy = SpyCredentialServiceV2()
        spy.shouldAutoRespondToOfferResult = false

        let agent = makeAgentWithSpy(spy: spy)
        let handler = OfferCredentialHandlerV2(agent: agent)

        let messageContext = InboundMessageContextTestFactory.make(
            connection: ConnectionRecordTestFactory.readyConnection()
        )

        
        let result = try await handler.handle(messageContext: messageContext)

        
        XCTAssertTrue(spy.processOfferCalled)
        XCTAssertTrue(spy.shouldAutoRespondToOfferCalled)
        XCTAssertFalse(spy.acceptOfferCalled)

        XCTAssertNil(result)
    }
    
}
