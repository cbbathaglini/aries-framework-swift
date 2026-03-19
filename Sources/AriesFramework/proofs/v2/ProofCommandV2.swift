//
//  ProofCommandV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

import Foundation
import AnyCodable
import os
import anoncreds_uniffi

public class ProofCommandV2 {
    let agent: Agent
    let historyService: HistoryService
    let logger = Logger(subsystem: "AriesFramework", category: "ProofCommandV2")
    
    init(agent: Agent, dispatcher: DispatcherProtocol) {
        self.agent = agent
        self.historyService = HistoryService(historyRepository: agent.historyRepository)
        registerHandlers(dispatcher: dispatcher)
        registerMessages()
    }
    
    private func registerHandlers(dispatcher: DispatcherProtocol) {
        dispatcher.registerHandler(handler: RequestPresentationHandlerV2(agent: agent))
        dispatcher.registerHandler(handler: PresentationHandlerV2(agent: agent))
        dispatcher.registerHandler(handler: PresentationAckHandlerV2(agent: agent))
    }
    
    private func registerMessages() {
        MessageSerializer.registerMessage(type: PresentationAckMessageV2.type, clazz: PresentationAckMessageV2.self)
        MessageSerializer.registerMessage(type: PresentationMessageV2.type, clazz: PresentationMessageV2.self)
        MessageSerializer.registerMessage(type: PresentationProblemReportMessageV2.type, clazz: PresentationProblemReportMessageV2.self)
        MessageSerializer.registerMessage(type: ProposePresentationMessageV2.type, clazz: ProposePresentationMessageV2.self)
        MessageSerializer.registerMessage(type: RequestPresentationMessageV2.type, clazz: RequestPresentationMessageV2.self)
    }
    
    
    public func requestProof(
        connectionId: String,
        proofRequest: AnonCredsProofRequest,
        formats: [ProofFormatSpec] = [],
        autoAcceptProof: AutoAcceptProof? = nil,
        willConfirm: Bool? = nil,
        comment: String? = nil
    ) async throws -> (ProofExchangeRecord, VerifierRecord) {
        
        let connection = try await agent.connectionRepository.getById(connectionId)
        
        guard let format = formats.first?.attachmentId else {
            throw CredoError("Proof format not informed")
        }
        
        let proofFormats: [String: AnyCodable] = ProofUtils.getProofFormats(
            proofRequest: proofRequest,
            format: format
        )
        logDebug("proof formats: \(proofFormats)")
        
        let (message, record) = try await agent.proofServiceV2.createRequest(
            params: CreateProofRequestOptions(
                proofRequest: proofRequest,
                formats: formats,
                proofFormats: proofFormats,
                connectionRecord: connection,
                comment: comment,
                autoAcceptProof: autoAcceptProof ?? .never,
                willConfirm: willConfirm
            )
        )
        
        let verifierRecord = VerifierRecord(
            proofRequest: proofRequest,
            requestMessage: message,
            globalThreadId: record.threadId,
            offline: false,
        )

        try await agent.verifierRepository.save(verifierRecord)
        
        try await agent.messageSender.send(message: OutboundMessage(payload: message, connection: connection))
        
        return (record, verifierRecord)
    }
    
    public func processRequest(requestMessage: RequestPresentationMessageV2, chosenCredentialId: String?=nil) async throws -> ProofExchangeRecord
    {
        return try await agent.proofServiceV2.processRequest(requestMessage: requestMessage)
    }
    
    public func createPresentation(record: ProofExchangeRecord, chosenCredentialId:String?=nil) async throws -> (ProofExchangeRecord, PresentationMessageV2){
        
        
        var chosenCredential: CredentialExchangeRecord?
        if let chosenCredentialId = chosenCredentialId {
            chosenCredential = try? await agent.credentialExchangeRepository.getById(chosenCredentialId)
        }
        
        let retrievedCredentials = try await ProofUtils.getRequestedCredentialsForProofRequest(
            proofRecordId: record.id,
            agent: agent,
            credentialW3cId: chosenCredential?.w3cCredentialId
        )

        var requestedCredentials: RequestedCredentialsAnoncreds = try await agent.proofServiceV2.autoSelectCredentialsForProofRequest(
            retrievedCredentials: retrievedCredentials
        )
                

        let params = AcceptProofRequestOptions(
            proofRecord: record,
            proofFormats: record.formats ?? [],
            requestedCredentials: requestedCredentials.toMap(),
            chosenCredentialId: chosenCredential?.w3cCredentialId
        )

        let (message, _) = try await agent.proofServiceV2.acceptRequest(params: params)
        
        return (record, message)
    }
    
    public func processOfflineAck(proofRecord: ProofExchangeRecord) async throws {
        try await agent.proofServiceV2.processOfflineAck(proofRecord: proofRecord)
    }
    
    public func requestProofOffline(
        proofRequest: AnonCredsProofRequest,
        formats: [ProofFormatSpec] = [],
        autoAcceptProof: AutoAcceptProof? = nil,
        willConfirm: Bool? = nil,
        comment: String? = nil
    ) async throws -> (ProofExchangeRecord, VerifierRecord) {
        
        guard let format = formats.first?.attachmentId else {
            throw CredoError("Proof format not informed")
        }
        
        let proofFormats: [String: AnyCodable] = ProofUtils.getProofFormats(
            proofRequest: proofRequest,
            format: format
        )
        logDebug("proof formats: \(proofFormats)")
        
        let (message, record) = try await agent.proofServiceV2.createRequest(
            params: CreateProofRequestOptions(
                proofRequest: proofRequest,
                formats: formats,
                proofFormats: proofFormats,
                connectionRecord: nil,
                comment: comment,
                autoAcceptProof: autoAcceptProof ?? .never,
                willConfirm: willConfirm
            )
        )
        
        let verifierRecord = VerifierRecord(
            proofRequest: proofRequest,
            requestMessage: message,
            globalThreadId: record.threadId,
            offline: true
        )
        try await agent.verifierRepository.save(verifierRecord)
    
        return (record,verifierRecord)
    }
    
