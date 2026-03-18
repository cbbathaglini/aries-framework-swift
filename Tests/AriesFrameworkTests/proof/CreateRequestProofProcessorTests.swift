//
//  CreateRequestProofProcessorTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//


import XCTest
@testable import AriesFramework
import AnyCodable

final class CreateRequestProofProcessorTests: XCTestCase {

    private var sut: CreateRequestProofProcessor!

    private var agent: Agent!
    private var common: CommonFunctions!

    private var proofFormatCoordinatorSpy: MockProofFormatCoordinator!
    private var proofRepositorySpy: MockProofRepository!
    private var delegateSpy: MockAgentDelegate!

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

        sut = CreateRequestProofProcessor(
            agent: agent,
            proofFormatCoordinator: proofFormatCoordinatorSpy,
            common: common
        )
    }

    override func tearDown() {
        sut = nil
        common = nil
        proofFormatCoordinatorSpy = nil
        proofRepositorySpy = nil
        delegateSpy = nil
        agent = nil
        super.tearDown()
    }

    func testCreateRequest_WhenInputIsValid_ShouldCreateRequestAndPersistProofRecord() async throws {
        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .build()

        let expectedMessage = RequestPresentationMessageV2Builder()
            .setComment("request-comment")
            .build()

        proofFormatCoordinatorSpy.requestMessageToReturn = expectedMessage

        let proofRequest = AnonCredsProofRequest(
            name: "Proof Request",
            version: "1.0",
            nonce: "1234567890",
            requestedAttributes: [:],
            requestedPredicates: [:]
        )
        
        let params = CreateProofRequestOptions(
            proofRequest: proofRequest,
            formats: [
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof-request@v1.0"
                )
            ],
            proofFormats: [
                "anoncreds": AnyCodable([
                    "name": "proof-format"
                ])
            ],
            connectionRecord: connection,
            comment: "request-comment",
            goalCode: "goal-code",
            goal: "goal-value",
            autoAcceptProof: .always,
            willConfirm: true
        )

        let (requestMessage, proofRecord) = try await sut.createRequest(params: params)

        XCTAssertEqual(requestMessage.comment, "request-comment")
        XCTAssertEqual(requestMessage.id, expectedMessage.id)

        XCTAssertEqual(proofRecord.connectionId, "conn-123")
        XCTAssertEqual(proofRecord.state, ProofState.RequestSent)
        XCTAssertEqual(proofRecord.role, ProofRole.verifier)
        XCTAssertEqual(proofRecord.protocolVersion, ProofConstants.PROTOCOL_VERSION_V2)
        XCTAssertEqual(proofRecord.autoAcceptProof, AutoAcceptProof.always)

        XCTAssertEqual(proofRepositorySpy.savedRecords.count, 1)
        XCTAssertEqual(proofRepositorySpy.savedRecords.first?.id, proofRecord.id)

        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.id, proofRecord.id)

        XCTAssertNotNil(proofFormatCoordinatorSpy.receivedCreateRequestParams)
        XCTAssertEqual(proofFormatCoordinatorSpy.receivedCreateRequestParams?.comment, "request-comment")
        XCTAssertEqual(proofFormatCoordinatorSpy.receivedCreateRequestParams?.goalCode, "goal-code")
        XCTAssertEqual(proofFormatCoordinatorSpy.receivedCreateRequestParams?.goal, "goal-value")
        XCTAssertEqual(proofFormatCoordinatorSpy.receivedCreateRequestParams?.willConfirm, true)
        XCTAssertEqual(proofFormatCoordinatorSpy.receivedCreateRequestParams?.attachmentId, "anoncreds")
    }

    func testCreateRequest_WhenFormatsAreEmpty_ShouldThrow() async {
        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .build()

        let proofRequest = AnonCredsProofRequest(
            name: "Proof Request",
            version: "1.0",
            nonce: "1234567890",
            requestedAttributes: [:],
            requestedPredicates: [:]
        )
        
        let params = CreateProofRequestOptions(
            proofRequest: proofRequest,
            formats: [],
            proofFormats: [:],
            connectionRecord: connection,
            comment: "request-comment",
            goalCode: "goal-code",
            goal: "goal-value",
            autoAcceptProof: .always,
            willConfirm: true
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.createRequest(params: params)
        } assertion: { error in
//            XCTAssertTrue(
//                String(describing: error).contains("Cannot create proof request: no formats provided.")
//            )
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofRepositorySpy.savedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testCreateRequest_WhenNoSupportedFormatService_ShouldThrow() async {
        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .build()

        common = CommonFunctions(agent: agent, proofFormats: [])
        sut = CreateRequestProofProcessor(
            agent: agent,
            proofFormatCoordinator: proofFormatCoordinatorSpy,
            common: common
        )
        
        let proofRequest = AnonCredsProofRequest(
            name: "Proof Request",
            version: "1.0",
            nonce: "1234567890",
            requestedAttributes: [:],
            requestedPredicates: [:]
        )
        
        let params = CreateProofRequestOptions(
            proofRequest: proofRequest,
            formats: [
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof-request@v1.0"
                )
            ],
            proofFormats: [
                "unknown": AnyCodable([
                    "foo": "bar"
                ])
            ],
            connectionRecord: nil,
            comment: "connectionless",
            goalCode: "goal-code",
            goal: "goal-value",
            autoAcceptProof: .always,
            willConfirm: true
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.createRequest(params: params)
        } assertion: { error in
//            XCTAssertTrue(
//                String(describing: error).contains("Unable to create request: no supported formats found.")
//            )
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofRepositorySpy.savedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testCreateRequest_WhenConnectionIsNil_ShouldCreateConnectionlessProofRecord() async throws {
        let expectedMessage = RequestPresentationMessageV2Builder()
            .setComment("connectionless")
            .build()

        proofFormatCoordinatorSpy.requestMessageToReturn = expectedMessage

        let proofRequest = AnonCredsProofRequest(
                name: "Proof Request",
                version: "1.0",
                nonce: "1234567890",
                requestedAttributes: [:],
                requestedPredicates: [:]
            )
        
        let params = CreateProofRequestOptions(
            proofRequest: proofRequest,
            formats: [
                ProofFormatSpec(
                    attachmentId: "anoncreds",
                    format: "anoncreds/proof-request@v1.0"
                )
            ],
            proofFormats: [
                "anoncreds": AnyCodable([
                    "name": "proof-format"
                ])
            ],
            connectionRecord: nil,
            comment: "connectionless",
            goalCode: "goal-code",
            goal: "goal-value",
            autoAcceptProof: .always,
            willConfirm: false
           
        )

        let (_, proofRecord) = try await sut.createRequest(params: params)

        XCTAssertEqual(proofRecord.connectionId, "connectionless-proof-request")
        XCTAssertEqual(proofRecord.state, ProofState.RequestSent)
        XCTAssertEqual(proofRecord.role, ProofRole.verifier)

        XCTAssertEqual(proofRepositorySpy.savedRecords.count, 1)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
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
