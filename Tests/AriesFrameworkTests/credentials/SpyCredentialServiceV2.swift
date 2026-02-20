//
//  SpyCredentialServiceV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework
import Foundation

public final class SpyCredentialServiceV2: CredentialServiceV2Protocol {

    // MARK: - Spies / Captures

    
    private(set) var processAckCalled = false
    private(set) var receivedMessageContext: InboundMessageContext?
    
    private(set) var processCredentialCalled = false
    private(set) var shouldAutoRespondCalled = false
    private(set) var acceptCredentialCalled = false
    
    private(set) var processOfferCalled = false
    private(set) var shouldAutoRespondToOfferCalled = false
    private(set) var acceptOfferCalled = false
    
    private(set) var processProposalCalled = false
    private(set) var acceptProposalCalled = false

    private(set) var  processRequestCalled = false
    private(set) var  acceptRequestCalled = false
    private(set) var  shouldAutoRespondToRequestCalled = false
    
    var errorToThrow: Error?
    var shouldAutoRespondResult: Bool = false
    var shouldAutoRespondToOfferResult: Bool = false
    var autoRespond = true
    var shouldAutoRespondToRequestResult = true
    
    public init() {}

    public func processAck(
        _ messageContext: InboundMessageContext
    ) async throws -> CredentialExchangeRecord {
        processAckCalled = true
        receivedMessageContext = messageContext
        
        if let error = errorToThrow {
           throw error
        }
        
        return CredentialExchangeRecordBuilder()
            .setState(.Done)
            .setProtocolVersion("2.0")
            .setRole(.issuer)
            .build()
    }


    public func createProposal(
        options: CreateProposalOptionsV2
    ) async throws -> (ProposeCredentialMessageV2, CredentialExchangeRecord) {
        fatalError("Not implemented")
    }

    public func processProposal(
        _ messageContext: InboundMessageContext
    ) async throws -> CredentialExchangeRecord {
        processProposalCalled = true
        return CredentialExchangeRecordBuilder()
            .setId("rec-1")
            .setProtocolVersion("2.0")
            .setRole(.issuer)
            .setState(.ProposalReceived)
            .build()
    }

    public func acceptProposal(
        options: AcceptCredentialProposalOptions
    ) async throws -> (OfferCredentialMessageV2, CredentialExchangeRecord) {
        acceptProposalCalled = true

    let json = """
        {
          "@id": "offer-1",
          "@type": "\(OfferCredentialMessageV2.type)",
          "formats": [
            { "attach_id": "anoncreds", "format": "anoncreds/credential-offer@v1.0" }
          ],
          "offers~attach": [
            {
              "@id": "anoncreds",
              "mime-type": "application/json",
              "data": { "json": "{}" }
            }
          ],
          "attachments": []
        }
        """

        let offer = try JSONDecoder().decode(
            OfferCredentialMessageV2.self,
            from: Data(json.utf8)
        )

        return (offer, options.credentialExchangeRecord)
    }

    public func negotiateProposal(
        options: NegotiateCredentialProposalOptions
    ) async throws -> (CredentialExchangeRecord, OfferCredentialMessageV2) {
        fatalError("Not implemented")
    }

    // MARK: - Offer

    public func createOffer(
        options: CreateCredentialOfferOptionsV2
    ) async throws -> (CredentialExchangeRecord, OfferCredentialMessageV2) {
        fatalError("Not implemented")
    }

    public func processOffer(
        _ messageContext: InboundMessageContext
    ) async throws -> CredentialExchangeRecord {
        processOfferCalled = true

        return CredentialExchangeRecordBuilder()
            .setId("offer-cred-id")
            .setState(.OfferReceived)
            .setProtocolVersion("2.0")
            .setRole(.holder)
            .build()
    }

    public func acceptOffer(
        options: AcceptCredentialOfferOptionsV2
    ) async throws -> (CredentialExchangeRecord, RequestCredentialMessageV2) {
        acceptOfferCalled = true

        let request = RequestCredentialMessageV2Builder()
             .withFormat(FormatTestFactory.anoncreds())
             .withRequestAttachment(
                 AttachmentTestFactory.json(id: "anoncreds")
             )
             .build()


        return (options.credentialExchangeRecord, request)
    }

