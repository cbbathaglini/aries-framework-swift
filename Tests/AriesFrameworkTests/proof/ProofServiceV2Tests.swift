//
//  ProofServiceV2Tests.swift
//  aries-framework-swiftTests
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/26.
//

import XCTest
@testable import AriesFramework

final class ProofServiceV2Tests: XCTestCase {

    private var sut: ProofServiceV2!
    private var agent: Agent!

    private var proofRepository: MockProofRepository!
    private var delegateSpy: MockAgentDelegate!
    private var historyRepository: MockHistoryRepository!
    private var didCommMessageRepository: MockDidCommMessageRepository!

    override func setUp() {
        super.setUp()

        agent = Agent(agentConfig: .test(), agentDelegate: nil)

        proofRepository = MockProofRepository(agent: agent)
        delegateSpy = MockAgentDelegate()
        historyRepository = MockHistoryRepository(agent: agent)
        didCommMessageRepository = MockDidCommMessageRepository(agent: agent)

        agent.proofRepository = proofRepository
        agent.historyRepository = historyRepository
        agent.didCommMessageRepository = didCommMessageRepository
        agent.agentDelegate = delegateSpy

        sut = ProofServiceV2(agent: agent)
    }

    override func tearDown() {
        sut = nil
        didCommMessageRepository = nil
        historyRepository = nil
        delegateSpy = nil
        proofRepository = nil
        agent = nil
        super.tearDown()
    }

    // MARK: - autoSelectCredentialsForProofRequest

    func testAutoSelectCredentialsForProofRequest_WhenValidAttributesAndPredicates_ShouldSelectFirstNonRevoked() async throws {
        let attrRevoked = RequestedAttributeAnonCredsBuilder()
            .setCredentialId("cred-attr-revoked")
            .setRevoked(true)
            .build()

        let attrValid = RequestedAttributeAnonCredsBuilder()
            .setCredentialId("cred-attr-valid")
            .setRevoked(false)
            .build()

        let predRevoked = RequestedPredicateAnonCredsBuilder()
            .setCredentialId("cred-pred-revoked")
            .setRevoked(true)
            .build()

        let predValid = RequestedPredicateAnonCredsBuilder()
            .setCredentialId("cred-pred-valid")
            .setRevoked(false)
            .build()

        let retrieved = RetrievedCredentialsBuilder()
            .setRequestedAttributes([
                "attr1": [attrRevoked, attrValid]
            ])
            .setRequestedPredicates([
                "pred1": [predRevoked, predValid]
            ])
            .buildAnonCreds()

        let result = try await sut.autoSelectCredentialsForProofRequest(
            retrievedCredentials: retrieved
        )

        XCTAssertEqual(result.requestedAttributes["attr1"]?.credentialId, "cred-attr-valid")
        XCTAssertEqual(result.requestedPredicates["pred1"]?.credentialId, "cred-pred-valid")
    }

