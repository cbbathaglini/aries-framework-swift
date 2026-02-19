//
//  CredentialsCommandProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/25.
//
import os

protocol CredentialsCommandProtocol {
    var agent: Agent { get }
    var logger: Logger { get }

    func registerHandlers(dispatcher: Dispatcher)
    func proposeCredential(options: CreateProposalOptionsProtocol) async throws -> CredentialExchangeRecord
    func offerCredential(options: CreateOfferOptionsProtocol) async throws -> CredentialExchangeRecord
    func acceptOffer(options: AcceptOfferOptionsProtocol) async throws -> CredentialExchangeRecord
    func declineOffer(options: AcceptOfferOptionsProtocol) async throws -> CredentialExchangeRecord
    func acceptRequest(options: AcceptRequestOptionsProtocol) async throws -> CredentialExchangeRecord
    func acceptCredential(options: AcceptCredentialOptionsProtocol) async throws -> CredentialExchangeRecord
    func findOfferMessage(credentialRecordId: String) async throws -> OfferCredentialMessageProtocol?
    func findRequestMessage(credentialRecordId: String) async throws -> RequestCredentialMessageProtocol?
    func findCredentialMessage(credentialRecordId: String) async throws -> IssueCredentialMessageProtocol?
}
