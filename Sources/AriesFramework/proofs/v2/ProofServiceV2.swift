
import Foundation
import AnyCodable
import os
import CollectionConcurrencyKit
import Anoncreds

public class ProofServiceV2 {
    let logger = Logger(subsystem: "AriesFramework", category: "ProofServiceV2")
        
    private let agent: Agent
    private let proofRepository: ProofRepository
    private let historyService: HistoryService
    private let didCommMessageRepository: DidCommMessageRepository
    private let proofFormats: [any ProofFormatService]
    private let proofFormatCoordinator: ProofFormatCoordinator
    private let common: CommonFunctions
    
    private let createRequestProofProcessor: CreateRequestProofProcessor
    private let proofRequestProcessor: ProofRequestProcessor
    private let acceptProofRequestProcessor: AcceptProofRequestProcessor
    private let ackProofProcessor: AckProofProcessor
    private let createProposalProofProcessor: CreateProposalProofProcessor
    private let processProposalProofProcessor: ProcessProposalProofProcessor
    private let acceptProposalProofProcessor: AcceptProposalProofProcessor
    private let negotiateProposalProofProcessor: NegotiateProposalProofProcessor
    private let processPresentationProofProcessor: ProcessPresentationProofProcessor
    private let acceptPresentationProofProcessor : AcceptPresentationProofProcessor
    private let negotiateProofRequestProcessor : NegotiateProofRequestProcessor
    
    private let requestedCredentialsForProofRequestProcessor : RequestedCredentialsForProofRequestProcessor

    public init(agent: Agent) {
        self.agent = agent
        self.proofFormats = [
            AnoncredsProofFormatService(agent: agent)
        ]
        self.historyService = HistoryService(historyRepository: agent.historyRepository)
        self.common = CommonFunctions(agent: agent, proofFormats: proofFormats)
        self.proofRepository = agent.proofRepository
        self.didCommMessageRepository = agent.didCommMessageRepository
        self.proofFormatCoordinator = ProofFormatCoordinator(agent: agent,formatServices: proofFormats)
        
        self.proofRequestProcessor = ProofRequestProcessor(agent: agent,proofFormatCoordinator: proofFormatCoordinator,proofRepository: proofRepository,historyService: historyService,common: common)
        self.acceptProofRequestProcessor = AcceptProofRequestProcessor(agent: agent,proofFormatCoordinator: proofFormatCoordinator,proofRepository: proofRepository,historyService: historyService,common: common)
        self.ackProofProcessor = AckProofProcessor(agent: agent,proofRepository: proofRepository,common: common)
        self.createRequestProofProcessor = CreateRequestProofProcessor(agent: agent,proofFormatCoordinator: proofFormatCoordinator,common: common)
        self.createProposalProofProcessor = CreateProposalProofProcessor(agent: agent,proofRepository: proofRepository,proofFormatCoordinator: proofFormatCoordinator,common: common)
        self.processProposalProofProcessor = ProcessProposalProofProcessor(agent: agent, proofRepository: proofRepository, didCommMessageRepository: didCommMessageRepository, proofFormatCoordinator: proofFormatCoordinator, common: common)
        self.acceptProposalProofProcessor = AcceptProposalProofProcessor(agent: agent, didCommMessageRepository: didCommMessageRepository, proofFormatCoordinator: proofFormatCoordinator, common: common)
        self.negotiateProposalProofProcessor = NegotiateProposalProofProcessor(agent: agent, proofFormatCoordinator: proofFormatCoordinator, common: common)
        self.processPresentationProofProcessor = ProcessPresentationProofProcessor(agent: agent, proofRepository: proofRepository, proofFormatCoordinator: proofFormatCoordinator, common: common)
        self.acceptPresentationProofProcessor = AcceptPresentationProofProcessor(agent: agent, common: common)
        self.negotiateProofRequestProcessor = NegotiateProofRequestProcessor(proofFormatCoordinator: proofFormatCoordinator, common: common)
        self.requestedCredentialsForProofRequestProcessor = RequestedCredentialsForProofRequestProcessor(agent: agent, common: common)
    }
    
    func processRequest(messageContext: InboundMessageContext? = nil, requestMessage:RequestPresentationMessageV2? = nil) async throws -> ProofExchangeRecord {
        try await proofRequestProcessor.process(messageContext: messageContext, requestMessage: requestMessage)
    }
    
