//
//  AcceptProposalProofProcessorTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

import XCTest
import AnyCodable
@testable import AriesFramework

final class AcceptProposalProofProcessorTests: XCTestCase {

    private var sut: AcceptProposalProofProcessor!

    private var agent: Agent!
    private var didCommMessageRepositoryStub: MockDidCommMessageRepository!
    private var proofFormatCoordinatorSpy: MockProofFormatCoordinator!
    private var proofRepositorySpy: MockProofRepository!
    private var delegateSpy: MockAgentDelegate!
    private var common: CommonFunctions!

    override func setUp() async throws {
        try await super.setUp()

        agent = Agent(agentConfig: .test(), agentDelegate: nil)

        didCommMessageRepositoryStub = MockDidCommMessageRepository(agent: agent)
        proofRepositorySpy = MockProofRepository(agent: agent)
        delegateSpy = MockAgentDelegate()

        agent.didCommMessageRepository = didCommMessageRepositoryStub
        agent.proofRepository = proofRepositorySpy
        agent.agentDelegate = delegateSpy

        common = CommonFunctions(
            agent: agent,
            proofFormats: [
                MockProofFormatService(
                    formatKey: "anoncreds",
                    supportedFormats: ["anoncreds/proof-request@v1.0"]
                )
            ]
        )

        proofFormatCoordinatorSpy = MockProofFormatCoordinator(agent: agent)

        sut = AcceptProposalProofProcessor(
            agent: agent,
            didCommMessageRepository: didCommMessageRepositoryStub,
            proofFormatCoordinator: proofFormatCoordinatorSpy,
            common: common
        )
    }

    override func tearDown() {
        sut = nil
        common = nil
        delegateSpy = nil
        proofRepositorySpy = nil
        proofFormatCoordinatorSpy = nil
        didCommMessageRepositoryStub = nil
        agent = nil
        super.tearDown()
    }

    func testAcceptProposal_WhenFormatsComeFromParams_ShouldReturnRequestAndUpdateState() async throws {
        var proofRecord = ProofExchangeRecordBuilder()
            .setState(.ProposalReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let expectedMessage = RequestPresentationMessageV2Builder()
            .setComment("request-comment")
            .build()

        proofFormatCoordinatorSpy.requestMessageToReturn = expectedMessage

        let params = AcceptProofProposalServiceParams(
            proofRecord: proofRecord,
            proofFormats: [
                "anoncreds": AnyCodable(["test": "value"])
            ],
            comment: "my-comment",
            goalCode: "goal-code",
            goal: "goal",
            autoAcceptProof: .always,
            willConfirm: true
        )

        let (message, updatedRecord) = try await sut.acceptProposal(params: params)

        XCTAssertEqual(message.id, expectedMessage.id)
        XCTAssertEqual(updatedRecord.state, .RequestSent)
        XCTAssertEqual(updatedRecord.autoAcceptProof, .always)

        XCTAssertEqual(proofFormatCoordinatorSpy.acceptProposalCallCount, 1)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 1)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)

        let received = proofFormatCoordinatorSpy.receivedAcceptProposalParams
        XCTAssertEqual(received?.comment, "my-comment")
        XCTAssertEqual(received?.goalCode, "goal-code")
        XCTAssertEqual(received?.goal, "goal")
        XCTAssertEqual(received?.willConfirm, true)
    }

    func testAcceptProposal_WhenFormatsAreEmpty_ShouldResolveFromStoredProposalMessage() async throws {
        let proofRecord = ProofExchangeRecordBuilder()
            .setState(.ProposalReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let proposalMessage = ProposePresentationMessageV2Builder()
            .setFormats([
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof-request@v1.0"
                )
            ])
            .build()

        didCommMessageRepositoryStub.stubTyped(
            recordId: proofRecord.id,
            type: ProposePresentationMessageV2.type,
            role: .Receiver,
            message: proposalMessage
        )

        try didCommMessageRepositoryStub.stubString(
            recordId: proofRecord.id,
            type: ProposePresentationMessageV2.type,
            role: .Receiver,
            json: proposalMessage.toJsonString()
        )

        let expectedMessage = RequestPresentationMessageV2Builder().build()
        proofFormatCoordinatorSpy.requestMessageToReturn = expectedMessage

        let params = AcceptProofProposalServiceParams(
            proofRecord: proofRecord,
            proofFormats: [:],
            comment: "comment",
            goalCode: nil,
            goal: nil,
            willConfirm: false
        )

        let (message, updatedRecord) = try await sut.acceptProposal(params: params)

        XCTAssertEqual(message.id, expectedMessage.id)
        XCTAssertEqual(updatedRecord.state, .RequestSent)
        XCTAssertEqual(proofFormatCoordinatorSpy.acceptProposalCallCount, 1)
    }

    func testAcceptProposal_WhenFormatsEmptyAndMessageNotFound_ShouldThrow() async {
        let proofRecord = ProofExchangeRecordBuilder()
            .setState(.ProposalReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let params = AcceptProofProposalServiceParams(
            proofRecord: proofRecord,
            proofFormats: [:],
            comment: nil,
            goalCode: nil,
            goal: nil,
            willConfirm: false
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.acceptProposal(params: params)
        } assertion: { error in
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofFormatCoordinatorSpy.acceptProposalCallCount, 0)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testAcceptProposal_WhenFormatsStillEmptyAfterResolving_ShouldThrow() async throws {
        let proofRecord = ProofExchangeRecordBuilder()
            .setState(.ProposalReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let proposalMessage = ProposePresentationMessageV2Builder()
            .setFormats([])
            .build()

        didCommMessageRepositoryStub.stubTyped(
            recordId: proofRecord.id,
            type: ProposePresentationMessageV2.type,
            role: .Receiver,
            message: proposalMessage
        )

        try didCommMessageRepositoryStub.stubString(
            recordId: proofRecord.id,
            type: ProposePresentationMessageV2.type,
            role: .Receiver,
            json: proposalMessage.toJsonString()
        )

        let params = AcceptProofProposalServiceParams(
            proofRecord: proofRecord,
            proofFormats: [:],
            comment: nil,
            goalCode: nil,
            goal: nil,
            willConfirm: false
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.acceptProposal(params: params)
        } assertion: { error in
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofFormatCoordinatorSpy.acceptProposalCallCount, 0)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testAcceptProposal_WhenProofStateIsInvalid_ShouldThrow() async {
        let proofRecord = ProofExchangeRecordBuilder()
            .setState(.RequestReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let params = AcceptProofProposalServiceParams(
            proofRecord: proofRecord,
            proofFormats: [:],
            comment: nil,
            goalCode: nil,
            goal: nil,
            willConfirm: false
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.acceptProposal(params: params)
        }

        XCTAssertEqual(proofFormatCoordinatorSpy.acceptProposalCallCount, 0)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
    }

    func testAcceptProposal_WhenProtocolVersionIsInvalid_ShouldThrow() async {
        let proofRecord = ProofExchangeRecordBuilder()
            .setState(.ProposalReceived)
            .setProtocolVersion("v1")
            .build()

        let params = AcceptProofProposalServiceParams(
            proofRecord: proofRecord,
            proofFormats: [:],
            comment: nil,
            goalCode: nil,
            goal: nil,
            willConfirm: false
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.acceptProposal(params: params)
        }

        XCTAssertEqual(proofFormatCoordinatorSpy.acceptProposalCallCount, 0)
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
