//
//  PresentationHandlerV2Tests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/26.
//

import XCTest
@testable import AriesFramework

final class PresentationHandlerV2Tests: XCTestCase {

    private var sut: PresentationHandlerV2!
    private var agent: Agent!
    private var proofServiceV2Mock: MockProofServiceV2!

    override func setUp() async throws {
        try await super.setUp()

        agent = Agent(agentConfig: .test(), agentDelegate: nil)
        proofServiceV2Mock = MockProofServiceV2(agent: agent)
        agent.proofServiceV2 = proofServiceV2Mock

        sut = PresentationHandlerV2(agent: agent)
    }

    override func tearDown() {
        sut = nil
        proofServiceV2Mock = nil
        agent = nil
        super.tearDown()
    }

    func testHandle_WhenAutoAcceptProofOnRecordIsAlways_ShouldReturnOutboundAck() async throws {
        var proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-id-1")
            .setConnectionId("conn-123")
            .setThreadId("thread-123")
            .setState(.PresentationReceived)
            .setRole(.verifier)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .setAutoAcceptProof(.always)
            .build()

        let ackMessage = PresentationAckMessageV2Builder()
            .setThreadId("thread-123")
            .setStatus(.OK)
            .build()

        proofServiceV2Mock.processPresentationRecordToReturn = proofRecord
        proofServiceV2Mock.createAckReturnMessage = ackMessage
        proofServiceV2Mock.createAckReturnRecord = proofRecord

        let presentationMessage = PresentationMessageV2Builder()
            .setComment("presentation")
            .build()

        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .withState(ConnectionState.Complete)
            .build()

        let context = try InboundMessageContextBuilder()
            .setMessage(presentationMessage)
            .setPlaintextMessage(presentationMessage.toJsonString())
            .setConnection(connection)
            .setSenderVerkey("sender-verkey")
            .setRecipientVerkey("recipient-verkey")
            .build()

        let result = try await sut.handle(messageContext: context)

        XCTAssertEqual(proofServiceV2Mock.processPresentationCallCount, 1)
        XCTAssertEqual(proofServiceV2Mock.createAckCallCount, 1)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.connection.id, "conn-123")

        let payload = try XCTUnwrap(result?.payload as? PresentationAckMessageV2)
        XCTAssertEqual(payload.status, .OK)
        XCTAssertEqual(payload.threadId, "thread-123")
    }

    func testHandle_WhenAgentConfigAutoAcceptProofIsAlways_ShouldReturnOutboundAck() async throws {
        agent.agentConfig.autoAcceptProof = .always

        var proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-id-2")
            .setConnectionId("conn-123")
            .setThreadId("thread-456")
            .setState(.PresentationReceived)
            .setRole(.verifier)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .setAutoAcceptProof(.never)
            .build()

        let ackMessage = PresentationAckMessageV2Builder()
            .setThreadId("thread-456")
            .setStatus(.OK)
            .build()

        proofServiceV2Mock.processPresentationRecordToReturn = proofRecord
        proofServiceV2Mock.createAckReturnMessage = ackMessage
        proofServiceV2Mock.createAckReturnRecord = proofRecord

        let presentationMessage = PresentationMessageV2Builder()
            .setComment("presentation")
            .build()

        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .withState(ConnectionState.Complete)
            .build()

        let context = try InboundMessageContextBuilder()
            .setMessage(presentationMessage)
            .setPlaintextMessage(presentationMessage.toJsonString())
            .setConnection(connection)
            .setSenderVerkey("sender-verkey")
            .setRecipientVerkey("recipient-verkey")
            .build()

        let result = try await sut.handle(messageContext: context)

        XCTAssertEqual(proofServiceV2Mock.processPresentationCallCount, 1)
        XCTAssertEqual(proofServiceV2Mock.createAckCallCount, 1)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.connection.id, "conn-123")

        let payload = try XCTUnwrap(result?.payload as? PresentationAckMessageV2)
        XCTAssertEqual(payload.threadId, "thread-456")
    }

    func testHandle_WhenAutoAcceptIsNotAlways_ShouldReturnNil() async throws {
        agent.agentConfig.autoAcceptProof = .never

        let proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-id-3")
            .setConnectionId("conn-123")
            .setThreadId("thread-789")
            .setState(.PresentationReceived)
            .setRole(.verifier)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .setAutoAcceptProof(.never)
            .build()

        proofServiceV2Mock.processPresentationRecordToReturn = proofRecord

        let presentationMessage = PresentationMessageV2Builder()
            .setComment("presentation")
            .build()

        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .withState(ConnectionState.Complete)
            .build()

        let context = try InboundMessageContextBuilder()
            .setMessage(presentationMessage)
            .setPlaintextMessage(presentationMessage.toJsonString())
            .setConnection(connection)
            .setSenderVerkey("sender-verkey")
            .setRecipientVerkey("recipient-verkey")
            .build()

        let result = try await sut.handle(messageContext: context)

        XCTAssertEqual(proofServiceV2Mock.processPresentationCallCount, 1)
        XCTAssertEqual(proofServiceV2Mock.createAckCallCount, 0)
        XCTAssertNil(result)
    }

    func testHandle_WhenProcessPresentationThrows_ShouldPropagateError() async {
        let presentationMessage = PresentationMessageV2Builder()
            .setComment("presentation")
            .build()

        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .withState(ConnectionState.Complete)
            .build()

        let context = try! InboundMessageContextBuilder()
            .setMessage(presentationMessage)
            .setPlaintextMessage(presentationMessage.toJsonString())
            .setConnection(connection)
            .setSenderVerkey("sender-verkey")
            .setRecipientVerkey("recipient-verkey")
            .build()

        proofServiceV2Mock.processPresentationErrorToThrow = CredoError("process presentation failed")

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.handle(messageContext: context)
        } assertion: { error in
            //XCTAssertTrue(String(describing: error).contains("process presentation failed"))
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofServiceV2Mock.processPresentationCallCount, 1)
        XCTAssertEqual(proofServiceV2Mock.createAckCallCount, 0)
    }

    func testHandle_WhenCreateAckThrows_ShouldPropagateError() async {
        var proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-id-4")
            .setConnectionId("conn-123")
            .setThreadId("thread-999")
            .setState(.PresentationReceived)
            .setRole(.verifier)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .setAutoAcceptProof(.always)
            .build()

        proofServiceV2Mock.processPresentationRecordToReturn = proofRecord
        proofServiceV2Mock.createAckErrorToThrow = CredoError("create ack failed")

        let presentationMessage = PresentationMessageV2Builder()
            .setComment("presentation")
            .build()

        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .withState(ConnectionState.Complete)
            .build()

        let context = try! InboundMessageContextBuilder()
            .setMessage(presentationMessage)
            .setPlaintextMessage(presentationMessage.toJsonString())
            .setConnection(connection)
            .setSenderVerkey("sender-verkey")
            .setRecipientVerkey("recipient-verkey")
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.handle(messageContext: context)
        } assertion: { error in
            //XCTAssertTrue(String(describing: error).contains("create ack failed"))
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofServiceV2Mock.processPresentationCallCount, 1)
        XCTAssertEqual(proofServiceV2Mock.createAckCallCount, 1)
    }

    func testMessageType_ShouldMatchPresentationMessageType() {
        XCTAssertEqual(sut.messageType, PresentationMessageV2.type)
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
