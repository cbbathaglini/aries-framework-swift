//
//  RequestPresentationHandlerV2Tests.swift
//  aries-framework-swiftTests
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/26.
//

import XCTest
@testable import AriesFramework
import AnyCodable

final class RequestPresentationHandlerV2Tests: XCTestCase {

    private var sut: RequestPresentationHandlerV2!
    private var agent: Agent!
    private var proofServiceV2Mock: MockProofServiceV2!
    private var proofUtilsMock: MockProofUtils!

    override func setUp() async throws {
        try await super.setUp()

        agent = Agent(agentConfig: .test(), agentDelegate: nil)
        proofServiceV2Mock = MockProofServiceV2(agent: agent)
        proofUtilsMock = MockProofUtils()

        agent.proofServiceV2 = proofServiceV2Mock
        ProofUtilsBridge.shared = proofUtilsMock

        sut = RequestPresentationHandlerV2(agent: agent)
    }

    override func tearDown() {
        ProofUtilsBridge.shared = DefaultProofUtilsBridge()

        sut = nil
        proofUtilsMock = nil
        proofServiceV2Mock = nil
        agent = nil
        super.tearDown()
    }

    func testHandle_WhenRecordAutoAcceptIsAlways_ShouldReturnOutboundPresentation() async throws {
        let record = ProofExchangeRecordBuilder()
            .setId("proof-id-1")
            .setConnectionId("conn-123")
            .setThreadId("thread-123")
            .setState(.RequestReceived)
            .setRole(.prover)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .setAutoAcceptProof(.always)
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof-request@v1.0"
                )
            ])
            .build()

        let requestMessage = RequestPresentationMessageV2Builder()
            .setComment("request")
            .build()

        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .withState(ConnectionState.Complete)
            .build()

        let presentationMessage = PresentationMessageV2Builder()
            .setComment("presentation")
            .build()

        proofServiceV2Mock.processRequestRecordToReturn = record
        proofUtilsMock.retrievedCredentialsToReturn = RetrievedCredentialsBuilder()
            .buildAnonCreds()
        proofServiceV2Mock.autoSelectedRequestedCredentialsToReturn = RequestedCredentialsBuilder()
            .build()
        proofServiceV2Mock.acceptRequestReturnMessage = presentationMessage
        proofServiceV2Mock.acceptRequestReturnRecord = record

        let context = try InboundMessageContextBuilder()
            .setMessage(requestMessage)
            .setPlaintextMessage(requestMessage.toJsonString())
            .setConnection(connection)
            .setSenderVerkey("sender")
            .setRecipientVerkey("recipient")
            .build()

        let result = try await sut.handle(messageContext: context)

        XCTAssertEqual(proofServiceV2Mock.processRequestCallCount, 1)
        //XCTAssertEqual(proofServiceV2Mock.autoSelectCredentialsCallCount, 1)
        XCTAssertEqual(proofServiceV2Mock.acceptRequestCallCount, 1)
        XCTAssertEqual(proofUtilsMock.getRequestedCredentialsCallCount, 1)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.connection.id, "conn-123")

        let payload = try XCTUnwrap(result?.payload as? PresentationMessageV2)
        XCTAssertEqual(payload.comment, "presentation")
    }

    func testHandle_WhenAgentConfigAutoAcceptIsAlways_ShouldReturnOutboundPresentation() async throws {
        agent.agentConfig.autoAcceptProof = .always

        let record = ProofExchangeRecordBuilder()
            .setId("proof-id-2")
            .setConnectionId("conn-123")
            .setThreadId("thread-456")
            .setState(.RequestReceived)
            .setRole(.prover)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .setAutoAcceptProof(.never)
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof-request@v1.0"
                )
            ])
            .build()

        let requestMessage = RequestPresentationMessageV2Builder()
            .setComment("request")
            .build()

        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .withState(ConnectionState.Complete)
            .build()

        let presentationMessage = PresentationMessageV2Builder()
            .setComment("presentation by config")
            .build()

        proofServiceV2Mock.processRequestRecordToReturn = record
        proofUtilsMock.retrievedCredentialsToReturn = RetrievedCredentialsBuilder().buildAnonCreds()
        proofServiceV2Mock.autoSelectedRequestedCredentialsToReturn = RequestedCredentialsBuilder().build()
        proofServiceV2Mock.acceptRequestReturnMessage = presentationMessage
        proofServiceV2Mock.acceptRequestReturnRecord = record

        let context = try InboundMessageContextBuilder()
            .setMessage(requestMessage)
            .setPlaintextMessage(requestMessage.toJsonString())
            .setConnection(connection)
            .setSenderVerkey("sender")
            .setRecipientVerkey("recipient")
            .build()

        let result = try await sut.handle(messageContext: context)

        XCTAssertEqual(proofServiceV2Mock.processRequestCallCount, 1)
        XCTAssertEqual(proofUtilsMock.getRequestedCredentialsCallCount, 1)
        //XCTAssertEqual(proofServiceV2Mock.autoSelectCredentialsCallCount, 1)
        XCTAssertEqual(proofServiceV2Mock.acceptRequestCallCount, 1)

        let payload = try XCTUnwrap(result?.payload as? PresentationMessageV2)
        XCTAssertEqual(payload.comment, "presentation by config")
    }

    func testHandle_WhenAutoAcceptIsNever_ShouldReturnNil() async throws {
        agent.agentConfig.autoAcceptProof = .never

        let record = ProofExchangeRecordBuilder()
            .setId("proof-id-3")
            .setConnectionId("conn-123")
            .setThreadId("thread-789")
            .setState(.RequestReceived)
            .setRole(.prover)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .setAutoAcceptProof(.never)
            .build()

        let requestMessage = RequestPresentationMessageV2Builder()
            .setComment("request")
            .build()

        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .withState(ConnectionState.Complete)
            .build()

        proofServiceV2Mock.processRequestRecordToReturn = record

        let context = try InboundMessageContextBuilder()
            .setMessage(requestMessage)
            .setPlaintextMessage(requestMessage.toJsonString())
            .setConnection(connection)
            .setSenderVerkey("sender")
            .setRecipientVerkey("recipient")
            .build()

        let result = try await sut.handle(messageContext: context)

        XCTAssertEqual(proofServiceV2Mock.processRequestCallCount, 1)
        XCTAssertEqual(proofUtilsMock.getRequestedCredentialsCallCount, 0)
        XCTAssertEqual(proofServiceV2Mock.autoSelectCredentialsCallCount, 0)
        XCTAssertEqual(proofServiceV2Mock.acceptRequestCallCount, 0)
        XCTAssertNil(result)
    }

    func testHandle_WhenProcessRequestThrows_ShouldPropagateError() async {
        let requestMessage = RequestPresentationMessageV2Builder()
            .setComment("request")
            .build()

        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .withState(ConnectionState.Complete)
            .build()

        proofServiceV2Mock.processRequestErrorToThrow = CredoError("process request failed")

        let context = try! InboundMessageContextBuilder()
            .setMessage(requestMessage)
            .setPlaintextMessage(requestMessage.toJsonString())
            .setConnection(connection)
            .setSenderVerkey("sender")
            .setRecipientVerkey("recipient")
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.handle(messageContext: context)
        } assertion: { error in
            //XCTAssertTrue(String(describing: error).contains("process request failed"))
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofServiceV2Mock.processRequestCallCount, 1)
        XCTAssertEqual(proofUtilsMock.getRequestedCredentialsCallCount, 0)
    }

    func testHandle_WhenGetRequestedCredentialsThrows_ShouldPropagateError() async {
        let record = ProofExchangeRecordBuilder()
            .setId("proof-id-4")
            .setConnectionId("conn-123")
            .setThreadId("thread-123")
            .setState(.RequestReceived)
            .setRole(.prover)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .setAutoAcceptProof(.always)
            .build()

        let requestMessage = RequestPresentationMessageV2Builder().build()
        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .withState(ConnectionState.Complete)
            .build()

        proofServiceV2Mock.processRequestRecordToReturn = record
        proofUtilsMock.errorToThrow = CredoError("retrieved credentials failed")

        let context = try! InboundMessageContextBuilder()
            .setMessage(requestMessage)
            .setPlaintextMessage(requestMessage.toJsonString())
            .setConnection(connection)
            .setSenderVerkey("sender")
            .setRecipientVerkey("recipient")
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.handle(messageContext: context)
        } assertion: { error in
            //XCTAssertTrue(String(describing: error).contains("retrieved credentials failed"))
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofServiceV2Mock.processRequestCallCount, 1)
        XCTAssertEqual(proofUtilsMock.getRequestedCredentialsCallCount, 1)
        XCTAssertEqual(proofServiceV2Mock.autoSelectCredentialsCallCount, 0)
    }

    func testHandle_WhenAutoSelectCredentialsThrows_ShouldPropagateError() async {
        let record = ProofExchangeRecordBuilder()
            .setId("proof-id-5")
            .setConnectionId("conn-123")
            .setThreadId("thread-123")
            .setState(.RequestReceived)
            .setRole(.prover)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .setAutoAcceptProof(.never)
            .build()

        let requestMessage = RequestPresentationMessageV2Builder().build()
        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .withState(ConnectionState.Complete)
            .build()

        proofServiceV2Mock.processRequestRecordToReturn = record
        proofUtilsMock.retrievedCredentialsToReturn = RetrievedCredentialsBuilder().buildAnonCreds()
        proofServiceV2Mock.autoSelectCredentialsErrorToThrow = CredoError("auto select failed")

        let context = try! InboundMessageContextBuilder()
            .setMessage(requestMessage)
            .setPlaintextMessage(requestMessage.toJsonString())
            .setConnection(connection)
            .setSenderVerkey("sender")
            .setRecipientVerkey("recipient")
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.handle(messageContext: context)
        } assertion: { error in
            //XCTAssertTrue(String(describing: error).contains("auto select failed"))
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofUtilsMock.getRequestedCredentialsCallCount, 1)
        XCTAssertEqual(proofServiceV2Mock.autoSelectCredentialsCallCount, 1)
        XCTAssertEqual(proofServiceV2Mock.acceptRequestCallCount, 0)
    }

    func testHandle_WhenAcceptRequestThrows_ShouldPropagateError() async {
        let record = ProofExchangeRecordBuilder()
            .setId("proof-id-6")
            .setConnectionId("conn-123")
            .setThreadId("thread-123")
            .setState(.RequestReceived)
            .setRole(.prover)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .setAutoAcceptProof(.always)
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof-request@v1.0"
                )
            ])
            .build()

        let requestMessage = RequestPresentationMessageV2Builder().build()
        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .withState(ConnectionState.Complete)
            .build()

        proofServiceV2Mock.processRequestRecordToReturn = record
        proofUtilsMock.retrievedCredentialsToReturn = RetrievedCredentialsBuilder().buildAnonCreds()
        proofServiceV2Mock.autoSelectedRequestedCredentialsToReturn = RequestedCredentialsBuilder().build()
        proofServiceV2Mock.acceptRequestErrorToThrow = CredoError("accept request failed")

        let context = try! InboundMessageContextBuilder()
            .setMessage(requestMessage)
            .setPlaintextMessage(requestMessage.toJsonString())
            .setConnection(connection)
            .setSenderVerkey("sender")
            .setRecipientVerkey("recipient")
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.handle(messageContext: context)
        } assertion: { error in
            //XCTAssertTrue(String(describing: error).contains("accept request failed"))
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofUtilsMock.getRequestedCredentialsCallCount, 1)
        XCTAssertEqual(proofServiceV2Mock.autoSelectCredentialsCallCount, 1)
        XCTAssertEqual(proofServiceV2Mock.acceptRequestCallCount, 1)
    }

    func testMessageType_ShouldMatchRequestPresentationMessageType() {
        XCTAssertEqual(sut.messageType, RequestPresentationMessageV2.type)
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
