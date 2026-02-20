//
//  CredentialServiceV2Protocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

public protocol CredentialServiceV2Protocol {

    // MARK: - Proposal

    func createProposal(
        options: CreateProposalOptionsV2
    ) async throws -> (ProposeCredentialMessageV2, CredentialExchangeRecord)

    func processProposal(
        _ messageContext: InboundMessageContext
    ) async throws -> CredentialExchangeRecord

    func acceptProposal(
        options: AcceptCredentialProposalOptions
    ) async throws -> (OfferCredentialMessageV2, CredentialExchangeRecord)

    func negotiateProposal(
        options: NegotiateCredentialProposalOptions
    ) async throws -> (CredentialExchangeRecord, OfferCredentialMessageV2)

    // MARK: - Offer

    func createOffer(
        options: CreateCredentialOfferOptionsV2
    ) async throws -> (CredentialExchangeRecord, OfferCredentialMessageV2)

    func processOffer(
        _ messageContext: InboundMessageContext
    ) async throws -> CredentialExchangeRecord

    func acceptOffer(
        options: AcceptCredentialOfferOptionsV2
    ) async throws -> (CredentialExchangeRecord, RequestCredentialMessageV2)

    func negotiateOffer(
        options: NegotiateCredentialOfferOptions
    ) async throws -> (CredentialExchangeRecord, ProposeCredentialMessageV2)

    // MARK: - Request

    func createRequest(
        options: CreateCredentialRequestOptions
    ) async throws -> (CredentialExchangeRecord, RequestCredentialMessageV2)

    func processRequest(
        _ messageContext: InboundMessageContext
    ) async throws -> CredentialExchangeRecord

    func acceptRequest(
        options: AcceptRequestOptionsV2
    ) async throws -> (CredentialExchangeRecord, IssueCredentialMessageV2)

    // MARK: - Credential

    func processCredential(
        _ messageContext: InboundMessageContext
    ) async throws -> CredentialExchangeRecord

    func acceptCredential(
        _ record: CredentialExchangeRecord
    ) async throws -> (CredentialExchangeRecord, CredentialAckMessageV2)

    func processAck(
        _ messageContext: InboundMessageContext
    ) async throws -> CredentialExchangeRecord

    // MARK: - Problem Report / Decline

    func createProblemReport(
        options: CreateCredentialProblemReportOptions
    ) async throws -> (CredentialExchangeRecord, CredentialProblemReportMessageV2)

    func declineOffer(
        credentialRecord: CredentialExchangeRecord,
        options: DeclineCredentialOfferOptions
    ) async throws -> CredentialExchangeRecord

    func sendProblemReport(
        _ options: SendCredentialProblemReportOptions
    ) async throws -> CredentialExchangeRecord

    // MARK: - Auto Accept

    func shouldAutoRespondToProposal(
        credentialRecord: CredentialExchangeRecord,
        messageContext: InboundMessageContext
    ) async throws -> Bool

    func shouldAutoRespondToOffer(
        credentialRecord: CredentialExchangeRecord,
        messageContext: InboundMessageContext
    ) async throws -> Bool

    func shouldAutoRespondToRequest(
        credentialRecord: CredentialExchangeRecord,
        messageContext: InboundMessageContext
    ) async throws -> Bool

    func shouldAutoRespondToCredential(
        credentialRecord: CredentialExchangeRecord,
        messageContext: InboundMessageContext
    ) async throws -> Bool

    // MARK: - Find Messages

    func findProposalMessage(
        credentialExchangeId: String
    ) async -> ProposeCredentialMessageV2?

    func findRequestMessage(
        credentialExchangeId: String
    ) async -> RequestCredentialMessageV2?

    func findOfferMessage(
        credentialExchangeId: String
    ) async -> OfferCredentialMessageV2?

//    func findMessage<T: Decodable>(
//        credentialExchangeId: String,
//        messageType: String
//    ) async -> T?
}

extension CredentialServiceV2 : CredentialServiceV2Protocol {}
