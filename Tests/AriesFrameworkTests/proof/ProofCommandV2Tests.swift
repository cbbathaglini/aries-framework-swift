//
//  ProofCommandV2Tests.swift
//  aries-framework-swiftTests
//

import XCTest
@testable import AriesFramework
import AnyCodable

final class ProofCommandV2Tests: XCTestCase {

    var sut: ProofCommandV2!
    var agent: MockProofCommandAgent!
    var dispatcher: MockDispatcher!

    private var connectionRepository: MockConnectionRepository!
    private var mockProofServiceV2: MockProofServiceV2!
    private var verifierRepository: MockVerifierRepository!
    private var messageSender: MockMessageSender!
    private var historyRepository: MockHistoryRepository!
    private var proofRepository: MockProofRepository!

    override func setUp() {
        super.setUp()

        connectionRepository = MockConnectionRepository()
        messageSender = MockMessageSender()

        agent = MockProofCommandAgent(
            agentConfig: AgentConfigTestFactory.minimal(
                autoAcceptConnections: false
            ),
            connectionRepository: connectionRepository,
            messageSender: messageSender
        )

        verifierRepository = MockVerifierRepository(agent: agent)
        historyRepository = MockHistoryRepository(agent: agent)
        mockProofServiceV2 = MockProofServiceV2(agent: agent)
        proofRepository = MockProofRepository(agent: agent)

        agent.verifierRepository = verifierRepository
        agent.historyRepository = historyRepository
        agent.proofServiceV2 = mockProofServiceV2

        dispatcher = MockDispatcher()
        sut = ProofCommandV2(agent: agent, dispatcher: dispatcher)
    }

    override func tearDown() {
        sut = nil
        agent = nil
        dispatcher = nil
        connectionRepository = nil
        mockProofServiceV2 = nil
        verifierRepository = nil
        messageSender = nil
        historyRepository = nil
        proofRepository = nil
        super.tearDown()
    }

    func test_init_registersHandlers() {
        XCTAssertEqual(dispatcher.registeredHandlers.count, 3)
        XCTAssertTrue(dispatcher.registeredHandlers.contains { $0 is RequestPresentationHandlerV2 })
        XCTAssertTrue(dispatcher.registeredHandlers.contains { $0 is PresentationHandlerV2 })
        XCTAssertTrue(dispatcher.registeredHandlers.contains { $0 is PresentationAckHandlerV2 })
    }

    func test_requestProof_success_savesVerifierAndSendsMessage() async throws {
        let connection = ConnectionRecordBuilder()
            .withId("conn-1")
            .build()

        let proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-1")
            .setThreadId("thread-123")
            .build()

        let message = RequestPresentationMessageV2Builder().build()
        let proofRequest = AnonCredsProofRequestBuilder().build()
        let formats = [
            ProofFormatSpec(
                attachmentId: "anoncreds",
                format: "anoncreds/proof-request@v1.0"
            )
        ]

        try await connectionRepository.save(connection)

        mockProofServiceV2.createRequestReturnMessage = message
        mockProofServiceV2.createRequestReturnRecord = proofRecord

        let (returnedRecord, verifierRecord) = try await sut.requestProof(
            connectionId: "conn-1",
            proofRequest: proofRequest,
            formats: formats
        )

        XCTAssertEqual(returnedRecord.id, "proof-1")
        XCTAssertEqual(verifierRecord.globalThreadId, "thread-123")
        XCTAssertFalse(verifierRecord.offline)

        XCTAssertEqual(mockProofServiceV2.createRequestCallCount, 1)
        XCTAssertEqual(verifierRepository.saved.count, 1)
        XCTAssertEqual(verifierRepository.saved.first?.globalThreadId, "thread-123")
        XCTAssertEqual(messageSender.sentMessages.count, 1)
        XCTAssertEqual(messageSender.sentMessages.first?.connection.id, "conn-1")
    }

    func test_requestProof_whenFormatsEmpty_shouldThrow() async throws {
        let connection = ConnectionRecordBuilder()
            .withId("conn-1")
            .build()

        try await connectionRepository.save(connection)

        let proofRequest = AnonCredsProofRequestBuilder().build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.requestProof(
                connectionId: "conn-1",
                proofRequest: proofRequest,
                formats: []
            )
        } assertion: { error in
            //XCTAssertTrue(String(describing: error).contains("Proof format not informed"))
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(mockProofServiceV2.createRequestCallCount, 0)
        XCTAssertEqual(verifierRepository.saved.count, 0)
        XCTAssertEqual(messageSender.sentMessages.count, 0)
    }

