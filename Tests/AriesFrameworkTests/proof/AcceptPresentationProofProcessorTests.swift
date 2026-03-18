//
//  AcceptPresentationProofProcessorTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

import XCTest
@testable import AriesFramework

final class AcceptPresentationProofProcessorTests: XCTestCase {

    private var sut: AcceptPresentationProofProcessor!
    private var agent: Agent!
    private var common: CommonFunctions!

    private var didCommMessageRepositoryStub: MockDidCommMessageRepository!
    private var proofRepositorySpy: MockProofRepository!
    private var delegateSpy: MockAgentDelegate!

    override func setUp() async throws {
        try await super.setUp()

        agent = Agent(agentConfig: .test(), agentDelegate: nil)

        didCommMessageRepositoryStub = MockDidCommMessageRepository(agent: agent)
        proofRepositorySpy = MockProofRepository(agent: agent)
        delegateSpy = MockAgentDelegate()

        agent.didCommMessageRepository = didCommMessageRepositoryStub
        agent.proofRepository = proofRepositorySpy
        agent.agentDelegate = delegateSpy

        common = CommonFunctions(agent: agent, proofFormats: [])
        sut = AcceptPresentationProofProcessor(agent: agent, common: common)
    }

    override func tearDown() {
        sut = nil
        common = nil
        proofRepositorySpy = nil
        didCommMessageRepositoryStub = nil
        delegateSpy = nil
        agent = nil
        super.tearDown()
    }

    func testAcceptPresentation_WhenPresentationIsValid_ShouldReturnAckAndUpdateState() async throws {
        var proofRecord = ProofExchangeRecordBuilder()
            .setState(.PresentationReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let presentation = PresentationMessageV2Builder()
            .setComment("Proof presentation")
            .setLastPresentation(true)
            .build()

        didCommMessageRepositoryStub.stubTyped(
            recordId: proofRecord.id,
            type: PresentationMessageV2.type,
            role: .Sender,
            message: presentation
        )

        let (ack, updatedRecord) = try await sut.acceptPresentation(proofRecord: &proofRecord)

        XCTAssertEqual(ack.status, .OK)
        XCTAssertEqual(updatedRecord.state, .Done)
    }

    func testAcceptPresentation_WhenPresentationNotFound_ShouldThrow() async {
        var proofRecord = ProofExchangeRecordBuilder()
            .setState(.PresentationReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

//        await XCTAssertThrowsErrorAsync {
//            _ = try await self.sut.acceptPresentation(proofRecord: &proofRecord)
//        } assertion: { error in
//            print("ERROR TYPE = \(type(of: error))")
//            print("ERROR DESCRIBING = \(String(describing: error))")
//            print("ERROR LOCALIZED = \(error.localizedDescription)")
//        }
        
        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.acceptPresentation(proofRecord: &proofRecord)
        } assertion: { error in
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
        XCTAssertEqual(proofRecord.state, .PresentationReceived)
    }

    func testAcceptPresentation_WhenLastPresentationIsFalse_ShouldThrowAndNotUpdateState() async {
        var proofRecord = ProofExchangeRecordBuilder()
            .setState(.PresentationReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let presentation = PresentationMessageV2Builder()
            .setComment("Proof presentation")
            .setLastPresentation(false)
            .build()

        didCommMessageRepositoryStub.stubTyped(
                recordId: proofRecord.id,
                type: PresentationMessageV2.type,
                role: .Sender,
                message: presentation
            )
        
        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.acceptPresentation(proofRecord: &proofRecord)
        } assertion: { error in
            XCTAssertTrue(error is CredoError)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
        XCTAssertEqual(proofRecord.state, .PresentationReceived)
    }

    func testAcceptPresentation_WhenProofStateIsInvalid_ShouldThrow() async {
        var proofRecord = ProofExchangeRecordBuilder()
            .setState(.RequestReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.acceptPresentation(proofRecord: &proofRecord)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
    
    }

    func testAcceptPresentation_WhenProtocolVersionIsInvalid_ShouldThrow() async {
        var proofRecord = ProofExchangeRecordBuilder()
            .setState(.PresentationReceived)
            .setProtocolVersion("v1")
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.acceptPresentation(proofRecord: &proofRecord)
        }

        XCTAssertEqual(proofRepositorySpy.updatedRecords.count, 0)
    
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
