//
//  PresentationAckHandlerV2Tests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/26.
//

import XCTest
@testable import AriesFramework

final class PresentationAckHandlerV2Tests: XCTestCase {

    private var sut: PresentationAckHandlerV2!
    private var agent: Agent!
    private var proofServiceV2Mock: MockProofServiceV2!

    override func setUp() async throws {
        try await super.setUp()

        agent = Agent(agentConfig: .test(), agentDelegate: nil)
        proofServiceV2Mock = MockProofServiceV2(agent: agent)
        agent.proofServiceV2 = proofServiceV2Mock

        sut = PresentationAckHandlerV2(agent: agent)
    }

    override func tearDown() {
        sut = nil
        proofServiceV2Mock = nil
        agent = nil
        super.tearDown()
    }

    func testHandle_WhenProcessAckSucceeds_ShouldCallProcessAckAndReturnNil() async throws {
        let ackMessage = PresentationAckMessageV2Builder()
            .setThreadId("thread-123")
            .setStatus(.OK)
            .build()

        let context = try InboundMessageContextBuilder()
            .setMessage(ackMessage)
            .setPlaintextMessage(ackMessage.toJsonString())
            .setConnection(nil)
            .setSenderVerkey("sender-verkey")
            .setRecipientVerkey("recipient-verkey")
            .build()

        let result = try await sut.handle(messageContext: context)

        XCTAssertNil(result)
        XCTAssertEqual(proofServiceV2Mock.processAckCallCount, 1)

        let receivedContext = try XCTUnwrap(proofServiceV2Mock.receivedMessageContext)
        let decoded = try XCTUnwrap(
            MessageSerializer.decodeFromString(receivedContext.plaintextMessage) as? PresentationAckMessageV2
        )

        XCTAssertEqual(decoded.status, .OK)
        XCTAssertEqual(decoded.threadId, "thread-123")
    }

    func testHandle_WhenProcessAckThrows_ShouldPropagateError() async {
        let ackMessage = PresentationAckMessageV2Builder()
            .setThreadId("thread-456")
            .setStatus(.OK)
            .build()

        let context = try! InboundMessageContextBuilder()
            .setMessage(ackMessage)
            .setPlaintextMessage(ackMessage.toJsonString())
            .setConnection(nil)
            .setSenderVerkey("sender-verkey")
            .setRecipientVerkey("recipient-verkey")
            .build()

        proofServiceV2Mock.errorToThrow = CredoError("process ack failed")

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.handle(messageContext: context)
        } assertion: { error in
            let message = String(describing: error)
            //XCTAssertTrue(message.contains("process ack failed"))
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofServiceV2Mock.processAckCallCount, 1)
    }

    func testMessageType_ShouldMatchPresentationAckMessageType() {
        XCTAssertEqual(sut.messageType, PresentationAckMessageV2.type)
    }

    // MARK: - Helper

    func XCTAssertThrowsErrorAsync(
        _ expression: @escaping () async throws -> Void,
        assertion: ((Error) -> Void)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await expression()
            XCTFail("Expected error to be thrown", file: file, line: line)
        } catch {
            assertion?(error)
        }
    }
}
