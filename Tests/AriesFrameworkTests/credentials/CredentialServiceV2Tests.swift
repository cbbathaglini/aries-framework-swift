//
//  CredentialServiceV2Tests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

import XCTest
@testable import AriesFramework

final class CredentialServiceV2Tests: XCTestCase {

    private var agent: Agent!
    private var service: CredentialServiceV2!

    private var credentialRepo: MockCredentialExchangeRepository!
    private var didCommRepo: MockDidCommMessageRepository!
    private var coordinator: MockCredentialFormatCoordinator!
    private var formatService: MockCredentialFormatService!
    private var delegate: SpyAgentDelegate!

    override func setUp() {
        super.setUp()

        coordinator = MockCredentialFormatCoordinator()
        formatService = MockCredentialFormatService(formatKey: "anoncreds")
        delegate = SpyAgentDelegate()
        
        agent = Agent(agentConfig: .test(), agentDelegate: delegate)

        credentialRepo = MockCredentialExchangeRepository(agent: agent)
        didCommRepo = MockDidCommMessageRepository(agent: agent)

        agent.credentialExchangeRepository = credentialRepo
        agent.didCommMessageRepository = didCommRepo

        agent.credentialV2Dependencies = TestCredentialV2DependenciesProvider(
            formatServices: [formatService],
            coordinator: coordinator
        )

        service = CredentialServiceV2(agent: agent)
    }
    
    func test_processProposal_whenRecordExists_updatesStateToProposalReceived() async throws {
        
        let existing = CredentialExchangeRecordBuilder()
            .setThreadId("th-1")
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .setState(.OfferSent)
            .setRole(.issuer)
            .setConnectionId(nil)
            .build()

        credentialRepo.stub([existing])

        let attachment = Attachment(
            id: "anoncreds",
            mimetype: "application/json",
            data: AttachmentData(base64: "e30=", json: nil, links: nil)
        )
        
        let proposal = ProposeCredentialMessageV2(
            formats: [Format(attachId: "anoncreds", format: "anoncreds/credential@v1.0")],
            proposalAttachments: [attachment]
        )
        proposal.setThread(threadId: "th-1", parentThreadId: nil)

        let connection = ConnectionRecordTestFactory.readyConnection()
        let ctx = try InboundMessageContextTestFactory.make(
            plaintextMessage: proposal.toJsonString(),
            connection: connection
        )

        let result = try await service.processProposal(ctx)

        XCTAssertTrue(coordinator.processProposalCalled)
        XCTAssertTrue(credentialRepo.updateCalled)
        XCTAssertEqual(result.state, CredentialState.ProposalReceived)
        XCTAssertEqual(result.connectionId, connection.id)
        XCTAssertTrue(delegate.onCredentialStateV2ChangedCalled)
    }

    func test_processProposal_whenNoRecord_createsNewIssuerRecordAndSaves() async throws {
        credentialRepo.stub([])

        let attachment = Attachment(
            id: "anoncreds",
            mimetype: "application/json",
            data: AttachmentData(base64: "e30=", json: nil, links: nil)
        )
        
        let proposal = ProposeCredentialMessageV2(
            formats: [Format(attachId: "anoncreds", format: "anoncreds/credential@v1.0")],
            proposalAttachments: [attachment]
        )
        proposal.setThread(threadId: "th-new", parentThreadId: nil)

        let connection = ConnectionRecordTestFactory.readyConnection()
        let ctx = try InboundMessageContextTestFactory.make(
            plaintextMessage: proposal.toJsonString(),
            connection: connection,
        )

        
        let rec = try await service.processProposal(ctx)

        
        XCTAssertTrue(coordinator.processProposalCalled)
        XCTAssertTrue(credentialRepo.saveCalled)
        XCTAssertEqual(rec.role, .issuer)
        XCTAssertEqual(rec.state, .ProposalReceived)
        XCTAssertEqual(rec.connectionId, connection.id)
        XCTAssertTrue(delegate.onCredentialStateV2ChangedCalled)
    }

    // MARK: - acceptProposal

