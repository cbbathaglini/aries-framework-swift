//
//  AckProofProcessorTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

import XCTest
@testable import AriesFramework

final class AckProofProcessorTests: XCTestCase {

    private var sut: AckProofProcessor!
    private var agent: Agent!
    private var proofRepositorySpy: MockProofRepository!
    private var didCommMessageRepositoryStub: MockDidCommMessageRepository!
    private var delegateSpy: MockAgentDelegate!
    private var common: CommonFunctions!

    override func setUp() async throws {
        try await super.setUp()

        agent = Agent(agentConfig: .test(), agentDelegate: nil)

        proofRepositorySpy = MockProofRepository(agent: agent)
        didCommMessageRepositoryStub = MockDidCommMessageRepository(agent: agent)
        delegateSpy = MockAgentDelegate()

        agent.proofRepository = proofRepositorySpy
        agent.didCommMessageRepository = didCommMessageRepositoryStub
        agent.agentDelegate = delegateSpy

        common = CommonFunctions(agent: agent, proofFormats: [])

        sut = AckProofProcessor(
            agent: agent,
            proofRepository: proofRepositorySpy,
            common: common
        )
    }

    override func tearDown() {
        sut = nil
        common = nil
        delegateSpy = nil
        didCommMessageRepositoryStub = nil
        proofRepositorySpy = nil
        agent = nil
        super.tearDown()
    }

    func testProcess_WhenAckIsValid_ShouldUpdateProofToDone() async throws {
        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .build()

        let ack = PresentationAckMessageV2Builder()
            .setId("ack-id")
            .setThreadId("thread-123")
            .setStatus(.OK)
            .build()

        var proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-123")
            .setThreadId("thread-123")
            .setConnectionId("conn-123")
            .setRole(.prover)
            .setState(.PresentationSent)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        proofRepositorySpy.stub([proofRecord])

        let presentation = PresentationMessageV2Builder()
            .setComment("presentation")
            .setLastPresentation(true)
            .build()

        let request = RequestPresentationMessageV2Builder()
            .setComment("request")
            .build()

        didCommMessageRepositoryStub.stubTyped(
            recordId: proofRecord.id,
            type: PresentationMessageV2.type,
            role: .Sender,
            message: presentation
        )

        didCommMessageRepositoryStub.stubTyped(
            recordId: proofRecord.id,
            type: RequestPresentationMessageV2.type,
            role: .Receiver,
            message: request
        )

        let context = try InboundMessageContextBuilder()
            .setPlaintextMessage(ack.toJsonString())
            .setConnection(connection)
            .build()

        let updated = try await sut.process(messageContext: context)

        XCTAssertEqual(updated.id, proofRecord.id)
        XCTAssertEqual(updated.state, ProofState.Done)
        XCTAssertEqual(updated.connectionId, "conn-123")

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 1)
        XCTAssertEqual(proofRepositorySpy.updatedRecords.first?.state, .Done)

        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.state, .Done)

        proofRecord = updated
        XCTAssertEqual(proofRecord.state, .Done)
    }

    func testProcess_WhenConnectionIsMissing_ShouldThrow() async throws {
        let ack = PresentationAckMessageV2Builder()
            .setThreadId("thread-123")
            .build()

        let context = try InboundMessageContextBuilder()
            .setPlaintextMessage(ack.toJsonString())
            .setConnection(nil)
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.process(messageContext: context)
        } assertion: { error in
            XCTAssertTrue(String(describing: error).contains("CredoError"))
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testProcess_WhenProofRecordNotFound_ShouldThrow() async throws{
        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .build()

        let ack = PresentationAckMessageV2Builder()
            .setThreadId("thread-not-found")
            .build()

        let context = try InboundMessageContextBuilder()
            .setPlaintextMessage(ack.toJsonString())
            .setConnection(connection)
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.process(messageContext: context)
        } assertion: { error in
            XCTAssertTrue(String(describing: error).contains("CredoError"))
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testProcess_WhenProofStateIsInvalid_ShouldThrow() async throws {
        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .build()

        let ack = PresentationAckMessageV2Builder()
            .setThreadId("thread-123")
            .build()

        let proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-123")
            .setThreadId("thread-123")
            .setConnectionId("conn-123")
            .setRole(.prover)
            .setState(.RequestReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        proofRepositorySpy.stub([proofRecord])

        let context = try InboundMessageContextBuilder()
            .setPlaintextMessage(ack.toJsonString())
            .setConnection(connection)
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.process(messageContext: context)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testProcess_WhenProtocolVersionIsInvalid_ShouldThrow() async throws{
        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .build()

        let ack = PresentationAckMessageV2Builder()
            .setThreadId("thread-123")
            .build()

        let proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-123")
            .setThreadId("thread-123")
            .setConnectionId("conn-123")
            .setRole(.prover)
            .setState(.PresentationSent)
            .setProtocolVersion("v1")
            .build()

        proofRepositorySpy.stub([proofRecord])

        let context = try InboundMessageContextBuilder()
            .setPlaintextMessage(ack.toJsonString())
            .setConnection(connection)
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.process(messageContext: context)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    func testProcess_WhenAckMessageIsInvalid_ShouldThrow() async throws{
        let connection = ConnectionRecordBuilder()
            .withId("conn-123")
            .build()

        let invalidJson = """
        {
          "@id": "ack-id",
          "@type": "invalid-type"
        }
        """

        let context = try InboundMessageContextBuilder()
            .setPlaintextMessage(invalidJson)
            .setConnection(connection)
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.process(messageContext: context)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
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
