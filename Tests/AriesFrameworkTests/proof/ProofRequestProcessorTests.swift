//
//  ProofRequestProcessorTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//

import XCTest
@testable import AriesFramework

final class ProofRequestProcessorTests: XCTestCase {

    private var sut: ProofRequestProcessor!

    private var agent: Agent!
    private var proofFormatCoordinatorSpy: MockProofFormatCoordinator!
    private var proofRepositorySpy: MockProofRepository!
    private var historyServiceSpy: MockHistoryService!
    private var common: CommonFunctions!
    private var delegateSpy: MockAgentDelegate!

    override func setUp() async throws {
        try await super.setUp()

        agent = Agent(agentConfig: .test(), agentDelegate: nil)

        proofFormatCoordinatorSpy = MockProofFormatCoordinator(agent: agent)
        proofRepositorySpy = MockProofRepository(agent: agent)
        historyServiceSpy = MockHistoryService()
        delegateSpy = MockAgentDelegate()

        agent.proofRepository = proofRepositorySpy
        agent.agentDelegate = delegateSpy

        let mockFormatService = MockProofFormatService(
            formatKey: "anoncreds",
            supportedFormats: ["anoncreds/proof@v1.0"]
        )

        common = CommonFunctions(
            agent: agent,
            proofFormats: [mockFormatService]
        )

        sut = ProofRequestProcessor(
            agent: agent,
            proofFormatCoordinator: proofFormatCoordinatorSpy,
            proofRepository: proofRepositorySpy,
            historyService: historyServiceSpy,
            common: common
        )
    }

    override func tearDown() {
        sut = nil
        delegateSpy = nil
        historyServiceSpy = nil
        proofRepositorySpy = nil
        proofFormatCoordinatorSpy = nil
        common = nil
        agent = nil
        super.tearDown()
    }