    func test_acceptProposal_whenFormatsNotProvided_loadsProposalFromDidCommAndCallsCoordinator() async throws {
    
        var record = CredentialExchangeRecordBuilder()
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .setState(.ProposalReceived)
            .setRole(.issuer)
            .setThreadId("th-acc")
            .build()

        let attachment = Attachment(
            id: "anoncreds",
            mimetype: "application/json",
            data: AttachmentData(base64: "e30=", json: nil, links: nil)
        )
        
        let proposal = ProposeCredentialMessageV2(
            formats: [Format(attachId: "anoncreds", format: "anoncreds/credential@v1.0")],
            proposalAttachments: [attachment]
        )
        proposal.setThread(threadId: "th-acc", parentThreadId: nil)

        try didCommRepo.stubString(
            recordId: record.id,
            type: ProposeCredentialMessageV2.type,
            role: DidCommMessageRole.Receiver,
            json: proposal.toJsonString()
        )

        coordinator.acceptProposalResult = OfferCredentialMessageV2(
            formats: [],
            offerAttachments: [],
            credentialPreview: CredentialPreviewV2(attributes: [])
        )

        let (offer, updated) = try await service.acceptProposal(
            options: AcceptCredentialProposalOptions(
                credentialExchangeRecord: record,
                credentialFormats: [:],
                autoAcceptCredential: .always,
                comment: nil,
                goal: nil,
                goalCode: nil
            )
        )

        
        XCTAssertTrue(coordinator.acceptProposalCalled)
        XCTAssertEqual(updated.state, .OfferSent)
        XCTAssertTrue(credentialRepo.updateCalled)
        XCTAssertTrue(delegate.onCredentialStateV2ChangedCalled)
        _ = offer
    }

    // MARK: - processOffer (new record path)

    func test_processOffer_whenNoRecord_createsNewHolderRecordAndSaves() async throws {
        credentialRepo.stub([])

        let attachment = Attachment(
            id: "anoncreds",
            mimetype: "application/json",
            data: AttachmentData(base64: "e30=", json: nil, links: nil)
        )
        
        let offer = OfferCredentialMessageV2(
            formats: [Format(attachId: "anoncreds", format: "anoncreds/credential@v1.0")],
            offerAttachments: [attachment],
            goalCode: nil,
            goal: nil,
            comment: nil,
            credentialPreview: CredentialPreviewV2(attributes: [])
        )
        offer.setThread(threadId: "th-offer", parentThreadId: nil)

        let connection = ConnectionRecordTestFactory.readyConnection()
        let ctx = try InboundMessageContextTestFactory.make(
            plaintextMessage: offer.toJsonString(),
            connection: connection
        )

        let rec = try await service.processOffer(ctx)

        XCTAssertTrue(coordinator.processOfferCalled)
        XCTAssertTrue(credentialRepo.saveCalled)
        XCTAssertEqual(rec.role, CredentialRole.holder)
        XCTAssertEqual(rec.state, CredentialState.OfferReceived)
        XCTAssertEqual(rec.connectionId, connection.id)
        XCTAssertTrue(delegate.onCredentialStateV2ChangedCalled)
    }

        // MARK: - acceptOffer

    func test_acceptOffer_whenFormatsNotProvided_loadsOfferFromDidCommAndMovesToRequestSent() async throws {
        var record = CredentialExchangeRecordBuilder()
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .setState(.OfferReceived)
            .setRole(.holder)
            .setThreadId("th-x")
            .build()
        
        let attachment = Attachment(
            id: "anoncreds",
            mimetype: "application/json",
            data: AttachmentData(base64: "e30=", json: nil, links: nil)
        )

        let offer = OfferCredentialMessageV2(
            formats: [Format(attachId: "anoncreds", format: "anoncreds/credential@v1.0")],
            offerAttachments: [attachment],
            goalCode: nil,
            goal: nil,
            comment: nil,
            credentialPreview: CredentialPreviewV2(attributes: [])
        )
        offer.setThread(threadId: record.threadId ?? "th-x", parentThreadId: nil)

        didCommRepo.stubTyped(
            recordId: record.id,
            type: OfferCredentialMessageV2.type,
            role: .Receiver,
            message: offer
        )

        coordinator.acceptOfferResult = RequestCredentialMessageV2(
            formats: [],
            attachments: [],
            requestAttachments: []
        )

        let (updated, request) = try await service.acceptOffer(
            options: AcceptCredentialOfferOptionsV2(
                credentialExchangeRecord: record,
                autoAcceptCredential: .always,
                comment: nil,
                goal: nil,
                goalCode: nil,
                credentialFormats: [
                    Format(attachId: "anoncreds", format: "anoncreds/credential@v1.0")
                ]
            )
        )
        
        XCTAssertTrue(coordinator.acceptOfferCalled)
        XCTAssertEqual(updated.state, CredentialState.RequestSent)
        XCTAssertTrue(credentialRepo.updateCalled)
        XCTAssertTrue(delegate.onCredentialStateV2ChangedCalled)
        _ = request
    }
    
