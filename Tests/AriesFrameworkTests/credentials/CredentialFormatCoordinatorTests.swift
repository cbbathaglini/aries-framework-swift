//
//  CredentialFormatCoordinatorTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 23/02/26.
//

import XCTest
@testable import AriesFramework

final class CredentialFormatCoordinatorTests: XCTestCase {

    private var agent: Agent!
    private var didCommRepo: MockDidCommMessageRepository!
    private var formatService: MockCredentialFormatService!
    private var coordinator: CredentialFormatCoordinator!

    override func setUp() {
        super.setUp()

        agent = Agent(agentConfig: .test(), agentDelegate: nil)

        didCommRepo = MockDidCommMessageRepository(agent: agent)
        agent.didCommMessageRepository = didCommRepo

        formatService = MockCredentialFormatService(formatKey: "anoncreds", credentialRecordType: "anoncreds")
        coordinator = CredentialFormatCoordinator(agent: agent, formatServices: [formatService])
    }

    // MARK: - Helpers

    private func makeAttachment(id: String = "anoncreds") -> Attachment {
        Attachment(
            id: id,
            mimetype: "application/json",
            data: AttachmentData(base64: "e30=", json: nil, links: nil)
        )
    }

    private func makeFormat(
        attachId: String = "anoncreds",
        format: String = "anoncreds/credential@v1.0"
    ) -> Format {
        Format(attachId: attachId, format: format)
    }

    private func makeRecord(
        id: String = UUID().uuidString,
        threadId: String = "th-1",
        parentThreadId: String? = nil
    ) -> CredentialExchangeRecord {
        var r = CredentialExchangeRecordBuilder()
            .setThreadId(threadId)
            .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
            .build()

        r.id = id
        r.parentThreadId = parentThreadId
        return r
    }

    // MARK: - createProposal

    func test_createProposal_createsMessage_setsThread_savesAsSender() async throws {
        let record = makeRecord(threadId: "th-prop")

        let params = CreateProposalParams(
            credentialFormats: ["anoncreds": [:]],
            formatServices: [formatService],
            credentialRecord: record,
            comment: "hi",
            goalCode: "gc",
            goal: "g"
        )

        let msg = try await coordinator.createProposal(params: params)

        XCTAssertTrue(formatService.createProposalCalled)
        XCTAssertEqual(msg.threadId, "th-prop")
        XCTAssertEqual(msg.comment, "hi")

        let stored: ProposeCredentialMessageV2? = try await didCommRepo.getTypedAgentMessage(
            associatedRecordId: record.id,
            messageType: ProposeCredentialMessageV2.type,
            role: .Sender
        )
        XCTAssertNotNil(stored)
        XCTAssertEqual(stored?.threadId, "th-prop")
    }

    // MARK: - processProposal

    func test_processProposal_callsService_andSavesAsReceiver() async throws {
        let record = makeRecord(threadId: "th-proc-prop")

        let msg = ProposeCredentialMessageV2(
            formats: [makeFormat()],
            proposalAttachments: [makeAttachment()],
            credentialPreview: nil,
            goalCode: nil,
            goal: nil,
            comment: nil
        )
        msg.setThread(threadId: "th-proc-prop", parentThreadId: nil)

        try await coordinator.processProposal(
            credentialExchangeRecord: record,
            message: msg,
            formatServices: [formatService]
        )

        XCTAssertTrue(formatService.processProposalCalled)

        let stored: ProposeCredentialMessageV2? = try await didCommRepo.getTypedAgentMessage(
            associatedRecordId: record.id,
            messageType: ProposeCredentialMessageV2.type,
            role: .Receiver
        )
        XCTAssertNotNil(stored)
        XCTAssertEqual(stored?.threadId, "th-proc-prop")
    }

    // MARK: - acceptProposal

    func test_acceptProposal_loadsProposalFromRepo_callsService_savesOfferAsSender() async throws {
        var record = makeRecord(threadId: "th-acc-prop")

        let proposal = ProposeCredentialMessageV2(
            formats: [makeFormat()],
            proposalAttachments: [makeAttachment()],
            credentialPreview: CredentialPreviewV2(attributes: []),
            goalCode: nil,
            goal: nil,
            comment: nil
        )
        proposal.setThread(threadId: "th-acc-prop", parentThreadId: nil)

        try await didCommRepo.saveOrUpdateAgentMessage(
            role: .Receiver,
            agentMessage: proposal,
            associatedRecordId: record.id
        )

        let params = AcceptProposalParams(
            credentialRecord: record,
            formatServices: [formatService],
            comment: "comment",
            goal: "goal",
            goalCode: "goalcode",
            credentialFormats: [:]
        )

        let offer = try await coordinator.acceptProposal(params: params)

        XCTAssertTrue(formatService.acceptProposalCalled)
        XCTAssertEqual(offer.threadId, "th-acc-prop")

        let stored: OfferCredentialMessageV2? = try await didCommRepo.getTypedAgentMessage(
            associatedRecordId: record.id,
            messageType: OfferCredentialMessageV2.type,
            role: .Sender
        )
        XCTAssertNotNil(stored)
        XCTAssertEqual(stored?.threadId, "th-acc-prop")
    }