    public func acceptRequest(params: AcceptProofRequestOptions) async throws -> (PresentationMessageV2, ProofExchangeRecord) {
        try await acceptProofRequestProcessor.acceptRequest(params: params)
    }
    
    public func processAck(messageContext: InboundMessageContext) async throws -> ProofExchangeRecord {
        try await ackProofProcessor.process(messageContext: messageContext)
    }
    
    public static func generateProofRequestNonce() throws -> String {
        return try Verifier().generateNonce()
    }
    
    
    public func createRequest(params: CreateProofRequestOptions) async throws -> (RequestPresentationMessageV2, ProofExchangeRecord) {
        try await createRequestProofProcessor.createRequest(params: params)
    }
    

    func createProposal(
        options: CreateProposalProofOptionsV2
    ) async throws -> (ProposePresentationMessageV2, ProofExchangeRecord) {
        try await createProposalProofProcessor.createProposal(options: options)
    }
    
    public func processProposal(messageContext: InboundMessageContext) async throws -> ProofExchangeRecord {
        try await processProposalProofProcessor.process(messageContext: messageContext)
    }

    
    func acceptProposal(params: AcceptProofProposalServiceParams) async throws -> (RequestPresentationMessageV2, ProofExchangeRecord) {
        try await acceptProposalProofProcessor.acceptProposal(params: params)
    }
    
    func negotiateProposal(
        params: NegotiateProofProposalOptions
    ) async throws -> (RequestPresentationMessageV2, ProofExchangeRecord) {
        try await negotiateProposalProofProcessor.negotiateProposal(params: params)
    }

    
    func negotiateRequest(params: NegotiateProofRequestParams) async throws -> (ProposePresentationMessageV2, ProofExchangeRecord) {
        try await negotiateProofRequestProcessor.negotiateRequest(params: params)
    }
    
    func processPresentation(messageContext: InboundMessageContext) async throws -> ProofExchangeRecord {
        try await processPresentationProofProcessor.process(messageContext: messageContext)
    }
    
    func processPresentationOffline(message: PresentationMessageV2) async throws -> ProofExchangeRecord? {
        try await processPresentationProofProcessor.processOffline(message: message)
    }
    
    public func processOfflineAck(proofRecord: ProofExchangeRecord) async throws -> (PresentationAckMessageV2, ProofExchangeRecord) {
        var record = proofRecord
        let ackMessage = PresentationAckMessageV2(
            threadId: proofRecord.threadId,
            status: AckStatus.OK)
       
        try await common.updateState(proofRecord: &record, newState: ProofState.Done)

        return (ackMessage, record)
   }
    
    public func acceptPresentation(proofRecord: inout ProofExchangeRecord) async throws -> (PresentationAckMessageV2, ProofExchangeRecord) {
        try await acceptPresentationProofProcessor.acceptPresentation(proofRecord: &proofRecord)
    }
    
    
    public func createAck(proofRecord: inout ProofExchangeRecord) async throws -> (PresentationAckMessageV2, ProofExchangeRecord) {
        try proofRecord.assertState(.PresentationReceived)
        
        let ackMessage = PresentationAckMessageV2(
            threadId: proofRecord.threadId,
            status: .OK
        )
        logDebug("proof record done: \(ackMessage)")
        try await common.updateState(proofRecord: &proofRecord, newState: .Done)

        return (ackMessage, proofRecord)
    }
    
   
    func createPresentationDeclinedProblemReport(
        proofRecord: inout ProofExchangeRecord
    ) async throws -> (PresentationProblemReportMessageV2, ProofExchangeRecord) {
        
        try proofRecord.assertState(.RequestReceived)

        let problemMessage = PresentationProblemReportMessageV2(threadId: proofRecord.threadId, proofRecord: proofRecord)
        try await common.updateState(proofRecord: &proofRecord, newState: .Declined)

        return (problemMessage, proofRecord)
    }
    
    public func autoSelectCredentialsForProofRequest(
        retrievedCredentials: RetrievedCredentialsAnonCreds
    ) async throws -> RequestedCredentialsAnoncreds {
        
        var requestedCredentials = RequestedCredentialsAnoncreds()
        
        for (attributeName, attributeArray) in retrievedCredentials.requestedAttributes {
            logDebug("attr name: \(attributeName)")
            guard !attributeArray.isEmpty else {
                throw NSError(domain: "AutoSelect", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Cannot find credentials for attribute '\(attributeName)'."
                ])
            }

            let nonRevokedAttributes = attributeArray.filter { $0.revoked != true }

            guard !nonRevokedAttributes.isEmpty else {
                throw NSError(domain: "AutoSelect", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "Cannot find non-revoked credentials for attribute '\(attributeName)'."
                ])
            }

