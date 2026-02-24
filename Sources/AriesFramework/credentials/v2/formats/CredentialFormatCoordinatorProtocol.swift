//
//  CredentialFormatCoordinatorProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 23/02/26.
//

import Foundation

public protocol CredentialFormatCoordinatorProtocol {
    func createProposal(params: CreateProposalParams) async throws -> ProposeCredentialMessageV2

    func processProposal(
        credentialExchangeRecord: CredentialExchangeRecord,
        message: ProposeCredentialMessageV2,
        formatServices: [any CredentialFormatService]
    ) async throws

    func acceptProposal(params: AcceptProposalParams) async throws -> OfferCredentialMessageV2

    // Offer
    func createOffer(params: CreateCredentialParams) async throws -> OfferCredentialMessageV2
    func processOffer(params: ProcessOfferParams) async throws
    func acceptOffer(params: AcceptOfferParams) async throws -> RequestCredentialMessageV2

    // Request
    func createRequest(params: RequestCredentialParams) async throws -> RequestCredentialMessageV2
    func processRequest(params: ProcessRequestParams) async throws
    func acceptRequest(params: AcceptRequestParams) async throws -> IssueCredentialMessageV2

    // Issue/Credential
    func processCredential(params: ProcessCredentialParams) async throws

    // Helper
    func getAttachmentForService(
        credentialFormatService: any CredentialFormatService,
        formats: [Format],
        attachments: [Attachment]
    ) throws -> Attachment
}

