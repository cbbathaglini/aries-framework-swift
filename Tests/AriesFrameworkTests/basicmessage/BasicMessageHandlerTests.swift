//
//  BasicMessageHandlerTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 20/02/26.
//

import XCTest
@testable import AriesFramework

final class BasicMessageHandlerTests: XCTestCase {

    func test_handle_success_savesAndNotifies() async throws {
        // Arrange
        let repository = MockBasicMessageRepository()
        let delegate = MockAgentDelegate()

        let agent = MockBasicMessageHandlerAgent()
        agent._basicMessageRepository = repository
        agent._agentDelegate = delegate

        let handler = BasicMessageHandler(agent: agent)

        let message = BasicMessage(content: "Hello")
        let jsonData = try JSONEncoder().encode(message)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        let context = InboundMessageContext(
            message: message,
            plaintextMessage: jsonString,
            connection: nil,
            senderVerkey: nil,
            recipientVerkey: nil
        )

        // Act
        let result = try await handler.handle(messageContext: context)

        // Assert
        XCTAssertNil(result)
        XCTAssertEqual(repository.savedRecords.count, 1)
        XCTAssertEqual(repository.savedRecords.first?.content, "Hello")
        XCTAssertNotNil(delegate.receivedRecord)
        XCTAssertEqual(delegate.receivedRecord?.content, "Hello")
    }
    
    func test_handle_withoutRepository_throws() async throws {

        let agent = MockBasicMessageHandlerAgent()
        agent._basicMessageRepository = nil

        let handler = BasicMessageHandler(agent: agent)

        let message = BasicMessage(content: "Hello")
        let jsonData = try JSONEncoder().encode(message)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        let context = InboundMessageContext(
            message: message,
            plaintextMessage: "{}",
            connection: nil,
            senderVerkey: nil,
            recipientVerkey: nil
        )

        await XCTAssertThrowsErrorAsync(
            { try await handler.handle(messageContext: context) },
            expectedError: AriesFrameworkError.self
        )
    }
    
    func XCTAssertThrowsErrorAsync<T: Error>(
        _ expression: @escaping () async throws -> Void,
        expectedError: T.Type,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            try await expression()
            XCTFail("Expected error to be thrown", file: file, line: line)
        } catch {
            XCTAssertTrue(error is T, "Unexpected error type: \(error)", file: file, line: line)
        }
    }
    
    func test_handle_invalidJson_throws() async throws {

        let repository = MockBasicMessageRepository()

        let agent = MockBasicMessageHandlerAgent()
        agent._basicMessageRepository = repository

        let handler = BasicMessageHandler(agent: agent)

        let message = BasicMessage(content: "Hello")
        let jsonData = try JSONEncoder().encode(message)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        let context = InboundMessageContext(
            message: message,
            plaintextMessage: "{ invalid json }",
            connection: nil,
            senderVerkey: nil,
            recipientVerkey: nil
        )

        await XCTAssertThrowsErrorAsync(
            { try await handler.handle(messageContext: context) },
            expectedError: DecodingError.self
        )
    }
}