            requestedCredentials.requestedAttributes[attributeName] = nonRevokedAttributes[0]
        }

        for (predicateName, predicateArray) in retrievedCredentials.requestedPredicates {
            guard !predicateArray.isEmpty else {
                throw NSError(domain: "AutoSelect", code: 3, userInfo: [
                    NSLocalizedDescriptionKey: "Cannot find credentials for predicate '\(predicateName)'."
                ])
            }

            let nonRevokedPredicates = predicateArray.filter { $0.revoked != true }

            guard !nonRevokedPredicates.isEmpty else {
                throw NSError(domain: "AutoSelect", code: 4, userInfo: [
                    NSLocalizedDescriptionKey: "Cannot find non-revoked credentials for predicate '\(predicateName)'."
                ])
            }

            requestedCredentials.requestedPredicates[predicateName] = nonRevokedPredicates[0]
        }

        return requestedCredentials
    }
    
    public func getRequestedCredentialsForProofRequest(
        anoncredsProofRequest: AnonCredsProofRequest,
        credentialW3cId: String? = nil
    ) async throws -> RetrievedCredentialsAnonCreds {
        try await requestedCredentialsForProofRequestProcessor.getRequestedCredentials(for: anoncredsProofRequest, credentialW3cId: credentialW3cId)
    }
    
    public func createProof(proofRequest: String, requestedCredentials: RequestedCredentialsAnoncreds) async throws -> Data {
        var anoncredsCreds = [RequestedCredential]()
        let credentialIds = requestedCredentials.getCredentialIdentifiers()
        var schemaIds = Set<String>()
        var credentialDefinitionIds = Set<String>()
        
        try await credentialIds.concurrentForEach { [self] (credId) in
            let credentialRecord = try await agent.w3cCredentialRepository.getById(credId)
            let credential = try W3cUtils.getCredentialUniffiByW3cCredentialRecord(credentialRecord)
            schemaIds.insert(credential.schemaId())
            credentialDefinitionIds.insert(credential.credDefId())

            var requestedAttributes = [String: Bool]()
            var requestedPredicates = [String]()
            var timestamp: UInt64?
            
            requestedCredentials.requestedAttributes.forEach { (referent, attr) in
                if attr.credentialId == credId {
                    requestedAttributes[referent] = attr.revealed
                    if attr.timestamp != nil {
                        timestamp = max(UInt64(attr.timestamp!), timestamp ?? 0)
                    }
                }
            }
            requestedCredentials.requestedPredicates.forEach { (referent, pred) in
                if pred.credentialId == credId {
                    requestedPredicates.append(referent)
                    if pred.timestamp != nil {
                        timestamp = max(UInt64(pred.timestamp!), timestamp ?? 0)
                    }
                }
            }
            
            var revocationState: CredentialRevocationState?
            if timestamp != nil {
                revocationState = try await agent.revocationService.createRevocationState(credential: credential, timestamp: Int(timestamp!))
            }
            
            let requestedCredential = RequestedCredential(
                cred: credential,
                timestamp: timestamp,
                revState: revocationState,
                requestedAttributes: requestedAttributes,
                requestedPredicates: requestedPredicates)
            anoncredsCreds.append(requestedCredential)
        }
        
        let schemas = try await ProofUtils.getSchemasUniffi(agent: agent, schemaIds: schemaIds)
        let credentialDefinitions = try await ProofUtils.getCredentialDefinitionsUniffi(agent: agent, credentialDefinitionIds: credentialDefinitionIds)
        let linkSecret = try await agent.anoncredsService.getLinkSecret(id: agent.wallet.linkSecretId!)
        
        do {
            let presentation = try Prover().createPresentation(
                presReq: PresentationRequest(json: proofRequest),
                requestedCredentials: anoncredsCreds,
                selfAttestedAttributes: [:],
                linkSecret: linkSecret,
                schemas: schemas,
                credDefs: credentialDefinitions
            )
            return presentation.toJson().data(using: .utf8)!
        } catch {
            throw AriesFrameworkError.frameworkError("Cannot create a proof using the provided credentials. \(error)")
        }
    }
}
