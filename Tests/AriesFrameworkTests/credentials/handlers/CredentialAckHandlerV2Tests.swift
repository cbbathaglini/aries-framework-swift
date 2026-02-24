//
//  CredentialAckHandlerV2Tests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

import XCTest
@testable import AriesFramework

final class CredentialAckHandlerV2Tests: XCTestCase {
    
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

    func test_handle_callsProcessAck_andReturnsNil() async throws {
        
        let spyService = SpyCredentialServiceV2()
        let agent = makeAgentWithSpy(spy: spyService)
        let handler = CredentialAckHandlerV2(agent: agent)

        let messageContext = InboundMessageContextTestFactory.make()

        
        let result = try await handler.handle(messageContext: messageContext)

        
        XCTAssertTrue(spyService.processAckCalled)
        XCTAssertNotNil(spyService.receivedMessageContext)

        XCTAssertEqual(
            spyService.receivedMessageContext?.message.type,
            messageContext.message.type
        )

        XCTAssertEqual(
            spyService.receivedMessageContext?.plaintextMessage,
            messageContext.plaintextMessage
        )

        XCTAssertNil(result)
    }
    
    func test_handle_propagatesError() async {
        let spyService = SpyCredentialServiceV2()
        spyService.errorToThrow = CredoError("boom")

        let agent = makeAgentWithSpy(spy: spyService)
        let handler = CredentialAckHandlerV2(agent: agent)
        let messageContext = InboundMessageContextTestFactory.make()

        do {
            _ = try await handler.handle(messageContext: messageContext)
            XCTFail("Expected error to be thrown, but no error was thrown")
        } catch {
            // success
        }
    }
}
