//
//  ProcessPresentationProofProcessorTests.swift
//  aries-framework-swiftTests
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//

import XCTest
import AnyCodable
@testable import AriesFramework

final class ProcessPresentationProofProcessorTests: XCTestCase {

    private var sut: ProcessPresentationProofProcessor!
    private var agent: Agent!
    private var common: CommonFunctions!

    private var proofRepositorySpy: MockProofRepository!
    private var didCommMessageRepositoryStub: MockDidCommMessageRepository!
    private var delegateSpy: MockAgentDelegate!
    private var proofFormatCoordinatorSpy: MockProofFormatCoordinator!
    private var connectionServiceMock: MockConnectionService!
    private var verifierRepository: MockVerifierRepository!
    private var connectionRepository: MockConnectionRepository!

    override func setUp() async throws {
        try await super.setUp()

        agent = Agent(agentConfig: .test(), agentDelegate: nil)

        proofRepositorySpy = MockProofRepository(agent: agent)
        didCommMessageRepositoryStub = MockDidCommMessageRepository(agent: agent)
        delegateSpy = MockAgentDelegate()
        proofFormatCoordinatorSpy = MockProofFormatCoordinator(agent: agent)
        connectionRepository = MockConnectionRepository()
        connectionServiceMock = MockConnectionService(connectionRepository: connectionRepository)
        verifierRepository = MockVerifierRepository(agent: agent)

        agent.proofRepository = proofRepositorySpy
        agent.didCommMessageRepository = didCommMessageRepositoryStub
        agent.agentDelegate = delegateSpy
        agent.connectionService = connectionServiceMock
        agent.verifierRepository = verifierRepository

        let mockFormatService = MockProofFormatService(
            formatKey: "anoncreds",
            supportedFormats: ["anoncreds/proof@v1.0"]
        )

        common = CommonFunctions(
            agent: agent,
            proofFormats: [mockFormatService]
        )

        sut = ProcessPresentationProofProcessor(
            agent: agent,
            proofRepository: proofRepositorySpy,
            proofFormatCoordinator: proofFormatCoordinatorSpy,
            common: common
        )
    }

    override func tearDown() {
        sut = nil
        common = nil
        proofRepositorySpy = nil
        didCommMessageRepositoryStub = nil
        delegateSpy = nil
        proofFormatCoordinatorSpy = nil
        connectionServiceMock = nil
        agent = nil
        super.tearDown()
    }

//    func testProcess_WhenPresentationIsValid_ShouldUpdateProofToPresentationReceived() async throws {
//        let proofRecord = ProofExchangeRecordBuilder()
//            .setId("proof-id-1")
//            .setThreadId("thread-123")
//            .setConnectionId("conn-123")
//            .setState(.RequestSent)
//            .setRole(.verifier)
//            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
//            .build()
//
//        proofRepositorySpy.stub([proofRecord])
//
//        let requestMessage = RequestPresentationMessageV2Builder()
//            .setComment("request")
//            .setFormats([
//                ProofFormatSpec(
//                    attachmentId: "anoncreds",
//                    format: "anoncreds/proof@v1.0"
//                )
//            ])
//            .setRequestPresentationAttachments([
//                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
//            ])
//            .build()
//
//        didCommMessageRepositoryStub.stubTyped(
//            recordId: proofRecord.id,
//            type: RequestPresentationMessageV2.type,
//            role: .Sender,
//            message: requestMessage
//        )
//
//        let presentationMessage = PresentationMessageV2Builder()
//            .setComment("presentation")
//            .setFormats([
//                ProofFormatSpec(
//                    attachmentId: "anoncreds",
//                    format: "anoncreds/proof@v1.0"
//                )
//            ])
//            .setPresentationAttachments([
//                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
//            ])
//            .enablePleaseAck()
//            .setLastPresentation(true)
//            .build()
//
//        var encodedPresentation = presentationMessage
//        encodedPresentation.setThread(threadId: proofRecord.threadId, parentThreadId: nil)
//
//        let context = try InboundMessageContextBuilder()
//            .setMessage(encodedPresentation)
//            .setPlaintextMessage(encodedPresentation.toJsonString())
//            .setConnection(
//                ConnectionRecordBuilder()
//                    .withId("conn-123")
//                    .build()
//            )
//            .setSenderVerkey("sender-verkey")
//            .setRecipientVerkey("recipient-verkey")
//            .build()
//
//        proofFormatCoordinatorSpy.processPresentationReturnToReturn = ProcessPresentationReturn(isValid: true)
//
//        let result = try await sut.process(messageContext: context)
//
//        XCTAssertEqual(result.id, proofRecord.id)
//        XCTAssertEqual(result.state, ProofState.PresentationReceived)
//        XCTAssertEqual(result.isVerified, true)
//
//        XCTAssertTrue(connectionServiceMock.matchIncomingCalled)
//        XCTAssertEqual(connectionServiceMock.receivedExpectedConnectionId, "conn-123")
//
//        XCTAssertTrue(proofFormatCoordinatorSpy.processPresentationCalled)
//        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 1)
//        XCTAssertEqual(proofRepositorySpy.updatedRecords.first?.state, .PresentationReceived)
//
//        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
//        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.state, .PresentationReceived)
//    }