    func testProcess_WhenNewRecord_ShouldCreateProofRecord() async throws {
        let requestMessage = RequestPresentationMessageV2Builder()
            .setComment("proof request")
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setRequestPresentationAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        var encodedRequest = requestMessage
        encodedRequest.setThread(threadId: "thread-123", parentThreadId: "parent-123")

        let context = try InboundMessageContextBuilder()
            .setMessage(encodedRequest)
            .setPlaintextMessage(encodedRequest.toJsonString())
            .setConnection(
                ConnectionRecordBuilder()
                    .withId("conn-123")
                    .withState(ConnectionState.Complete)
                    .build()
            )
            .setSenderVerkey("sender-key")
            .setRecipientVerkey("recipient-key")
            .build()

        let result = try await sut.process(messageContext: context, requestMessage: nil)

        XCTAssertEqual(result.connectionId, "conn-123")
        XCTAssertEqual(result.threadId, "thread-123")
        XCTAssertEqual(result.parentThreadId, "parent-123")
        XCTAssertEqual(result.state, .RequestReceived)
        XCTAssertEqual(result.role, .prover)
        XCTAssertEqual(result.protocolVersion, ProofConstants.PROTOCOL_VERSION_V2)
        XCTAssertEqual(result.comment, "proof request")

        XCTAssertTrue(proofFormatCoordinatorSpy.processRequestCalled)
        XCTAssertEqual(proofRepositorySpy.savedRecords.count, 1)
        XCTAssertEqual(proofRepositorySpy.savedRecords.first?.threadId, "thread-123")

        XCTAssertEqual(historyServiceSpy.savedRecords.count, 1)
        XCTAssertEqual(historyServiceSpy.savedRecords.first?.historyType, .proofRequestReceived)

        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.state, .RequestReceived)
    }

    func testProcess_WhenExistingRecord_ShouldUpdateExistingRecord() async throws {
        let existingRecord = ProofExchangeRecordBuilder()
            .setId("proof-id-1")
            .setThreadId("thread-123")
            .setConnectionId("conn-123")
            .setState(.ProposalSent)
            .setRole(.prover)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        proofRepositorySpy.stub([existingRecord])

        let requestMessage = RequestPresentationMessageV2Builder()
            .setComment("updated request")
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setRequestPresentationAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        var encodedRequest = requestMessage
        encodedRequest.setThread(threadId: "thread-123", parentThreadId: nil)

        let context = try InboundMessageContextBuilder()
            .setMessage(encodedRequest)
            .setPlaintextMessage(encodedRequest.toJsonString())
            .setConnection(
                ConnectionRecordBuilder()
                    .withId("conn-123")
                    .withState(ConnectionState.Complete)
                    .build()
            )
            .setSenderVerkey("sender-key")
            .setRecipientVerkey("recipient-key")
            .build()

        let result = try await sut.process(messageContext: context, requestMessage: nil)

        XCTAssertEqual(result.id, "proof-id-1")
        XCTAssertEqual(result.state, .RequestReceived)
        XCTAssertEqual(result.comment, "updated request")

        XCTAssertTrue(proofFormatCoordinatorSpy.processRequestCalled)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 1)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.first?.state, .RequestReceived)

        XCTAssertEqual(historyServiceSpy.savedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.state, .RequestReceived)
    }

    func testProcess_WhenMessageCannotBeDecoded_ShouldThrow() async {
        let context = try! InboundMessageContextBuilder()
            .setMessage(RequestPresentationMessageV2Builder().build())
            .setPlaintextMessage("{\"invalid\":\"json\"}")
            .setConnection(
                ConnectionRecordBuilder()
                    .withId("conn-123")
                    .withState(ConnectionState.Complete)
                    .build()
            )
            .setSenderVerkey("sender-key")
            .setRecipientVerkey("recipient-key")
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.process(messageContext: context, requestMessage: nil)
        }

        XCTAssertEqual(proofRepositorySpy.savedRecords.count, 0)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(historyServiceSpy.savedRecords.count, 0)
    }

    func testProcess_WhenNoSupportedFormats_ShouldThrow() async {
        let requestMessage = RequestPresentationMessageV2Builder()
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "unsupported",
                    format: "unsupported/format@v1.0"
                )
            ])
            .setRequestPresentationAttachments([
                Attachment.fromData(Data("{}".utf8), id: "unsupported")
            ])
            .build()

        var encodedRequest = requestMessage
        encodedRequest.setThread(threadId: "thread-123", parentThreadId: nil)

        let context = try! InboundMessageContextBuilder()
            .setMessage(encodedRequest)
            .setPlaintextMessage(encodedRequest.toJsonString())
            .setConnection(
                ConnectionRecordBuilder()
                    .withId("conn-123")
                    .withState(ConnectionState.Complete)
                    .build()
            )
            .setSenderVerkey("sender-key")
            .setRecipientVerkey("recipient-key")
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.process(messageContext: context, requestMessage: nil)
        } assertion: { error in
//            XCTAssertTrue(
//                String(describing: error).contains("No supported formats") ||
//                error.localizedDescription.contains("No supported formats")
//            )
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofRepositorySpy.savedRecords.count, 0)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
    }

    func testProcess_WhenExistingRecordHasInvalidState_ShouldThrow() async {
        let existingRecord = ProofExchangeRecordBuilder()
            .setId("proof-id-1")
            .setThreadId("thread-123")
            .setConnectionId("conn-123")
            .setState(.RequestReceived)
            .setRole(.prover)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        proofRepositorySpy.stub([existingRecord])

        let requestMessage = RequestPresentationMessageV2Builder()
            .setComment("request")
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setRequestPresentationAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        var encodedRequest = requestMessage
        encodedRequest.setThread(threadId: "thread-123", parentThreadId: nil)

        let context = try! InboundMessageContextBuilder()
            .setMessage(encodedRequest)
            .setPlaintextMessage(encodedRequest.toJsonString())
            .setConnection(
                ConnectionRecordBuilder()
                    .withId("conn-123")
                    .withState(ConnectionState.Complete)
                    .build()
            )
            .setSenderVerkey("sender-key")
            .setRecipientVerkey("recipient-key")
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.process(messageContext: context, requestMessage: nil)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(historyServiceSpy.savedRecords.count, 0)
    }

    func testProcess_WhenConnectionIsNil_ShouldCreateConnectionlessRecord() async throws {
        let requestMessage = RequestPresentationMessageV2Builder()
            .setComment("connectionless request")
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setRequestPresentationAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        var encodedRequest = requestMessage
        encodedRequest.setThread(threadId: "thread-connectionless", parentThreadId: nil)

        let context = try InboundMessageContextBuilder()
            .setMessage(encodedRequest)
            .setPlaintextMessage(encodedRequest.toJsonString())
            .setConnection(nil)
            .setSenderVerkey("sender-key")
            .setRecipientVerkey("recipient-key")
            .build()

        let result = try await sut.process(messageContext: context, requestMessage: nil)

        XCTAssertEqual(result.connectionId, "connectionless")
        XCTAssertEqual(result.threadId, "thread-connectionless")
        XCTAssertEqual(result.state, .RequestReceived)

        XCTAssertEqual(proofRepositorySpy.savedRecords.count, 1)
        XCTAssertEqual(historyServiceSpy.savedRecords.count, 1)
    }

    func testProcess_WhenRequestMessageProvidedDirectly_ShouldUseIt() async throws {
        let requestMessage = RequestPresentationMessageV2Builder()
            .setComment("direct request")
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setRequestPresentationAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        var request = requestMessage
        request.setThread(threadId: "thread-direct", parentThreadId: "parent-direct")

        let result = try await sut.process(messageContext: nil, requestMessage: request)

        XCTAssertEqual(result.connectionId, "connectionless")
        XCTAssertEqual(result.threadId, "thread-direct")
        XCTAssertEqual(result.parentThreadId, "parent-direct")
        XCTAssertEqual(result.comment, "direct request")
        XCTAssertEqual(result.state, .RequestReceived)

        XCTAssertEqual(proofRepositorySpy.savedRecords.count, 1)
        XCTAssertEqual(historyServiceSpy.savedRecords.count, 1)
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
