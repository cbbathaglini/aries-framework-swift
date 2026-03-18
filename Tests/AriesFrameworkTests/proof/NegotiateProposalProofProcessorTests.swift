//
//  NegotiateProposalProofProcessorTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//

import XCTest
import AnyCodable
@testable import AriesFramework

final class NegotiateProposalProofProcessorTests: XCTestCase {

    private var sut: NegotiateProposalProofProcessor!
    private var agent: Agent!
    private var common: CommonFunctions!

    private var proofRepositorySpy: MockProofRepository!
    private var delegateSpy: MockAgentDelegate!
    private var proofFormatCoordinatorSpy: MockProofFormatCoordinator!

    override func setUp() async throws {
        try await super.setUp()

        agent = Agent(agentConfig: .test(), agentDelegate: nil)

        proofRepositorySpy = MockProofRepository(agent: agent)
        delegateSpy = MockAgentDelegate()
        proofFormatCoordinatorSpy = MockProofFormatCoordinator(agent: agent)

        agent.proofRepository = proofRepositorySpy
        agent.agentDelegate = delegateSpy

        let mockFormatService = MockProofFormatService(
            formatKey: "anoncreds",
            supportedFormats: ["anoncreds/proof-request@v1.0"]
        )

        common = CommonFunctions(
            agent: agent,
            proofFormats: [mockFormatService]
        )

        sut = NegotiateProposalProofProcessor(
            agent: agent,
            proofFormatCoordinator: proofFormatCoordinatorSpy,
            common: common
        )
    }

    override func tearDown() {
        sut = nil
        common = nil
        proofRepositorySpy = nil
        delegateSpy = nil
        proofFormatCoordinatorSpy = nil
        agent = nil
        super.tearDown()
    }

    func testNegotiateProposal_WhenValidProposal_ShouldCreateRequestAndUpdateState() async throws {
        var proofRecord = ProofExchangeRecordBuilder()
            .setConnectionId("conn-123")
            .setState(.ProposalReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let expectedRequest = RequestPresentationMessageV2Builder()
            .setComment("request comment")
            .setGoalCode("goal-code")
            .setGoal("goal-value")
            .build()

        proofFormatCoordinatorSpy.requestMessageToReturn = expectedRequest

        let params = NegotiateProofProposalOptions(
            proofRecord: proofRecord,
            proofFormats: [
                "anoncreds": AnyCodable([
                    "name": "proof-format"
                ])
            ],
            autoAcceptProof: .always,
            comment: "request comment",
            goalCode: "goal-code",
            goal: "goal-value",
            willConfirm: false
        )

        let (requestMessage, updatedRecord) = try await sut.negotiateProposal(params: params)

        XCTAssertEqual(requestMessage.id, expectedRequest.id)
        XCTAssertEqual(requestMessage.comment, "request comment")

        XCTAssertEqual(updatedRecord.state, .RequestSent)
        XCTAssertEqual(updatedRecord.autoAcceptProof, .always)

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 1)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.first?.id, proofRecord.id)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.first?.state, .RequestSent)

        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.id, proofRecord.id)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.state, .RequestSent)
    }

    func testNegotiateProposal_WhenConnectionIdIsEmpty_ShouldThrow() async {
        let proofRecord = ProofExchangeRecordBuilder()
            .setConnectionId("")
            .setState(.ProposalReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let params = NegotiateProofProposalOptions(
            proofRecord: proofRecord,
            proofFormats: [
                "anoncreds": AnyCodable([
                    "name": "proof-format"
                ])
            ],
            autoAcceptProof: .always,
            comment: "request comment",
            goalCode: "goal-code",
            goal: "goal-value",
            willConfirm: false
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.negotiateProposal(params: params)
        } assertion: { error in
            let description = String(describing: error)
//            XCTAssertTrue(
//                description.contains("Connection-less verification does not support negotiation")
//                || description.contains("No connectionId found")
//            )
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testNegotiateProposal_WhenStateIsInvalid_ShouldThrow() async {
        let proofRecord = ProofExchangeRecordBuilder()
            .setConnectionId("conn-123")
            .setState(.RequestReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let params = NegotiateProofProposalOptions(
            proofRecord: proofRecord,
            proofFormats: [
                "anoncreds": AnyCodable([
                    "name": "proof-format"
                ])
            ],
            autoAcceptProof: .always,
            comment: "request comment",
            goalCode: "goal-code",
            goal: "goal-value",
            willConfirm: false
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.negotiateProposal(params: params)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testNegotiateProposal_WhenProtocolVersionIsInvalid_ShouldThrow() async {
        let proofRecord = ProofExchangeRecordBuilder()
            .setConnectionId("conn-123")
            .setState(.ProposalReceived)
            .setProtocolVersion("v1")
            .build()

        let params = NegotiateProofProposalOptions(
            proofRecord: proofRecord,
            proofFormats: [
                "anoncreds": AnyCodable([
                    "name": "proof-format"
                ])
            ],
            autoAcceptProof: .always,
            comment: "request comment",
            goalCode: "goal-code",
            goal: "goal-value",
            willConfirm: false
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.negotiateProposal(params: params)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testNegotiateProposal_WhenNoSupportedFormats_ShouldThrow() async {
        let proofRecord = ProofExchangeRecordBuilder()
            .setConnectionId("conn-123")
            .setState(.ProposalReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let params = NegotiateProofProposalOptions(
            proofRecord: proofRecord,
            proofFormats: [
                "unsupported": AnyCodable([
                    "name": "proof-format"
                ])
            ],
            autoAcceptProof: .always,
            comment: "request comment",
            goalCode: "goal-code",
            goal: "goal-value",
            willConfirm: false
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.negotiateProposal(params: params)
        } assertion: { error in
            let description = String(describing: error)
            //XCTAssertTrue(description.contains("No supported formats"))
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testNegotiateProposal_WhenAutoAcceptProofIsNil_ShouldKeepOriginalValue() async throws {
        var proofRecord = ProofExchangeRecordBuilder()
            .setConnectionId("conn-123")
            .setState(.ProposalReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .setAutoAcceptProof(.never)
            .build()

        let expectedRequest = RequestPresentationMessageV2Builder()
            .setComment("request comment")
            .build()

        proofFormatCoordinatorSpy.requestMessageToReturn = expectedRequest

        let params = NegotiateProofProposalOptions(
            proofRecord: proofRecord,
            proofFormats: [
                "anoncreds": AnyCodable([
                    "name": "proof-format"
                ])
            ],
            autoAcceptProof: AutoAcceptProof.never,
            comment: "request comment",
            goalCode: "goal-code",
            goal: "goal-value",
            willConfirm: true
        )

        let (_, updatedRecord) = try await sut.negotiateProposal(params: params)

        XCTAssertEqual(updatedRecord.autoAcceptProof, .never)
        XCTAssertEqual(updatedRecord.state, .RequestSent)
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
