//
//  CreateProposalProofProcessorTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

import XCTest
import AnyCodable
@testable import AriesFramework

final class CreateProposalProofProcessorTests: XCTestCase {

    private var sut: CreateProposalProofProcessor!

    private var agent: Agent!
    private var proofRepositorySpy: MockProofRepository!
    private var proofFormatCoordinatorSpy: MockProofFormatCoordinator!
    private var delegateSpy: MockAgentDelegate!
    private var common: CommonFunctions!

    override func setUp() async throws {
        try await super.setUp()

        agent = Agent(agentConfig: .test(), agentDelegate: nil)

        proofRepositorySpy = MockProofRepository(agent: agent)
        proofFormatCoordinatorSpy = MockProofFormatCoordinator(agent: agent, formatServices: [])
        delegateSpy = MockAgentDelegate()

        agent.proofRepository = proofRepositorySpy
        agent.agentDelegate = delegateSpy

        let supportedService = MockProofFormatService(
            formatKey: "anoncreds",
            supportedFormats: ["anoncreds/proof-request@v1.0"]
        )

        common = CommonFunctions(
            agent: agent,
            proofFormats: [supportedService]
        )

        sut = CreateProposalProofProcessor(
            agent: agent,
            proofRepository: proofRepositorySpy,
            proofFormatCoordinator: proofFormatCoordinatorSpy,
            common: common
        )
    }

    override func tearDown() {
        sut = nil
        common = nil
        delegateSpy = nil
        proofFormatCoordinatorSpy = nil
        proofRepositorySpy = nil
        agent = nil
        super.tearDown()
    }

    func testCreateProposal_WhenFormatsAreSupported_ShouldCreateProposalAndPersistRecord() async throws {
        let expectedMessage = ProposePresentationMessageV2Builder()
            .setComment("proposal comment")
            .setGoalCode("goal-code")
            .setGoal("goal-text")
            .build()

        proofFormatCoordinatorSpy.proposalMessageToReturn = expectedMessage

        let connection = makeConnectionRecord(id: "conn-123")

        let options = CreateProposalProofOptionsV2(
            connectionRecord: connection,
            proofFormats: [
                "anoncreds": AnyCodable(["format": "anoncreds/proof-request@v1.0"])
            ],
            comment: "proposal comment",
            autoAcceptProof: .always,
            goalCode: "goal-code",
            goal: "goal-text",
            parentThreadId: "parent-thread",
        )

        let (message, record) = try await sut.createProposal(options: options)

        XCTAssertEqual(message.id, expectedMessage.id)
        XCTAssertEqual(message.comment, expectedMessage.comment)
        XCTAssertEqual(message.goalCode, expectedMessage.goalCode)
        XCTAssertEqual(message.goal, expectedMessage.goal)

        XCTAssertTrue(proofFormatCoordinatorSpy.createProposalCalled)
        XCTAssertEqual(proofFormatCoordinatorSpy.receivedCreateProposalParams?.comment, "proposal comment")
        XCTAssertEqual(proofFormatCoordinatorSpy.receivedCreateProposalParams?.goalCode, "goal-code")
        XCTAssertEqual(proofFormatCoordinatorSpy.receivedCreateProposalParams?.goal, "goal-text")

        XCTAssertEqual(record.connectionId, "conn-123")
        XCTAssertEqual(record.parentThreadId, "parent-thread")
        XCTAssertEqual(record.state, .ProposalSent)
        XCTAssertEqual(record.role, .prover)
        XCTAssertEqual(record.protocolVersion, ProofConstants.PROTOCOL_VERSION_V2)
        XCTAssertEqual(record.autoAcceptProof, .always)

        XCTAssertEqual(proofRepositorySpy.savedRecords.count, 1)
        XCTAssertEqual(proofRepositorySpy.savedRecords.first?.id, record.id)

        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.id, record.id)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.state, .ProposalSent)
    }

    func testCreateProposal_WhenNoSupportedFormats_ShouldThrow() async {
        let localCommon = CommonFunctions(agent: agent, proofFormats: [])

        sut = CreateProposalProofProcessor(
            agent: agent,
            proofRepository: proofRepositorySpy,
            proofFormatCoordinator: proofFormatCoordinatorSpy,
            common: localCommon
        )

        let connection = makeConnectionRecord(id: "conn-123")

        let options = CreateProposalProofOptionsV2(
            connectionRecord: connection,
            proofFormats: [:],
            comment: "proposal comment",
            autoAcceptProof: .always,
            goalCode: "goal-code",
            goal: "goal-text",
            parentThreadId: "",
            
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.createProposal(options: options)
        } assertion: { error in
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertFalse(proofFormatCoordinatorSpy.createProposalCalled)
        XCTAssertEqual(proofRepositorySpy.savedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testCreateProposal_WhenCoordinatorThrows_ShouldNotPersistRecord() async {
        proofFormatCoordinatorSpy.errorToThrow = CredoError("coordinator failed")

        let connection = makeConnectionRecord(id: "conn-123")

        let options = CreateProposalProofOptionsV2(
            connectionRecord: connection,
            proofFormats: [
                "anoncreds": AnyCodable(["format": "anoncreds/proof-request@v1.0"])
            ],
            comment: "proposal comment",
            autoAcceptProof: .always,
            goalCode: "goal-code",
            goal: "goal-text",
            parentThreadId: ""
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.createProposal(options: options)
        } assertion: { error in
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertTrue(proofFormatCoordinatorSpy.createProposalCalled)
        XCTAssertEqual(proofRepositorySpy.savedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testCreateProposal_WhenRepositorySaveThrows_ShouldNotNotifyDelegate() async {
        proofRepositorySpy.errorToThrowOnSave = CredoError("save failed")

        let expectedMessage = ProposePresentationMessageV2Builder()
            .setComment("proposal comment")
            .build()

        proofFormatCoordinatorSpy.proposalMessageToReturn = expectedMessage

        let connection = makeConnectionRecord(id: "conn-123")

        let options = CreateProposalProofOptionsV2(
            connectionRecord: connection,
            proofFormats: [
                "anoncreds": AnyCodable(["format": "anoncreds/proof-request@v1.0"])
            ],
            comment: "proposal comment",
            autoAcceptProof: .always,
            goalCode: "",
            goal: "",
            parentThreadId: ""
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.createProposal(options: options)
        } assertion: { error in
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertTrue(proofFormatCoordinatorSpy.createProposalCalled)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }
}

// MARK: - Helpers
private extension CreateProposalProofProcessorTests {

    func makeConnectionRecord(id: String) -> ConnectionRecord {
        ConnectionRecordBuilder()
            .withId(id)
            .build()
    }

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