    func test_requestProof_whenCreateRequestThrows_shouldPropagateError() async throws {
        let connection = ConnectionRecordBuilder()
            .withId("conn-1")
            .build()

        let proofRequest = AnonCredsProofRequestBuilder().build()
        let formats = [
            ProofFormatSpec(
                attachmentId: "anoncreds",
                format: "anoncreds/proof-request@v1.0"
            )
        ]

        try await connectionRepository.save(connection)
        mockProofServiceV2.createRequestErrorToThrow = CredoError("create request failed")

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.requestProof(
                connectionId: "conn-1",
                proofRequest: proofRequest,
                formats: formats
            )
        } assertion: { error in
            //XCTAssertTrue(String(describing: error).contains("create request failed"))
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(verifierRepository.saved.count, 0)
        XCTAssertEqual(messageSender.sentMessages.count, 0)
    }

    func test_requestProofOffline_success_savesOfflineVerifier() async throws {
        let proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-offline-1")
            .setThreadId("thread-offline-123")
            .build()

        let message = RequestPresentationMessageV2Builder().build()
        let proofRequest = AnonCredsProofRequestBuilder().build()
        let formats = [
            ProofFormatSpec(
                attachmentId: "anoncreds",
                format: "anoncreds/proof-request@v1.0"
            )
        ]

        mockProofServiceV2.createRequestReturnMessage = message
        mockProofServiceV2.createRequestReturnRecord = proofRecord

        let (returnedRecord, verifierRecord) = try await sut.requestProofOffline(
            proofRequest: proofRequest,
            formats: formats
        )

        XCTAssertEqual(returnedRecord.id, "proof-offline-1")
        XCTAssertEqual(verifierRecord.globalThreadId, "thread-offline-123")
        XCTAssertTrue(verifierRecord.offline)

        XCTAssertEqual(mockProofServiceV2.createRequestCallCount, 1)
        XCTAssertEqual(verifierRepository.saved.count, 1)
        XCTAssertEqual(messageSender.sentMessages.count, 0)
    }

    func test_processRequest_delegatesToProofService() async throws {
        let expectedRecord = ProofExchangeRecordBuilder()
            .setId("proof-process-1")
            .build()

        let requestMessage = RequestPresentationMessageV2Builder().build()
        mockProofServiceV2.processRequestRecordToReturn = expectedRecord

        let result = try await sut.processRequest(requestMessage: requestMessage)

        XCTAssertEqual(result.id, "proof-process-1")
        XCTAssertEqual(mockProofServiceV2.processRequestCallCount, 1)
        XCTAssertNil(mockProofServiceV2.receivedProcessRequestMessageContext)
        XCTAssertNotNil(mockProofServiceV2.receivedProcessRequestMessage)
    }

    func test_processOfflineAck_delegatesToProofService() async throws {
    
        let proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-offline-ack")
            .build()

        mockProofServiceV2.processOfflineAckReturnRecord = proofRecord
        try await sut.processOfflineAck(proofRecord: proofRecord)

        XCTAssertEqual(mockProofServiceV2.processOfflineAckCallCount, 1)
        XCTAssertEqual(
            mockProofServiceV2.receivedProcessOfflineAckProofRecord?.id,
            "proof-offline-ack"
        )
    }

    func test_processPresentationOffline_success_returnsTuple() async throws {
        let presentationMessage = PresentationMessageV2Builder().build()

        let expectedRecord = ProofExchangeRecordBuilder()
            .setId("proof-presentation-offline")
            .setIsVerified(true)
            .build()

        mockProofServiceV2.processPresentationOfflineRecordToReturn = expectedRecord

        let (record, result) = try await sut.processPresentationOffline(
            presentationMessage: presentationMessage.toJsonString()
        )

        XCTAssertEqual(record?.id, "proof-presentation-offline")
        XCTAssertTrue(result)
        XCTAssertEqual(mockProofServiceV2.processPresentationOfflineCallCount, 1)
    }

    func test_processPresentationOffline_whenMessageInvalid_shouldThrow() async {
        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.processPresentationOffline(
                presentationMessage: "{ invalid json"
            )
        } assertion: { error in
            //XCTAssertTrue(String(describing: error).contains("Failed to decode PresentationMessageV2"))
            XCTAssertTrue(error is CredoError)
        }
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