    func testProcess_WhenProofRecordNotFound_ShouldThrow() async throws{
        let presentationMessage = PresentationMessageV2Builder()
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setPresentationAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        var msg = presentationMessage
        msg.setThread(threadId: "missing-thread", parentThreadId: nil)

        let context = try InboundMessageContextBuilder()
            .setMessage(msg)
            .setPlaintextMessage(msg.toJsonString())
            .setConnection(
                ConnectionRecordBuilder()
                    .withId("conn-123")
                    .build()
            )
            .setSenderVerkey("sender-verkey")
            .setRecipientVerkey("recipient-verkey")
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.process(messageContext: context)
        } assertion: { error in
            //XCTAssertTrue(String(describing: error).contains("Proof record not found"))
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testProcess_WhenLastSentRequestNotFound_ShouldThrow() async throws{
        let proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-id-2")
            .setThreadId("thread-456")
            .setConnectionId("conn-456")
            .setState(.RequestSent)
            .setRole(.verifier)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        proofRepositorySpy.stub([proofRecord])

        let presentationMessage = PresentationMessageV2Builder()
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setPresentationAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        var msg = presentationMessage
        msg.setThread(threadId: proofRecord.threadId, parentThreadId: nil)

        let context = try InboundMessageContextBuilder()
            .setMessage(msg)
            .setPlaintextMessage(msg.toJsonString())
            .setConnection(
                ConnectionRecordBuilder()
                    .withId("conn-456")
                    .build()
            )
            .setSenderVerkey("sender-verkey")
            .setRecipientVerkey("recipient-verkey")
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.process(messageContext: context)
        } assertion: { error in
            //XCTAssertTrue(String(describing: error).contains("Last sent RequestPresentationMessageV2 not found"))
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

//    func testProcess_WhenCoordinatorReturnsInvalidPresentation_ShouldAbandonAndThrowProblemReport() async throws{
//        let proofRecord = ProofExchangeRecordBuilder()
//            .setId("proof-id-3")
//            .setThreadId("thread-789")
//            .setConnectionId("conn-789")
//            .setState(.RequestSent)
//            .setRole(.verifier)
//            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
//            .build()
//
//        proofRepositorySpy.stub([proofRecord])
//
//        let requestMessage = RequestPresentationMessageV2Builder()
//            .setFormats([
//                ProofFormatSpec(
//                    attachmentId: "anoncreds",
//                    format: "anoncreds/proof@v1.0"
//                )
//            ])
//            .setRequestPresentationAttachments([
//                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
//            ])
//            .build()
//
//        didCommMessageRepositoryStub.stubTyped(
//            recordId: proofRecord.id,
//            type: RequestPresentationMessageV2.type,
//            role: .Sender,
//            message: requestMessage
//        )
//
//        let presentationMessage = PresentationMessageV2Builder()
//            .setFormats([
//                ProofFormatSpec(
//                    attachmentId: "anoncreds",
//                    format: "anoncreds/proof@v1.0"
//                )
//            ])
//            .setPresentationAttachments([
//                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
//            ])
//            .build()
//
//        var msg = presentationMessage
//        msg.setThread(threadId: proofRecord.threadId, parentThreadId: nil)
//
//        let context = try InboundMessageContextBuilder()
//            .setMessage(msg)
//            .setPlaintextMessage(msg.toJsonString())
//            .setConnection(
//                ConnectionRecordBuilder()
//                    .withId("conn-789")
//                    .build()
//            )
//            .setSenderVerkey("sender-verkey")
//            .setRecipientVerkey("recipient-verkey")
//            .build()
//
//        proofFormatCoordinatorSpy.processPresentationReturnToReturn = ProcessPresentationReturn(
//            isValid: false,
//            message: "invalid proof"
//        )
//
//        await XCTAssertThrowsErrorAsync {
//            _ = try await self.sut.process(messageContext: context)
//        } assertion: { error in
////            XCTAssertTrue(
////                String(describing: error).contains("invalid proof")
////                || String(describing: error).contains("Presentation invalid")
//                //)
//            XCTAssertTrue(error is CredoError)
//        }
//
//        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 1)
//        XCTAssertEqual(proofRepositorySpy.updatedRecords.first?.state, .Abandoned)
//        XCTAssertEqual(proofRepositorySpy.updatedRecords.first?.isVerified, false)
//        XCTAssertEqual(proofRepositorySpy.updatedRecords.first?.errorMessage, "invalid proof")
//
//        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
//        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.state, .Abandoned)
//    }

    func testProcess_WhenStateIsInvalid_ShouldThrow() async throws{
        let proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-id-4")
            .setThreadId("thread-invalid-state")
            .setConnectionId("conn-invalid")
            .setState(.ProposalReceived)
            .setRole(.verifier)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        proofRepositorySpy.stub([proofRecord])

        let requestMessage = RequestPresentationMessageV2Builder()
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

        didCommMessageRepositoryStub.stubTyped(
            recordId: proofRecord.id,
            type: RequestPresentationMessageV2.type,
            role: .Sender,
            message: requestMessage
        )

        let presentationMessage = PresentationMessageV2Builder()
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setPresentationAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        var msg = presentationMessage
        msg.setThread(threadId: proofRecord.threadId, parentThreadId: nil)

        let context = try InboundMessageContextBuilder()
            .setMessage(msg)
            .setPlaintextMessage(msg.toJsonString())
            .setConnection(
                ConnectionRecordBuilder()
                    .withId("conn-invalid")
                    .build()
            )
            .setSenderVerkey("sender-verkey")
            .setRecipientVerkey("recipient-verkey")
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.process(messageContext: context)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
    }

    func testProcessOffline_WhenValidPresentation_ShouldSaveProofRecord() async throws {
        let requestMessage = RequestPresentationMessageV2Builder()
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
        

        let verifierRecord = VerifierRecordBuilder()
            .setGlobalThreadId("offline-thread-1")
            .setRequestMessage(requestMessage)
            .build()
        
        verifierRepository.verifierRecordToReturn = verifierRecord
        verifierRepository.queryResultsToReturn = []

        let presentationMessage = PresentationMessageV2Builder()
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setPresentationAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        var offlineMsg = presentationMessage
        offlineMsg.setThread(threadId: "offline-thread-1", parentThreadId: nil)

        proofFormatCoordinatorSpy.processPresentationReturnToReturn = ProcessPresentationReturn(isValid: true)

        let result = try await sut.processOffline(message: offlineMsg)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.connectionId, "connectionless-proof-presentation")
        XCTAssertEqual(proofRepositorySpy.savedRecords.count, 1)
    }

    private func XCTAssertThrowsErrorAsync(
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