    public func processPresentationOffline(presentationMessage: String) async throws -> (ProofExchangeRecord?, Bool){
        guard let message = MessageSerializer.decodeFromString(presentationMessage) as? PresentationMessageV2 else {
            throw CredoError("Failed to decode PresentationMessageV2")
        }
    
        let proofRecord = try await agent.proofServiceV2.processPresentationOffline(message: message)
        let resultOfVerification = proofRecord?.isVerified ?? false
        return (proofRecord, resultOfVerification)
        
    }
    
    public func acceptRequest(
        proofRecordId: String,
        chosenCredentialId: String? = nil,
        comment: String? = nil
    ) async throws -> ProofExchangeRecord {
        
        var chosenCredential: CredentialExchangeRecord?
        if let chosenCredentialId = chosenCredentialId {
            chosenCredential = try? await agent.credentialExchangeRepository.getById(chosenCredentialId)
        }
        
        let retrievedCredentials = try await ProofUtils.getRequestedCredentialsForProofRequest(
            proofRecordId: proofRecordId,
            agent: agent,
            credentialW3cId: chosenCredential?.w3cCredentialId
        )
        
        var requestedCredentials = try await agent.proofServiceV2.autoSelectCredentialsForProofRequest(
            retrievedCredentials: retrievedCredentials
        )
            

        try await agent.didCommMessageRepository.getAgentMessage(
            associatedRecordId: proofRecordId,
            messageType: RequestPresentationMessageV2.type
        )

        let record = try await agent.proofRepository.getById(proofRecordId)
        
        guard let formats = record.formats else {
            throw CredoError("No formats found in proof record")
        }

        let requestedCredentialsMap: [String: AnyCodable] = requestedCredentials.toMap()

        let sanitized = sanitizeForJSON(requestedCredentialsMap)

        if let dict = sanitized as? [String: Any],
           JSONSerialization.isValidJSONObject(dict),
           let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            logDebug("✅ Requested Credentials JSON:\n\(jsonString)")
        } else {
            logDebug("⚠️ JSON invalid (type not supported)")
        }

        guard let dict = sanitized as? [String: Any] else {
            throw CredoError("Error converting requestedCredentials to JSON dictionary")
        }

        let reconverted: [String: AnyCodable] = dict.reduce(into: [:]) { acc, pair in
            acc[pair.key] = AnyCodable(pair.value)
        }

        let params = AcceptProofRequestOptions(
            proofRecord: record,
            proofFormats: formats,
            comment: comment,
            requestedCredentials: reconverted,
            chosenCredentialId: chosenCredential?.w3cCredentialId
        )

        let (presentationMessage, updatedRecord) = try await agent.proofServiceV2.acceptRequest(params: params)
        
        let connection = try await agent.connectionRepository.getById(record.connectionId)
        requestedCredentials.normalizeAllAttributes()

        try await historyService.save(
            historyType: HistoryType.proofRequestAccepted,
            connection: connection,
            associatedRecordId: proofRecordId,
            proofRequestedCredentialsAnoncreds: requestedCredentials
        )

        try await agent.messageSender.send(
            message: OutboundMessage(payload: presentationMessage, connection: connection)
        )

        return updatedRecord
    }
    
    func sanitizeForJSON(_ value: Any) -> Any {
        switch value {
        case let anyCodable as AnyCodable:
            return sanitizeForJSON(anyCodable.value)

        case let dict as [String: Any]:
            return dict.reduce(into: [String: Any]()) { acc, pair in
                let sanitized = sanitizeForJSON(pair.value)
                if !(sanitized is NSNull) {
                    acc[pair.key] = sanitized
                }
            }

        case let array as [Any]:
            return array.compactMap { item in
                let sanitized = sanitizeForJSON(item)
                return (sanitized is NSNull) ? nil : sanitized
            }

        case let date as Date:
            return ISO8601DateFormatter().string(from: date)

        case Optional<Any>.none:
            return NSNull()

        default:
            if JSONSerialization.isValidJSONObject([ "v": value ]) {
                return value
            } else {
                return "\(value)"
            }
        }
    }
    
    func unwrapAnyCodable(_ value: Any) -> Any {
        if let anyCodable = value as? AnyCodable {
            return unwrapAnyCodable(anyCodable.value)
        } else if let dict = value as? [String: Any] {
            return dict.mapValues { unwrapAnyCodable($0) }
        } else if let array = value as? [Any] {
            return array.map { unwrapAnyCodable($0) }
        } else {
            return value
        }
    }
    
    public func declineRequest(proofRecordId: String) async throws -> ProofExchangeRecord {
        
        var record = try await agent.proofRepository.getById(proofRecordId)
        let (message, updatedRecord) = try await agent.proofServiceV2.createPresentationDeclinedProblemReport(proofRecord: &record)
        let connection = try await agent.connectionRepository.getById(record.connectionId)
        
        let outboundMessage = OutboundMessage(payload: message, connection: connection)
        try await agent.messageSender.send(message:outboundMessage)

        try await historyService.save(historyType: HistoryType.proofRequestDeclined,
                                connection: connection,
                                associatedRecordId: proofRecordId
        )

        return updatedRecord
    }
}
