//
//  MockCredentialFormatCoordinator.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//
@testable import AriesFramework
import Foundation

final class MockCredentialFormatCoordinator: CredentialFormatCoordinatorProtocol {

    // Capturas
    private(set) var createProposalCalled = false
    private(set) var lastCreateProposalParams: CreateProposalParams?

    private(set) var processProposalCalled = false
    private(set) var lastProcessProposalRecord: CredentialExchangeRecord?
    private(set) var lastProcessProposalMessage: ProposeCredentialMessageV2?
    private(set) var lastProcessProposalServices: [any CredentialFormatService] = []

    private(set) var acceptProposalCalled = false
    private(set) var lastAcceptProposalParams: AcceptProposalParams?

    private(set) var createOfferCalled = false
    private(set) var lastCreateOfferParams: CreateCredentialParams?

    private(set) var processOfferCalled = false
    private(set) var lastProcessOfferParams: ProcessOfferParams?

    private(set) var acceptOfferCalled = false
    private(set) var lastAcceptOfferParams: AcceptOfferParams?

    private(set) var createRequestCalled = false
    private(set) var lastCreateRequestParams: RequestCredentialParams?

    private(set) var processRequestCalled = false
    private(set) var lastProcessRequestParams: ProcessRequestParams?

    private(set) var acceptRequestCalled = false
    private(set) var lastAcceptRequestParams: AcceptRequestParams?

    private(set) var processCredentialCalled = false
    private(set) var lastProcessCredentialParams: ProcessCredentialParams?

    // Stubs (o que seu teste quer que retorne)
    var createProposalResult = ProposeCredentialMessageV2(
        formats: [],
        proposalAttachments: [],
        credentialPreview: nil,
        goalCode: nil,
        goal: nil,
        comment: nil
    )

    var acceptProposalResult = OfferCredentialMessageV2(
        formats: [],
        offerAttachments: [],
        goalCode: nil,
        goal: nil,
        comment: nil,
        credentialPreview: CredentialPreviewV2(attributes: [])
    )

    var createOfferResult = OfferCredentialMessageV2(
        formats: [],
        offerAttachments: [],
        goalCode: nil,
        goal: nil,
        comment: nil,
        credentialPreview: CredentialPreviewV2(attributes: [])
    )

    var acceptOfferResult = RequestCredentialMessageV2(
        formats: [],
        attachments: [],
        requestAttachments: [],
        goalCode: nil,
        goal: nil,
        comment: nil
    )

    var createRequestResult = RequestCredentialMessageV2(
        formats: [],
        attachments: [],
        requestAttachments: [],
        goalCode: nil,
        goal: nil,
        comment: nil
    )

    var acceptRequestResult = IssueCredentialMessageV2(
        formats: [],
        credentialAttachments: [],
        goalCode: nil,
        goal: nil,
        comment: nil
    )

    // MARK: - Protocol

    func createProposal(params: CreateProposalParams) async throws -> ProposeCredentialMessageV2 {
        createProposalCalled = true
        lastCreateProposalParams = params
        return createProposalResult
    }

    func processProposal(
        credentialExchangeRecord: CredentialExchangeRecord,
        message: ProposeCredentialMessageV2,
        formatServices: [any CredentialFormatService]
    ) async throws {
        processProposalCalled = true
        lastProcessProposalRecord = credentialExchangeRecord
        lastProcessProposalMessage = message
        lastProcessProposalServices = formatServices
    }

    func acceptProposal(params: AcceptProposalParams) async throws -> OfferCredentialMessageV2 {
        acceptProposalCalled = true
        lastAcceptProposalParams = params
        return acceptProposalResult
    }

    func createOffer(params: CreateCredentialParams) async throws -> OfferCredentialMessageV2 {
        createOfferCalled = true
        lastCreateOfferParams = params
        return createOfferResult
    }

    func processOffer(params: ProcessOfferParams) async throws {
        processOfferCalled = true
        lastProcessOfferParams = params
    }

    func acceptOffer(params: AcceptOfferParams) async throws -> RequestCredentialMessageV2 {
        acceptOfferCalled = true
        lastAcceptOfferParams = params
        return acceptOfferResult
    }

    func createRequest(params: RequestCredentialParams) async throws -> RequestCredentialMessageV2 {
        createRequestCalled = true
        lastCreateRequestParams = params
        return createRequestResult
    }

    func processRequest(params: ProcessRequestParams) async throws {
        processRequestCalled = true
        lastProcessRequestParams = params
    }

    func acceptRequest(params: AcceptRequestParams) async throws -> IssueCredentialMessageV2 {
        acceptRequestCalled = true
        lastAcceptRequestParams = params
        return acceptRequestResult
    }

    func processCredential(params: ProcessCredentialParams) async throws {
        processCredentialCalled = true
        lastProcessCredentialParams = params
    }

    func getAttachmentForService(
        credentialFormatService: any CredentialFormatService,
        formats: [Format],
        attachments: [Attachment]
    ) throws -> Attachment {
        // Pra tests de shouldAutoRespond*, normalmente você só quer devolver "o primeiro"
        // (ou buscar por id se seus testes precisarem).
        return attachments[0]
    }
}