    // MARK: - createOffer

    func test_createOffer_callsService_savesOfferAsSender() async throws {
        let record = makeRecord(threadId: "th-create-offer")

        let params = CreateCredentialParams(
            credentialRecord: record,
            formatServices: [formatService],
            comment: "comment",
            goal: nil,
            goalCode: nil,
            credentialFormats: ["anoncreds": [:]]
        )

        let offer = try await coordinator.createOffer(params: params)

        XCTAssertTrue(formatService.createOfferCalled)
        XCTAssertEqual(offer.threadId, "th-create-offer")

        let stored: OfferCredentialMessageV2? = try await didCommRepo.getTypedAgentMessage(
            associatedRecordId: record.id,
            messageType: OfferCredentialMessageV2.type,
            role: .Sender
        )
        XCTAssertNotNil(stored)
    }

    // MARK: - processOffer

    func test_processOffer_callsService_savesOfferAsReceiver() async throws {
        let record = makeRecord(threadId: "th-proc-offer")

        let offer = OfferCredentialMessageV2(
            formats: [makeFormat()],
            offerAttachments: [makeAttachment()],
            goalCode: nil,
            goal: nil,
            comment: nil,
            credentialPreview: CredentialPreviewV2(attributes: [])
        )
        offer.setThread(threadId: "th-proc-offer", parentThreadId: nil)

        let params = ProcessOfferParams(
            credentialExchangeRecord: record,
            message: offer,
            formatService: [formatService]
        )

        try await coordinator.processOffer(params: params)

        XCTAssertTrue(formatService.processOfferCalled)

        let stored: OfferCredentialMessageV2? = try await didCommRepo.getTypedAgentMessage(
            associatedRecordId: record.id,
            messageType: OfferCredentialMessageV2.type,
            role: .Receiver
        )
        XCTAssertNotNil(stored)
    }

    // MARK: - acceptOffer

    func test_acceptOffer_loadsOfferFromRepo_callsService_savesRequestAsSender() async throws {
        let record = makeRecord(threadId: "th-acc-offer")

        let offer = OfferCredentialMessageV2(
            formats: [makeFormat(attachId: "anoncreds", format: "anoncreds/credential@v1.0")],
            offerAttachments: [makeAttachment(id: "anoncreds")],
            goalCode: nil,
            goal: nil,
            comment: nil,
            credentialPreview: CredentialPreviewV2(attributes: [])
        )
        offer.setThread(threadId: "th-acc-offer", parentThreadId: nil)

        try await didCommRepo.saveOrUpdateAgentMessage(
            role: .Receiver,
            agentMessage: offer,
            associatedRecordId: record.id
        )

        let params = AcceptOfferParams(
            credentialRecord: record,
            formatServices: [formatService],
            comment: nil,
            goal: nil,
            goalCode: nil,
            credentialFormats: nil
        )

        let request = try await coordinator.acceptOffer(params: params)

        XCTAssertTrue(formatService.acceptOfferCalled)
        XCTAssertEqual(request.threadId, "th-acc-offer")

        let stored: RequestCredentialMessageV2? = try await didCommRepo.getTypedAgentMessage(
            associatedRecordId: record.id,
            messageType: RequestCredentialMessageV2.type,
            role: .Sender
        )
        XCTAssertNotNil(stored)
    }

    // MARK: - createRequest

    func test_createRequest_callsService_savesRequestAsSender() async throws {
        let record = makeRecord(threadId: "th-create-req")

        let params = RequestCredentialParams(
            credentialFormats: [makeFormat()],
            formatServices: [formatService],
            credentialRecord: record,
            comment: nil,
            goalCode: nil,
            goal: nil
        )

        let req = try await coordinator.createRequest(params: params)

        XCTAssertTrue(formatService.createRequestCalled)
        XCTAssertEqual(req.threadId, "th-create-req")

        let stored: RequestCredentialMessageV2? = try await didCommRepo.getTypedAgentMessage(
            associatedRecordId: record.id,
            messageType: RequestCredentialMessageV2.type,
            role: .Sender
        )
        XCTAssertNotNil(stored)
    }

    // MARK: - processRequest