    public func negotiateOffer(
        options: NegotiateCredentialOfferOptions
    ) async throws -> (CredentialExchangeRecord, ProposeCredentialMessageV2) {
        fatalError("Not implemented")
    }

    // MARK: - Request

    public func createRequest(
        options: CreateCredentialRequestOptions
    ) async throws -> (CredentialExchangeRecord, RequestCredentialMessageV2) {
        fatalError("Not implemented")
    }

    public func processRequest(_ messageContext: InboundMessageContext) async throws -> CredentialExchangeRecord {
        processRequestCalled = true
        return CredentialExchangeRecordBuilder()
            .setId("cred-1")
            .setState(.RequestReceived)
            .setProtocolVersion("2.0")
            .setRole(.issuer)
            .build()
    }

    public func acceptRequest(
        options: AcceptRequestOptionsV2
    ) async throws -> (CredentialExchangeRecord, IssueCredentialMessageV2) {

        acceptRequestCalled = true

        let issue = IssueCredentialMessageV2Builder()
            .withThreadId(options.credentialExchangeRecord.threadId)
            .withAnoncredsCredential()
            .withPleaseAck()
            .build()

        return (options.credentialExchangeRecord, issue)
    }

    // MARK: - Credential

    public func processCredential(
        _ messageContext: InboundMessageContext
    ) async throws -> CredentialExchangeRecord {
        processCredentialCalled = true
        return CredentialExchangeRecordBuilder()
            .setId("cred-id-123")
            .setState(.CredentialReceived)
            .setProtocolVersion("2.0")
            .setRole(.holder)
            .build()
    }

    public func acceptCredential(
        _ record: CredentialExchangeRecord
    ) async throws -> (CredentialExchangeRecord, CredentialAckMessageV2) {
        acceptCredentialCalled = true

        let ack = CredentialAckMessageV2(
            threadId: record.threadId,
            status: .OK
        )

        return (record, ack)
    }
    
    // MARK: - Problem Report / Decline

    public func createProblemReport(
        options: CreateCredentialProblemReportOptions
    ) async throws -> (CredentialExchangeRecord, CredentialProblemReportMessageV2) {
        fatalError("Not implemented")
    }

    public func declineOffer(
        credentialRecord: CredentialExchangeRecord,
        options: DeclineCredentialOfferOptions
    ) async throws -> CredentialExchangeRecord {
        fatalError("Not implemented")
    }

    public func sendProblemReport(
        _ options: SendCredentialProblemReportOptions
    ) async throws -> CredentialExchangeRecord {
        fatalError("Not implemented")
    }

    // MARK: - Auto Accept

    public func shouldAutoRespondToProposal(
        credentialRecord: CredentialExchangeRecord,
        messageContext: InboundMessageContext
    ) async throws -> Bool {
        shouldAutoRespondCalled = true
        return autoRespond
    }

    public func shouldAutoRespondToOffer(
        credentialRecord: CredentialExchangeRecord,
        messageContext: InboundMessageContext
    ) async throws -> Bool {
        shouldAutoRespondToOfferCalled = true
        return shouldAutoRespondToOfferResult
    }

    public func shouldAutoRespondToRequest(
        credentialRecord: CredentialExchangeRecord,
        messageContext: InboundMessageContext
    ) async throws -> Bool {
        shouldAutoRespondToRequestCalled = true
        return shouldAutoRespondToRequestResult
    }

    public func shouldAutoRespondToCredential(
        credentialRecord: CredentialExchangeRecord,
        messageContext: InboundMessageContext
    ) async throws -> Bool {
        shouldAutoRespondCalled = true
        return shouldAutoRespondResult
    }

    // MARK: - Find Messages

    public func findProposalMessage(
        credentialExchangeId: String
    ) async -> ProposeCredentialMessageV2? {
        fatalError("Not implemented")
    }

    public func findRequestMessage(
        credentialExchangeId: String
    ) async -> RequestCredentialMessageV2? {
        return nil
    }

    public func findOfferMessage(
        credentialExchangeId: String
    ) async -> OfferCredentialMessageV2? {
        return OfferCredentialMessageV2Builder()
            .withAnoncredsOffer()
            .build()
    }
    
//    func findMessage<T: Decodable>(
//        credentialExchangeId: String,
//        messageType: String
//    ) async -> T?{
//        fatalError("Not implemented")
//    }
}
