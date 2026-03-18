//
//  AcceptProofRequestProcessorTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

import XCTest
@testable import AriesFramework

final class AcceptProofRequestProcessorTests: XCTestCase {

    private var sut: AcceptProofRequestProcessor!
    private var agent: Agent!
    private var common: CommonFunctions!

    private var didCommMessageRepositoryStub: MockDidCommMessageRepository!
    private var proofRepositorySpy: MockProofRepository!
    private var delegateSpy: MockAgentDelegate!
    private var proofFormatCoordinatorSpy: MockProofFormatCoordinator!
    private var historyServiceStub: MockHistoryService!

    override func setUp() async throws {
        try await super.setUp()

        agent = Agent(agentConfig: .test(), agentDelegate: nil)

        didCommMessageRepositoryStub = MockDidCommMessageRepository(agent: agent)
        proofRepositorySpy = MockProofRepository(agent: agent)
        delegateSpy = MockAgentDelegate()
        proofFormatCoordinatorSpy = MockProofFormatCoordinator(agent: agent)
        historyServiceStub = MockHistoryService()

        agent.didCommMessageRepository = didCommMessageRepositoryStub
        agent.proofRepository = proofRepositorySpy
        agent.agentDelegate = delegateSpy

        common = CommonFunctions(agent: agent, proofFormats: [
            MockProofFormatService(
                formatKey: "anoncreds",
                supportedFormats: ["anoncreds/proof-request@v1.0"]
            )
        ])

        sut = AcceptProofRequestProcessor(
            agent: agent,
            proofFormatCoordinator: proofFormatCoordinatorSpy,
            proofRepository: proofRepositorySpy,
            historyService: historyServiceStub,
            common: common
        )
    }

    override func tearDown() {
        sut = nil
        common = nil
        didCommMessageRepositoryStub = nil
        proofRepositorySpy = nil
        delegateSpy = nil
        proofFormatCoordinatorSpy = nil
        historyServiceStub = nil
        agent = nil
        super.tearDown()
    }

