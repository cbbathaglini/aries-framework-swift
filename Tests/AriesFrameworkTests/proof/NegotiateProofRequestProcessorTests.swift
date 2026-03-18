//
//  NegotiateProofRequestProcessorTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//

import XCTest
import AnyCodable
@testable import AriesFramework

final class NegotiateProofRequestProcessorTests: XCTestCase {

    private var sut: NegotiateProofRequestProcessor!
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

        sut = NegotiateProofRequestProcessor(
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

    func testNegotiateRequest_WhenValidRequest_ShouldCreateProposalAndUpdateState() async throws {
        var proofRecord = ProofExchangeRecordBuilder()
            .setConnectionId("conn-123")
            .setState(.RequestReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let expectedProposal = ProposePresentationMessageV2Builder()
            .setComment("proposal comment")
            .setGoalCode("goal-code")
            .setGoal("goal-value")
            .build()

        proofFormatCoordinatorSpy.proposalMessageToReturn = expectedProposal

        let params = NegotiateProofRequestParams(
            proofRecord: proofRecord,
            proofFormats: [
                "anoncreds": AnyCodable([
                    "name": "proof-format"
                ])
            ],
            comment: "proposal comment",
            goalCode: "goal-code",
            goal: "goal-value",
            autoAcceptProof: .always
        )

        let (proposalMessage, updatedRecord) = try await sut.negotiateRequest(params: params)

        XCTAssertEqual(proposalMessage.id, expectedProposal.id)
        XCTAssertEqual(proposalMessage.comment, "proposal comment")

        XCTAssertEqual(updatedRecord.state, .ProposalSent)
        XCTAssertEqual(updatedRecord.autoAcceptProof, .always)

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 1)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.first?.id, proofRecord.id)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.first?.state, .ProposalSent)

        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.id, proofRecord.id)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.state, .ProposalSent)
    }

    func testNegotiateRequest_WhenConnectionIdIsEmpty_ShouldThrow() async {
        let proofRecord = ProofExchangeRecordBuilder()
            .setConnectionId("")
            .setState(.RequestReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let params = NegotiateProofRequestParams(
            proofRecord: proofRecord,
            proofFormats: [
                "anoncreds": AnyCodable([
                    "name": "proof-format"
                ])
            ],
            comment: "proposal comment",
            goalCode: "goal-code",
            goal: "goal-value",
            autoAcceptProof: .always
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.negotiateRequest(params: params)
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

    func testNegotiateRequest_WhenStateIsInvalid_ShouldThrow() async {
        let proofRecord = ProofExchangeRecordBuilder()
            .setConnectionId("conn-123")
            .setState(.ProposalSent)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let params = NegotiateProofRequestParams(
            proofRecord: proofRecord,
            proofFormats: [
                "anoncreds": AnyCodable([
                    "name": "proof-format"
                ])
            ],
            comment: "proposal comment",
            goalCode: "goal-code",
            goal: "goal-value",
            autoAcceptProof: .always
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.negotiateRequest(params: params)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testNegotiateRequest_WhenProtocolVersionIsInvalid_ShouldThrow() async {
        let proofRecord = ProofExchangeRecordBuilder()
            .setConnectionId("conn-123")
            .setState(.RequestReceived)
            .setProtocolVersion("v1")
            .build()

        let params = NegotiateProofRequestParams(
            proofRecord: proofRecord,
            proofFormats: [
                "anoncreds": AnyCodable([
                    "name": "proof-format"
                ])
            ],
            comment: "proposal comment",
            goalCode: "goal-code",
            goal: "goal-value",
            autoAcceptProof: .always
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.negotiateRequest(params: params)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testNegotiateRequest_WhenNoSupportedFormats_ShouldThrow() async {
        let proofRecord = ProofExchangeRecordBuilder()
            .setConnectionId("conn-123")
            .setState(.RequestReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let params = NegotiateProofRequestParams(
            proofRecord: proofRecord,
            proofFormats: [
                "unsupported": AnyCodable([
                    "name": "proof-format"
                ])
            ],
            comment: "proposal comment",
            goalCode: "goal-code",
            goal: "goal-value",
            autoAcceptProof: .always
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.negotiateRequest(params: params)
        } assertion: { error in
            let description = String(describing: error)
            //XCTAssertTrue(description.contains("No supported formats"))
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
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