    func test_negotiateProposal_whenHasConnection_createsOfferAndMovesToOfferSent() async throws {
        var record = CredentialExchangeRecordBuilder()
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .setState(.ProposalReceived)
            .setRole(.issuer)
            .setThreadId("th-neg-prop")
            .setConnectionId("conn-1")
            .build()

        coordinator.createOfferResult = OfferCredentialMessageV2(
            formats: [],
            offerAttachments: [],
            credentialPreview: CredentialPreviewV2(attributes: [])
        )

        let (updated, offer) = try await service.negotiateProposal(
            options: NegotiateCredentialProposalOptions(
                credentialExchangeRecord: record,
                credentialFormats: ["anoncreds": [:]],
                autoAcceptCredential: .always,
                comment: nil,
                goalCode: nil,
                goal: nil,
            )
        )

        XCTAssertTrue(coordinator.createOfferCalled)
        XCTAssertEqual(updated.state, .OfferSent)
        XCTAssertTrue(credentialRepo.updateCalled)
        XCTAssertTrue(delegate.onCredentialStateV2ChangedCalled)
        _ = offer
    }
    
    func test_negotiateProposal_whenNoConnectionId_throws() async throws {
        let record = CredentialExchangeRecordBuilder()
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .setState(.ProposalReceived)
            .setRole(.issuer)
            .setThreadId("th-neg-prop-err")
            .setConnectionId(nil)
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await self.service.negotiateProposal(
                options: NegotiateCredentialProposalOptions(
                    credentialExchangeRecord: record,
                    credentialFormats: ["anoncreds": [:]],
                    autoAcceptCredential: nil,
                    comment: nil,
                    goalCode: nil,
                    goal: nil,
                )
            )
        }
    }
    
    func test_createOffer_savesRecord_andReturnsOffer() async throws {
        let connection = ConnectionRecordTestFactory.readyConnection()

        coordinator.createOfferResult = OfferCredentialMessageV2(
            formats: [],
            offerAttachments: [],
            credentialPreview: CredentialPreviewV2(attributes: [])
        )

        let (rec, offer) = try await service.createOffer(
            options: CreateCredentialOfferOptionsV2(
                credentialFormat: ["anoncreds": [:]],
                autoAcceptCredential: .always,
                comment: nil,
                goal: nil,
                goalCode: nil,
                connectionRecord: connection
            )
        )

        XCTAssertTrue(coordinator.createOfferCalled)
        XCTAssertTrue(credentialRepo.saveCalled)
        XCTAssertEqual(rec.role, CredentialRole.issuer)
        XCTAssertEqual(rec.state, CredentialState.OfferSent)
        XCTAssertEqual(rec.connectionId, connection.id)
        XCTAssertTrue(delegate.onCredentialStateV2ChangedCalled)
        _ = offer
    }
    
    func test_processOffer_whenRecordExists_updatesStateToOfferReceived() async throws {
        let connection = ConnectionRecordTestFactory.readyConnection()

        let existing = CredentialExchangeRecordBuilder()
            .setThreadId("th-offer-exists")
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .setState(.ProposalSent)
            .setRole(.holder)
            .setConnectionId(connection.id)
            .build()

        credentialRepo.stub([existing])

        let attachment = Attachment(
            id: "anoncreds",
            mimetype: "application/json",
            data: AttachmentData(base64: "e30=", json: nil, links: nil)
        )

        let offer = OfferCredentialMessageV2(
            formats: [Format(attachId: "anoncreds", format: "anoncreds/credential@v1.0")],
            offerAttachments: [attachment],
            goalCode: nil,
            goal: nil,
            comment: nil,
            credentialPreview: CredentialPreviewV2(attributes: [])
        )
        offer.setThread(threadId: "th-offer-exists", parentThreadId: nil)

        let ctx = try InboundMessageContextTestFactory.make(
            plaintextMessage: offer.toJsonString(),
            connection: connection
        )

        let result = try await service.processOffer(ctx)

        XCTAssertTrue(coordinator.processOfferCalled)
        XCTAssertTrue(credentialRepo.updateCalled)
        XCTAssertEqual(result.state, .OfferReceived)
        XCTAssertTrue(delegate.onCredentialStateV2ChangedCalled)
    }
    
    func test_negotiateOffer_whenHasConnection_createsProposalAndMovesToProposalSent() async throws {
        var record = CredentialExchangeRecordBuilder()
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .setState(.OfferReceived)
            .setRole(.holder)
            .setThreadId("th-neg-offer")
            .setConnectionId("conn-1")
            .build()

        coordinator.createProposalResult = ProposeCredentialMessageV2(
            formats: [],
            proposalAttachments: []
        )

        let (updated, proposal) = try await service.negotiateOffer(
            options: NegotiateCredentialOfferOptions(
                credentialExchangeRecord: record,
                credentialFormat: ["anoncreds": [:]],
                autoAcceptCredential: .always,
                comment: nil,
                goal: nil,
                goalCode: nil
            )
        )

        XCTAssertTrue(coordinator.createProposalCalled)
        XCTAssertEqual(updated.state, .ProposalSent)
        XCTAssertTrue(credentialRepo.updateCalled)
        XCTAssertTrue(delegate.onCredentialStateV2ChangedCalled)
        _ = proposal
    }
    
    func test_createRequest_savesRecord_andReturnsRequest() async throws {
        let connection = ConnectionRecordTestFactory.readyConnection()

        coordinator.createRequestResult = RequestCredentialMessageV2(
            formats: [],
            attachments: [],
            requestAttachments: []
        )
        
        let (rec, request) = try await service.createRequest(
            options: CreateCredentialRequestOptions(
                credentialFormats: [Format(attachId: "anoncreds", format: "anoncreds/credential@v1.0")],
                autoAcceptCredential: .always,
                comment: nil,
                goal: nil,
                goalCode: nil,
                connectionRecord: connection,
                
            )
        )

        XCTAssertTrue(coordinator.createRequestCalled)
        XCTAssertTrue(credentialRepo.saveCalled)
        XCTAssertEqual(rec.role, CredentialRole.holder)
        XCTAssertEqual(rec.state, CredentialState.RequestSent)
        XCTAssertEqual(rec.connectionId, connection.id)
        XCTAssertTrue(delegate.onCredentialStateV2ChangedCalled)
        _ = request
    }
    
    func test_processRequest_whenNoRecord_createsNewIssuerRecordAndSaves() async throws {
        credentialRepo.stub([])

        let connection = ConnectionRecordTestFactory.readyConnection()

        let attachment = Attachment(
            id: "anoncreds",
            mimetype: "application/json",
            data: AttachmentData(base64: "e30=", json: nil, links: nil)
        )

        let request = RequestCredentialMessageV2(
            formats: [Format(attachId: "anoncreds", format: "anoncreds/credential@v1.0")],
            attachments: [attachment],
            requestAttachments: [attachment]
        )
        request.setThread(threadId: "th-req-new", parentThreadId: nil)

        let ctx = try InboundMessageContextTestFactory.make(
            plaintextMessage: request.toJsonString(),
            connection: connection
        )

        let rec = try await service.processRequest(ctx)

        XCTAssertTrue(coordinator.processRequestCalled)
        XCTAssertTrue(credentialRepo.saveCalled)
        XCTAssertEqual(rec.role, .issuer)
        XCTAssertEqual(rec.state, .RequestReceived)
        XCTAssertEqual(rec.connectionId, connection.id)
        XCTAssertTrue(delegate.onCredentialStateV2ChangedCalled)
    }
    
    func test_acceptRequest_whenFormatsNotProvided_loadsRequestFromDidCommAndMovesToCredentialIssued() async throws {
        var record = CredentialExchangeRecordBuilder()
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .setState(.OfferSent)
            .setRole(.issuer)
            .setThreadId("th-acc-req")
            .build()

        let attachment = Attachment(
            id: "anoncreds",
            mimetype: "application/json",
            data: AttachmentData(base64: "e30=", json: nil, links: nil)
        )

        let request = RequestCredentialMessageV2(
            formats: [Format(attachId: "anoncreds", format: "anoncreds/credential@v1.0")],
            attachments: [attachment],
            requestAttachments: [attachment]
        )
        request.setThread(threadId: "th-acc-req", parentThreadId: nil)

        try didCommRepo.stubString(
            recordId: record.id,
            type: RequestCredentialMessageV2.type,
            role: .Sender,
            json: request.toJsonString()
        )

        coordinator.acceptRequestResult = IssueCredentialMessageV2(
            formats: [],
            credentialAttachments: []
        )

        let (updated, issue) = try await service.acceptRequest(
            options: AcceptRequestOptionsV2(
                credentialExchangeRecord: record,
                autoAcceptCredential: .always,
                comment: nil,
                goal: nil,
                goalCode: nil,
                credentialFormats: [
                    "anoncreds" : Format(attachId: "anoncreds", format: "anoncreds/credential@v1.0")
                ]
            )
        )

        XCTAssertTrue(coordinator.acceptRequestCalled)
        XCTAssertEqual(updated.state, CredentialState.CredentialIssued)
        XCTAssertTrue(credentialRepo.updateCalled)
        XCTAssertTrue(delegate.onCredentialStateV2ChangedCalled)
        _ = issue
    }
    
    func test_processCredential_movesToCredentialReceived() async throws {
        let connection = ConnectionRecordTestFactory.readyConnection()

        let existing = CredentialExchangeRecordBuilder()
            .setThreadId("th-cred")
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .setState(.RequestSent)
            .setRole(.holder)
            .setConnectionId(connection.id)
            .build()

        credentialRepo.stub([existing])

        let attachment = Attachment(
            id: "anoncreds",
            mimetype: "application/json",
            data: AttachmentData(base64: "e30=", json: nil, links: nil)
        )

        let request = RequestCredentialMessageV2(
            formats: [Format(attachId: "anoncreds", format: "anoncreds/credential@v1.0")],
            attachments: [attachment],
            requestAttachments: [attachment]
        )
        request.setThread(threadId: "th-cred", parentThreadId: nil)

//        try didCommRepo.stubString(
//            recordId: existing.id,
//            type: RequestCredentialMessageV2.type,
//            role: .Sender,
//            json: request.toJsonString()
//        )
        
        try await didCommRepo.saveAgentMessage(
            role: .Sender,
            agentMessage: request,
            associatedRecordId: existing.id
        )

        let issue = IssueCredentialMessageV2(
            formats: [Format(attachId: "anoncreds", format: "anoncreds/credential@v1.0")],
            credentialAttachments: [attachment]
        )
        issue.setThread(threadId: "th-cred", parentThreadId: nil)

        let ctx = try InboundMessageContextTestFactory.make(
            plaintextMessage: issue.toJsonString(),
            connection: connection
        )

        let rec = try await service.processCredential(ctx)

        XCTAssertTrue(coordinator.processCredentialCalled)
        XCTAssertEqual(rec.state, .CredentialReceived)
        XCTAssertTrue(credentialRepo.updateCalled)
        XCTAssertTrue(delegate.onCredentialStateV2ChangedCalled)
    }
    
    func test_acceptCredential_movesToDone_andReturnsAck() async throws {
        let record = CredentialExchangeRecordBuilder()
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .setState(.CredentialReceived)
            .setRole(.holder)
            .setThreadId("th-ack")
            .build()

        let (updated, ack) = try await service.acceptCredential(record)

        XCTAssertEqual(updated.state, .Done)
        XCTAssertTrue(credentialRepo.updateCalled)
        XCTAssertTrue(delegate.onCredentialStateV2ChangedCalled)
        XCTAssertEqual(ack.status, .OK)
    }
    
    func test_processAck_movesToDone() async throws {
        let connection = ConnectionRecordTestFactory.readyConnection()

        let existing = CredentialExchangeRecordBuilder()
            .setThreadId("th-proc-ack")
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .setState(.CredentialIssued)
            .setRole(.issuer)
            .setConnectionId(connection.id)
            .build()

        credentialRepo.stub([existing])

        let attachment = Attachment(
               id: "anoncreds",
               mimetype: "application/json",
               data: AttachmentData(base64: "e30=", json: nil, links: nil)
           )
        
        let request = RequestCredentialMessageV2(
                formats: [Format(attachId: "anoncreds", format: "anoncreds/credential@v1.0")],
                attachments: [attachment],
                requestAttachments: [attachment]
            )
        
        request.setThread(threadId: "th-proc-ack", parentThreadId: nil)

        try didCommRepo.stubString(
            recordId: existing.id,
            type: RequestCredentialMessageV2.type,
            role: .Receiver,
            json: request.toJsonString()
        )

        let issue = IssueCredentialMessageV2(formats: [], credentialAttachments: [])
        issue.setThread(threadId: "th-proc-ack", parentThreadId: nil)

        try didCommRepo.stubString(
            recordId: existing.id,
            type: IssueCredentialMessageV2.type,
            role: .Sender,
            json: issue.toJsonString()
        )

        let ack = CredentialAckMessageV2(threadId: "th-proc-ack", status: .OK)
        ack.setThread(threadId: "th-proc-ack", parentThreadId: nil)

        let ctx = try InboundMessageContextTestFactory.make(
            plaintextMessage: ack.toJsonString(),
            connection: connection
        )

        let rec = try await service.processAck(ctx)

        XCTAssertEqual(rec.state, .Done)
        XCTAssertTrue(credentialRepo.updateCalled)
        XCTAssertTrue(delegate.onCredentialStateV2ChangedCalled)
    }
    
    private func XCTAssertThrowsErrorAsync(
        _ expression: @escaping () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await expression()
            XCTFail("Expected error, but no error was thrown", file: file, line: line)
        } catch {
            // ok
        }
    }
}

