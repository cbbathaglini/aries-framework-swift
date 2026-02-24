////
////  CredentialAckHandlerV2Tests.swift
////  aries-framework-swift
////
////  Created by Carine Bertagnolli Bathaglini on 15/10/25.
////
//
//import XCTest
//@testable import AriesFramework
//
//final class CredentialAckHandlerV2Tests: XCTestCase {
//
//    // MARK: - Mocks
//
//    class MockCredentialServiceV2: CredentialServiceV2 {
//        var processAckCalled = false
//        var shouldThrowError = false
//
//        override func processAck(_ messageContext: InboundMessageContext) async throws -> CredentialExchangeRecord {
//            processAckCalled = true
//            if shouldThrowError {
//                throw NSError(domain: "TestError", code: -1)
//            }
//            return "Processed"
//        }
//    }
//
//    class MockAgent: Agent {
//        let mockService = MockCredentialServiceV2()
//
//        override var credentialServiceV2: CredentialServiceV2? {
//            get { mockService }
//            set { /* ignore, não necessário para o mock */ }
//        }
//    }
//
//    class MockInboundMessageContext: InboundMessageContext {
//        // Adicione campos conforme necessário
//    }
//
//    // MARK: - Tests
//
//    func testHandle_CallsProcessAckAndReturnsNil() async throws {
//        // Given
//        let agent = MockAgent()
//        let handler = CredentialAckHandlerV2(agent: agent)
//        let context = MockInboundMessageContext()
//
//        
//        let result = try await handler.handle(messageContext: context)
//
//        // Then
//        XCTAssertNil(result, "O método handle deve retornar nil")
//        XCTAssertTrue(agent.mockService.processAckCalled, "processAck deve ser chamado")
//    }
//
//    func testHandle_WhenProcessAckThrows_ShouldThrowError() async {
//        // Given
//        let agent = MockAgent()
//        agent.mockService.shouldThrowError = true
//        let handler = CredentialAckHandlerV2(agent: agent)
//        let context = MockInboundMessageContext()
//
//        //when / Then
//        await XCTAssertThrowsError(try await handler.handle(messageContext: context))
//    }
//}
