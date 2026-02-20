//
//  CredentialServiceV2Tests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

//import XCTest
//@testable import AriesFramework
//
//final class CredentialServiceV2Tests: XCTestCase {
//
//    var agent: TestAgent!
//    var service: CredentialServiceV2!
//
//    var credentialRepo: MockCredentialExchangeRepository!
//    var didCommRepo: MockDidCommMessageRepository!
//    var formatService: MockCredentialFormatService!
//    var formatCoordinator: MockCredentialFormatCoordinator!
//    var delegate: SpyAgentDelegate!
//
//    override func setUp() {
//        super.setUp()
//
//        credentialRepo = MockCredentialExchangeRepository()
//        didCommRepo = MockDidCommMessageRepository()
//        formatService = MockCredentialFormatService()
//        formatCoordinator = MockCredentialFormatCoordinator()
//        delegate = SpyAgentDelegate()
//
//        agent = TestAgent(
//            credentialExchangeRepository: credentialRepo,
//            didCommMessageRepository: didCommRepo,
//            credentialFormatServices: [formatService],
//            credentialFormatCoordinator: formatCoordinator,
//            agentDelegate: delegate
//        )
//
//        service = CredentialServiceV2(agent: agent)
//    }
//    
//    func test_createProposal_createsRecordAndSaves() async throws {
//        let connection = ConnectionRecordTestFactory.readyConnection()
//
//        let options = CreateProposalOptionsV2(
//            connection: connection,
//            credentialFormats: ["anoncreds": [:]],
//            autoAcceptCredential: true
//        )
//
//        formatCoordinator.createProposalResult =
//            ProposeCredentialMessageV2Builder().build()
//
//        let (proposal, record) = try await service.createProposal(options: options)
//
//        XCTAssertEqual(record.state, .ProposalSent)
//        XCTAssertEqual(record.role, .holder)
//        XCTAssertEqual(record.connectionId, connection.id)
//
//        XCTAssertTrue(credentialRepo.saveCalled)
//        XCTAssertTrue(formatCoordinator.createProposalCalled)
//        XCTAssertTrue(delegate.credentialStateChangedCalled)
//    }
//    
//    func test_processProposal_existingRecord_updatesState() async throws {
//        let record = CredentialExchangeRecordBuilder()
//            .setState(.OfferSent)
//            .setRole(.issuer)
//            .setProtocolVersion("2.0")
//            .build()
//
//        credentialRepo.stubGetByThreadAndRole(record)
//
//        let proposal = ProposeCredentialMessageV2Builder()
//            .withThreadId(record.threadId)
//            .build()
//
//        let ctx = InboundMessageContextTestFactory.make(
//            plaintextMessage: proposal.toJsonString()
//        )
//
//        let result = try await service.processProposal(ctx)
//
//        XCTAssertEqual(result.state, .ProposalReceived)
//        XCTAssertTrue(credentialRepo.updateCalled)
//    }
//    
//    func test_acceptOffer_movesToRequestSent() async throws {
//        let record = CredentialExchangeRecordBuilder()
//            .setState(.OfferReceived)
//            .setRole(.holder)
//            .setProtocolVersion("2.0")
//            .build()
//
//        formatCoordinator.acceptOfferResult =
//            RequestCredentialMessageV2Builder().build()
//
//        let (updated, request) = try await service.acceptOffer(
//            options: AcceptCredentialOfferOptionsV2(
//                credentialExchangeRecord: record
//            )
//        )
//
//        XCTAssertEqual(updated.state, .RequestSent)
//        XCTAssertNotNil(request)
//    }
//    
//    func test_shouldAutoRespondToRequest_true() async throws {
//        formatService.shouldAutoRespondToRequestResult = true
//
//        let record = CredentialExchangeRecordBuilder()
//            .setAutoAcceptCredential(.contentApproved)
//            .build()
//
//        let ctx = InboundMessageContextTestFactory.make(
//            plaintextMessage: RequestCredentialMessageV2Builder().build().toJsonString()
//        )
//
//        let result = try await service.shouldAutoRespondToRequest(
//            credentialRecord: record,
//            messageContext: ctx
//        )
//
//        XCTAssertTrue(result)
//    }
//    
//    func test_integration_offer_to_request_flow() async throws {
//        let agent = TestAgentFactory.realistic()
//        let service = CredentialServiceV2(agent: agent)
//
//        let connection = ConnectionRecordTestFactory.readyConnection()
//
//        let (record, offer) = try await service.createOffer(
//            options: CreateCredentialOfferOptionsV2(
//                connectionRecord: connection,
//                credentialFormat: ["anoncreds": [:]]
//            )
//        )
//
//        let ctx = InboundMessageContextTestFactory.make(
//            connection: connection,
//            plaintextMessage: offer.toJsonString()
//        )
//
//        let updated = try await service.processOffer(ctx)
//
//        XCTAssertEqual(updated.state, .OfferReceived)
//    }
//}
