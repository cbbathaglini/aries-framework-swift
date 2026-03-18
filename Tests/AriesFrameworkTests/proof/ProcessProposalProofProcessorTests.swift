//
//  ProcessProposalProofProcessorTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//

import XCTest
@testable import AriesFramework

final class ProcessProposalProofProcessorTests: XCTestCase {

    private var sut: ProcessProposalProofProcessor!

    private var agent: Agent!
    private var proofRepositorySpy: MockProofRepository!
    private var didCommMessageRepositoryStub: MockDidCommMessageRepository!
    private var proofFormatCoordinatorSpy: MockProofFormatCoordinator!
    private var delegateSpy: MockAgentDelegate!
    private var common: CommonFunctions!

    override func setUp() async throws {
        try await super.setUp()

        agent = Agent(agentConfig: .test(), agentDelegate: nil)

        proofRepositorySpy = MockProofRepository(agent: agent)
        didCommMessageRepositoryStub = MockDidCommMessageRepository(agent: agent)
        proofFormatCoordinatorSpy = MockProofFormatCoordinator(agent: agent)
        delegateSpy = MockAgentDelegate()

        agent.proofRepository = proofRepositorySpy
        agent.didCommMessageRepository = didCommMessageRepositoryStub
        agent.agentDelegate = delegateSpy

        let mockFormatService = MockProofFormatService(
            formatKey: "anoncreds",
            supportedFormats: ["anoncreds/proof@v1.0"]
        )

        common = CommonFunctions(
            agent: agent,
            proofFormats: [mockFormatService]
        )

        sut = ProcessProposalProofProcessor(
            agent: agent,
            proofRepository: proofRepositorySpy,
            didCommMessageRepository: didCommMessageRepositoryStub,
            proofFormatCoordinator: proofFormatCoordinatorSpy,
            common: common
        )
    }

    override func tearDown() {
        sut = nil
        common = nil
        delegateSpy = nil
        proofFormatCoordinatorSpy = nil
        didCommMessageRepositoryStub = nil
        proofRepositorySpy = nil
        agent = nil
        super.tearDown()
    }