    func testAcceptRequest_WhenProofRecordIsValidAndFormatsProvided_ShouldReturnPresentationAndUpdateState() async throws {
        var proofRecord = ProofExchangeRecordBuilder()
            .setState(.RequestReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let expectedPresentation = PresentationMessageV2Builder()
            .setComment("presentation")
            .setLastPresentation(true)
            .build()

        proofFormatCoordinatorSpy.presentationMessageToReturn = expectedPresentation
        
        let formats = [
            ProofFormatSpec(attachmentId: "anoncreds", format: "anoncreds/proof-request@v1.0")
        ]

        let options = AcceptProofRequestOptions(
            proofRecord: proofRecord,
            proofFormats: formats,
            comment: "test-comment",
            goalCode: "goal-code",
            goal: "goal",
            autoAcceptProof: .always,
            requestedCredentials: [:],
            chosenCredentialId: "cred-123"
        )

        let (presentation, updatedRecord) = try await sut.acceptRequest(params: options)

        XCTAssertEqual(proofFormatCoordinatorSpy.acceptRequestCallCount, 1)
        XCTAssertEqual(presentation.id, expectedPresentation.id)

        XCTAssertEqual(updatedRecord.state, .PresentationSent)
        XCTAssertEqual(updatedRecord.chosenCredentialId, "cred-123")
        XCTAssertEqual(updatedRecord.autoAcceptProof, .always)
        XCTAssertEqual(updatedRecord.presentationMessage?.id, expectedPresentation.id)

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 1)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.first?.state, .PresentationSent)

        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.state, .PresentationSent)

        XCTAssertEqual(proofFormatCoordinatorSpy.receivedAcceptRequestParams?.comment, "test-comment")
        XCTAssertEqual(proofFormatCoordinatorSpy.receivedAcceptRequestParams?.goalCode, "goal-code")
        XCTAssertEqual(proofFormatCoordinatorSpy.receivedAcceptRequestParams?.goal, "goal")
        XCTAssertEqual(proofFormatCoordinatorSpy.receivedAcceptRequestParams?.chosenCredentialId, "cred-123")
    }

    func testAcceptRequest_WhenFormatsNotProvided_ShouldResolveFromRequestMessage() async throws {
        let proofRecord = ProofExchangeRecordBuilder()
            .setState(.RequestReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let requestMessage = RequestPresentationMessageV2Builder()
            .setFormats([
                ProofFormatSpec(attachmentId: "anoncreds", format: "anoncreds/proof-request@v1.0")
            ])
            .build()

        didCommMessageRepositoryStub.stubTyped(
            recordId: proofRecord.id,
            type: RequestPresentationMessageV2.type,
            role: .Receiver,
            message: requestMessage
        )

        let expectedPresentation = PresentationMessageV2Builder().build()
        proofFormatCoordinatorSpy.presentationMessageToReturn = expectedPresentation

        let options = AcceptProofRequestOptions(
            proofRecord: proofRecord,
            proofFormats: [],
            comment: nil,
            goalCode: nil,
            goal: nil,
            autoAcceptProof: nil,
            requestedCredentials: [:],
            chosenCredentialId: nil
        )

        let (presentation, updatedRecord) = try await sut.acceptRequest(params: options)

        XCTAssertEqual(proofFormatCoordinatorSpy.acceptRequestCallCount, 1)
        XCTAssertEqual(presentation.id, expectedPresentation.id)
        XCTAssertEqual(updatedRecord.state, ProofState.PresentationSent)
    }

    func testAcceptRequest_WhenNoSupportedFormatsProvidedAndNoRequestMessageFormats_ShouldThrow() async {
        let proofRecord = ProofExchangeRecordBuilder()
            .setState(.RequestReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let requestMessage = RequestPresentationMessageV2Builder()
            .setFormats([])
            .build()

        didCommMessageRepositoryStub.stubTyped(
            recordId: proofRecord.id,
            type: RequestPresentationMessageV2.type,
            role: .Receiver,
            message: requestMessage
        )

        let options = AcceptProofRequestOptions(
            proofRecord: proofRecord,
            proofFormats: [],
            comment: nil,
            goalCode: nil,
            goal: nil,
            autoAcceptProof: nil,
            requestedCredentials: [:],
            chosenCredentialId: nil
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.acceptRequest(params: options)
        } assertion: { error in
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofFormatCoordinatorSpy.acceptRequestCallCount, 0)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testAcceptRequest_WhenProofStateIsInvalid_ShouldThrow() async {
        let proofRecord = ProofExchangeRecordBuilder()
            .setState(.PresentationReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let options = AcceptProofRequestOptions(
            proofRecord: proofRecord,
            proofFormats: [],
            comment: nil,
            goalCode: nil,
            goal: nil,
            autoAcceptProof: nil,
            requestedCredentials: [:],
            chosenCredentialId: nil
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.acceptRequest(params: options)
        }

        XCTAssertEqual(proofFormatCoordinatorSpy.acceptRequestCallCount, 0)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
    }

    func testAcceptRequest_WhenProtocolVersionIsInvalid_ShouldThrow() async {
        let proofRecord = ProofExchangeRecordBuilder()
            .setState(.RequestReceived)
            .setProtocolVersion("v1")
            .build()

        let options = AcceptProofRequestOptions(
            proofRecord: proofRecord,
            proofFormats: [],
            comment: nil,
            goalCode: nil,
            goal: nil,
            autoAcceptProof: nil,
            requestedCredentials: [:],
            chosenCredentialId: nil
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.acceptRequest(params: options)
        }

        XCTAssertEqual(proofFormatCoordinatorSpy.acceptRequestCallCount, 0)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
    }

    func testAcceptRequest_WhenCoordinatorThrows_ShouldPropagateErrorAndNotUpdateState() async {
        let proofRecord = ProofExchangeRecordBuilder()
            .setState(.RequestReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        proofFormatCoordinatorSpy.errorToThrow = CredoError("coordinator failed")

        let formats = [
            ProofFormatSpec(attachmentId: "anoncreds", format: "anoncreds/proof-request@v1.0")
        ]

        let options = AcceptProofRequestOptions(
            proofRecord: proofRecord,
            proofFormats: formats,
            comment: nil,
            goalCode: nil,
            goal: nil,
            autoAcceptProof: nil,
            requestedCredentials: [:],
            chosenCredentialId: nil
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.acceptRequest(params: options)
        } assertion: { error in
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofFormatCoordinatorSpy.acceptRequestCallCount, 1)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
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