    func testAutoSelectCredentialsForProofRequest_WhenAttributeArrayIsEmpty_ShouldThrow() async {
        let retrieved = RetrievedCredentialsBuilder()
            .setRequestedAttributes([
                "attr1": []
            ])
            .buildAnonCreds()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.autoSelectCredentialsForProofRequest(
                retrievedCredentials: retrieved
            )
        } assertion: { error in
            XCTAssertTrue(error.localizedDescription.contains("Cannot find credentials for attribute 'attr1'"))
        }
    }

    func testAutoSelectCredentialsForProofRequest_WhenAllAttributesAreRevoked_ShouldThrow() async {
        let attrRevoked1 = RequestedAttributeAnonCredsBuilder()
            .setCredentialId("cred-1")
            .setRevoked(true)
            .build()

        let attrRevoked2 = RequestedAttributeAnonCredsBuilder()
            .setCredentialId("cred-2")
            .setRevoked(true)
            .build()

        let retrieved = RetrievedCredentialsBuilder()
            .setRequestedAttributes([
                "attr1": [attrRevoked1, attrRevoked2]
            ])
            .buildAnonCreds()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.autoSelectCredentialsForProofRequest(
                retrievedCredentials: retrieved
            )
        } assertion: { error in
            XCTAssertTrue(error.localizedDescription.contains("Cannot find non-revoked credentials for attribute 'attr1'"))
        }
    }

    func testAutoSelectCredentialsForProofRequest_WhenPredicateArrayIsEmpty_ShouldThrow() async {
        let retrieved = RetrievedCredentialsBuilder()
            .setRequestedPredicates([
                "pred1": []
            ])
            .buildAnonCreds()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.autoSelectCredentialsForProofRequest(
                retrievedCredentials: retrieved
            )
        } assertion: { error in
            XCTAssertTrue(error.localizedDescription.contains("Cannot find credentials for predicate 'pred1'"))
        }
    }

    func testAutoSelectCredentialsForProofRequest_WhenAllPredicatesAreRevoked_ShouldThrow() async {
        let predRevoked1 = RequestedPredicateAnonCredsBuilder()
            .setCredentialId("cred-1")
            .setRevoked(true)
            .build()

        let predRevoked2 = RequestedPredicateAnonCredsBuilder()
            .setCredentialId("cred-2")
            .setRevoked(true)
            .build()

        let retrieved = RetrievedCredentialsBuilder()
            .setRequestedPredicates([
                "pred1": [predRevoked1, predRevoked2]
            ])
            .buildAnonCreds()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.autoSelectCredentialsForProofRequest(
                retrievedCredentials: retrieved
            )
        } assertion: { error in
            XCTAssertTrue(error.localizedDescription.contains("Cannot find non-revoked credentials for predicate 'pred1'"))
        }
    }

    func testAutoSelectCredentialsForProofRequest_WhenEmptyInput_ShouldReturnEmptyRequestedCredentials() async throws {
        let retrieved = RetrievedCredentialsBuilder()
            .buildAnonCreds()

        let result = try await sut.autoSelectCredentialsForProofRequest(
            retrievedCredentials: retrieved
        )

        XCTAssertTrue(result.requestedAttributes.isEmpty)
        XCTAssertTrue(result.requestedPredicates.isEmpty)
        XCTAssertTrue(result.selfAttestedAttributes.isEmpty)
    }

    // MARK: - createAck

    func testCreateAck_WhenProofRecordIsPresentationReceived_ShouldReturnAckAndUpdateState() async throws {
        var proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-1")
            .setThreadId("thread-123")
            .setState(.PresentationReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let (ack, updatedRecord) = try await sut.createAck(proofRecord: &proofRecord)

        XCTAssertEqual(ack.status, .OK)
        XCTAssertEqual(ack.threadId, "thread-123")

        XCTAssertEqual(updatedRecord.state, .Done)
        XCTAssertEqual(proofRecord.state, .Done)

        XCTAssertEqual(proofRepository.updatedRecords.count, 1)
        XCTAssertEqual(proofRepository.updatedRecords.first?.id, "proof-1")

        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.state, .Done)
    }

    func testCreateAck_WhenProofRecordStateIsInvalid_ShouldThrow() async {
        var proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-2")
            .setThreadId("thread-456")
            .setState(.RequestReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.createAck(proofRecord: &proofRecord)
        }

        XCTAssertEqual(proofRepository.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
        XCTAssertEqual(proofRecord.state, .RequestReceived)
    }

    // MARK: - processOfflineAck

    func testProcessOfflineAck_ShouldReturnAckAndUpdateStateToDone() async throws {
        let proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-offline")
            .setThreadId("thread-offline")
            .setState(.PresentationReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let (ack, updatedRecord) = try await sut.processOfflineAck(proofRecord: proofRecord)

        XCTAssertEqual(ack.status, .OK)
        XCTAssertEqual(ack.threadId, "thread-offline")
        XCTAssertEqual(updatedRecord.state, .Done)

        XCTAssertEqual(proofRepository.updatedRecords.count, 1)
        XCTAssertEqual(proofRepository.updatedRecords.first?.id, "proof-offline")

        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.state, .Done)
    }

    // MARK: - createPresentationDeclinedProblemReport

    func testCreatePresentationDeclinedProblemReport_WhenStateIsRequestReceived_ShouldReturnProblemReportAndUpdateState() async throws {
        var proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-decline")
            .setThreadId("thread-decline")
            .setState(.RequestReceived)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        let (message, updatedRecord) = try await sut.createPresentationDeclinedProblemReport(
            proofRecord: &proofRecord
        )

        XCTAssertEqual(message.threadId, "thread-decline")
        XCTAssertEqual(updatedRecord.state, .Declined)
        XCTAssertEqual(proofRecord.state, .Declined)

        XCTAssertEqual(proofRepository.updatedRecords.count, 1)
        XCTAssertEqual(proofRepository.updatedRecords.first?.state, .Declined)

        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 1)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.first?.state, .Declined)
    }

    func testCreatePresentationDeclinedProblemReport_WhenStateIsInvalid_ShouldThrow() async {
        var proofRecord = ProofExchangeRecordBuilder()
            .setId("proof-invalid-decline")
            .setThreadId("thread-invalid-decline")
            .setState(.Done)
            .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.createPresentationDeclinedProblemReport(proofRecord: &proofRecord)
        }

        XCTAssertEqual(proofRepository.updatedRecords.count, 0)
        XCTAssertEqual(delegateSpy.receivedProofStateChanges.count, 0)
    }

    // MARK: - Helpers

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