    func testProcess_WhenNoExistingRecord_ShouldCreateNewRecord() async throws {
        let proposalMessage = ProposePresentationMessageV2Builder()
            .setComment("proposal")
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setProposalAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        var encodedProposal = proposalMessage
        encodedProposal.setThread(threadId: "thread-123", parentThreadId: "parent-123")

        let context = try InboundMessageContextBuilder()
            .setMessage(encodedProposal)
            .setPlaintextMessage(encodedProposal.toJsonString())
            .setConnection(
                ConnectionRecordBuilder()
                    .withId("conn-123")
                    .withState(ConnectionState.Complete)
                    .build()
            )
            .setSenderVerkey("sender-key")
            .setRecipientVerkey("recipient-key")
            .build()

        let result = try await sut.process(messageContext: context)

        XCTAssertEqual(result.connectionId, "conn-123")
        XCTAssertEqual(result.threadId, "thread-123")
        XCTAssertEqual(result.parentThreadId, "parent-123")
        XCTAssertEqual(result.state, .ProposalReceived)
        XCTAssertEqual(result.role, .verifier)
        XCTAssertEqual(result.protocolVersion, ProofConstants.PROTOCOL_VERSION_V2)

        XCTAssertTrue(proofFormatCoordinatorSpy.processProposalCalled)
        XCTAssertEqual(proofRepositorySpy.savedRecords.count, 1)
        XCTAssertEqual(proofRepositorySpy.savedRecords.first?.threadId, "thread-123")

        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.state, .ProposalReceived)
    }

    func testProcess_WhenExistingRecord_ShouldUpdateExistingRecord() async throws {
        let existingRecord = ProofExchangeRecordBuilder()
            .setId("proof-id-1")
            .setThreadId("thread-123")
            .setConnectionId("conn-123")
            .setState(.RequestSent)
            .setRole(.verifier)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        proofRepositorySpy.stub([existingRecord])

        let previousProposal = ProposePresentationMessageV2Builder()
            .setComment("previous-proposal")
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setProposalAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        let previousRequest = RequestPresentationMessageV2Builder()
            .setComment("previous-request")
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
            recordId: existingRecord.id,
            type: ProposePresentationMessageV2.type,
            role: .Receiver,
            message: previousProposal
        )

        didCommMessageRepositoryStub.stubTyped(
            recordId: existingRecord.id,
            type: RequestPresentationMessageV2.type,
            role: .Sender,
            message: previousRequest
        )

        let incomingProposal = ProposePresentationMessageV2Builder()
            .setComment("incoming-proposal")
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setProposalAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        var encodedProposal = incomingProposal
        encodedProposal.setThread(threadId: "thread-123", parentThreadId: nil)

        let context = try InboundMessageContextBuilder()
            .setMessage(encodedProposal)
            .setPlaintextMessage(encodedProposal.toJsonString())
            .setConnection(
                ConnectionRecordBuilder()
                    .withId("conn-123")
                    .withState(ConnectionState.Complete)
                    .build()
            )
            .setSenderVerkey("sender-key")
            .setRecipientVerkey("recipient-key")
            .build()

        let result = try await sut.process(messageContext: context)

        XCTAssertEqual(result.id, "proof-id-1")
        XCTAssertEqual(result.state, .ProposalReceived)

        XCTAssertTrue(proofFormatCoordinatorSpy.processProposalCalled)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 1)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.first?.id, "proof-id-1")
        XCTAssertEqual(proofRepositorySpy.updatedRecords.first?.state, .ProposalReceived)

        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.state, .ProposalReceived)
    }

    func testProcess_WhenProposalCannotBeDecoded_ShouldThrow() async {
        let context = try! InboundMessageContextBuilder()
            .setMessage(ProposePresentationMessageV2Builder().build())
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
            _ = try await self.sut.process(messageContext: context)
        }

        XCTAssertEqual(proofRepositorySpy.savedRecords.count, 0)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
    }

    func testProcess_WhenNoSupportedFormats_ShouldThrow() async {
        let proposalMessage = ProposePresentationMessageV2Builder()
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "unsupported",
                    format: "unsupported/format@v1.0"
                )
            ])
            .setProposalAttachments([
                Attachment.fromData(Data("{}".utf8), id: "unsupported")
            ])
            .build()

        var encodedProposal = proposalMessage
        encodedProposal.setThread(threadId: "thread-123", parentThreadId: nil)

        let context = try! InboundMessageContextBuilder()
            .setMessage(encodedProposal)
            .setPlaintextMessage(encodedProposal.toJsonString())
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
            _ = try await self.sut.process(messageContext: context)
        } assertion: { error in
//            XCTAssertTrue(
//                String(describing: error).contains("No supported formats found") ||
//                error.localizedDescription.contains("No supported formats found")
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
            .setState(.ProposalReceived)
            .setRole(.verifier)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        proofRepositorySpy.stub([existingRecord])

        let previousProposal = ProposePresentationMessageV2Builder()
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setProposalAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        let previousRequest = RequestPresentationMessageV2Builder()
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
            recordId: existingRecord.id,
            type: ProposePresentationMessageV2.type,
            role: .Receiver,
            message: previousProposal
        )

        didCommMessageRepositoryStub.stubTyped(
            recordId: existingRecord.id,
            type: RequestPresentationMessageV2.type,
            role: .Sender,
            message: previousRequest
        )

        let incomingProposal = ProposePresentationMessageV2Builder()
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setProposalAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        var encodedProposal = incomingProposal
        encodedProposal.setThread(threadId: "thread-123", parentThreadId: nil)

        let context = try! InboundMessageContextBuilder()
            .setMessage(encodedProposal)
            .setPlaintextMessage(encodedProposal.toJsonString())
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
            _ = try await self.sut.process(messageContext: context)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
    }

    func testProcess_WhenExistingRecordMissingLastReceivedProposal_ShouldThrow() async {
        let existingRecord = ProofExchangeRecordBuilder()
            .setId("proof-id-1")
            .setThreadId("thread-123")
            .setConnectionId("conn-123")
            .setState(.RequestSent)
            .setRole(.verifier)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        proofRepositorySpy.stub([existingRecord])

        let previousRequest = RequestPresentationMessageV2Builder()
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
            recordId: existingRecord.id,
            type: RequestPresentationMessageV2.type,
            role: .Sender,
            message: previousRequest
        )

        let incomingProposal = ProposePresentationMessageV2Builder()
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setProposalAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        var encodedProposal = incomingProposal
        encodedProposal.setThread(threadId: "thread-123", parentThreadId: nil)

        let context = try! InboundMessageContextBuilder()
            .setMessage(encodedProposal)
            .setPlaintextMessage(encodedProposal.toJsonString())
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
            _ = try await self.sut.process(messageContext: context)
        } assertion: { error in
//            XCTAssertTrue(
//                String(describing: error).contains("Last received proposal message not found") ||
//                error.localizedDescription.contains("Last received proposal message not found")
//            )
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
    }

    func testProcess_WhenExistingRecordMissingLastSentRequest_ShouldThrow() async {
        let existingRecord = ProofExchangeRecordBuilder()
            .setId("proof-id-1")
            .setThreadId("thread-123")
            .setConnectionId("conn-123")
            .setState(.RequestSent)
            .setRole(.verifier)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        proofRepositorySpy.stub([existingRecord])

        let previousProposal = ProposePresentationMessageV2Builder()
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setProposalAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        didCommMessageRepositoryStub.stubTyped(
            recordId: existingRecord.id,
            type: ProposePresentationMessageV2.type,
            role: .Receiver,
            message: previousProposal
        )

        let incomingProposal = ProposePresentationMessageV2Builder()
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof@v1.0"
                )
            ])
            .setProposalAttachments([
                Attachment.fromData(Data("{}".utf8), id: "anoncreds")
            ])
            .build()

        var encodedProposal = incomingProposal
        encodedProposal.setThread(threadId: "thread-123", parentThreadId: nil)

        let context = try! InboundMessageContextBuilder()
            .setMessage(encodedProposal)
            .setPlaintextMessage(encodedProposal.toJsonString())
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
            _ = try await self.sut.process(messageContext: context)
        } assertion: { error in
//            XCTAssertTrue(
//                String(describing: error).contains("Last sent request message not found") ||
//                error.localizedDescription.contains("Last sent request message not found")
//            )
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
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