    func test_processRequest_callsService_savesRequestAsReceiver() async throws {
        let record = makeRecord(threadId: "th-proc-req")

        let request = RequestCredentialMessageV2(
            formats: [makeFormat()],
            attachments: [],
            requestAttachments: [makeAttachment()],
            goalCode: nil,
            goal: nil,
            comment: nil
        )
        request.setThread(threadId: "th-proc-req", parentThreadId: nil)

        let params = ProcessRequestParams(
            credentialExchangeRecord: record,
            message: request,
            formatService: [formatService]
        )

        try await coordinator.processRequest(params: params)

        XCTAssertTrue(formatService.processRequestCalled)

        let stored: RequestCredentialMessageV2? = try await didCommRepo.getTypedAgentMessage(
            associatedRecordId: record.id,
            messageType: RequestCredentialMessageV2.type,
            role: .Receiver
        )
        XCTAssertNotNil(stored)
    }

    // MARK: - acceptRequest

    func test_acceptRequest_loadsRequestAndOffer_callsService_savesIssueAsSender() async throws {
        let record = makeRecord(threadId: "th-acc-req")

        let request = RequestCredentialMessageV2(
            formats: [makeFormat()],
            attachments: [],
            requestAttachments: [makeAttachment()],
            goalCode: nil,
            goal: nil,
            comment: nil
        )
        request.setThread(threadId: "th-acc-req", parentThreadId: nil)

        let offer = OfferCredentialMessageV2(
            formats: [makeFormat()],
            offerAttachments: [makeAttachment()],
            goalCode: nil,
            goal: nil,
            comment: nil,
            credentialPreview: CredentialPreviewV2(attributes: [])
        )
        offer.setThread(threadId: "th-acc-req", parentThreadId: nil)

        try await didCommRepo.saveOrUpdateAgentMessage(role: .Receiver, agentMessage: request, associatedRecordId: record.id)
        try await didCommRepo.saveOrUpdateAgentMessage(role: .Sender, agentMessage: offer, associatedRecordId: record.id)

        let params = AcceptRequestParams(
            credentialExchangeRecord: record,
            formatService: [formatService],
            comment: nil,
            goal: nil,
            goalCode: nil,
            credentialFormat: [:]
        )

        let issue = try await coordinator.acceptRequest(params: params)

        XCTAssertTrue(formatService.acceptRequestCalled)
        XCTAssertEqual(issue.threadId, "th-acc-req")

        let stored: IssueCredentialMessageV2? = try await didCommRepo.getTypedAgentMessage(
            associatedRecordId: record.id,
            messageType: IssueCredentialMessageV2.type,
            role: .Sender
        )
        XCTAssertNotNil(stored)
    }

    // MARK: - processCredential

    func test_processCredential_loadsOffer_callsService_savesIssueAsReceiver() async throws {
        let record = makeRecord(threadId: "th-proc-cred")

        let request = RequestCredentialMessageV2(
            formats: [makeFormat()],
            attachments: [],
            requestAttachments: [makeAttachment()],
            goalCode: nil,
            goal: nil,
            comment: nil
        )
        request.setThread(threadId: "th-proc-cred", parentThreadId: nil)

        let issue = IssueCredentialMessageV2(
            formats: [makeFormat()],
            credentialAttachments: [makeAttachment()]
        )
        issue.setThread(threadId: "th-proc-cred", parentThreadId: nil)

        let offer = OfferCredentialMessageV2(
            formats: [makeFormat()],
            offerAttachments: [makeAttachment()],
            goalCode: nil,
            goal: nil,
            comment: nil,
            credentialPreview: CredentialPreviewV2(attributes: [])
        )
        offer.setThread(threadId: "th-proc-cred", parentThreadId: nil)

        try await didCommRepo.saveOrUpdateAgentMessage(
            role: .Receiver,
            agentMessage: offer,
            associatedRecordId: record.id
        )

        let params = ProcessCredentialParams(
            credentialExchangeRecord: record,
            formatService: [formatService],
            requestCredentialMessageV2: request,
            message: issue
        )

        try await coordinator.processCredential(params: params)

        XCTAssertTrue(formatService.processCredentialCalled)

        let stored: IssueCredentialMessageV2? = try await didCommRepo.getTypedAgentMessage(
            associatedRecordId: record.id,
            messageType: IssueCredentialMessageV2.type,
            role: .Receiver
        )
        XCTAssertNotNil(stored)
    }

    // MARK: - Attachment helpers

    func test_getAttachmentIdForService_throwsWhenNoMatchingFormat() {
        XCTAssertThrowsError(
            try coordinator.getAttachmentIdForService(
                credentialFormatService: formatService,
                formats: [Format(attachId: "x", format: "something/else@v1.0")]
            )
        )
    }

    func test_getAttachmentForService_throwsWhenAttachmentMissing() {
        XCTAssertThrowsError(
            try coordinator.getAttachmentForService(
                credentialFormatService: formatService,
                formats: [makeFormat(attachId: "anoncreds", format: "anoncreds/credential@v1.0")],
                attachments: [] // <<< 
            )
        )
    }
}
