//
//  RevocationNotificationService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/25.
//

import os
import Foundation

public class RevocationNotificationServiceV2 {
    let agent: Agent
    let dispatcher: Dispatcher
    private let logger = Logger(subsystem: "AriesFramework", category: "RevocationNotificationServiceV2")
    
    private var credentialExchangeRepository: CredentialExchangeRepository {
        return agent.credentialExchangeRepository
    }
    
    init(agent: Agent, dispatcher: Dispatcher) {
        self.agent = agent
        self.dispatcher = dispatcher
        registerMessageHandlers(dispatcher: dispatcher)
        registerMessages()
    }
    
    func createRevocationNotification(options: RevocationNotificationMessageV2Options) -> [String: RevocationNotificationMessageV2] {
            let message = RevocationNotificationMessageV2(
                revocationFormat: options.revocationFormat,
                credentialId: options.credentialId,
                comment: options.comment,
                pleaseAck:options.pleaseAck
            )
        
            return ["message": message]
        }
    
    public func processRevocationNotification(messageContext: InboundMessageContext) async throws {
        logDebug("Processing revocation notification v2")

        let revocationMessage = try JSONDecoder().decode(
            RevocationNotificationMessageV2.self,
            from: Data(messageContext.plaintextMessage.utf8)
        )

        let credentialId = revocationMessage.credentialId

        guard [RevocationIdentifier.v2IndyRevocationFormat, RevocationIdentifier.v2AnonCredsRevocationFormat]
            .contains(revocationMessage.revocationFormat) else {
            throw CredoError(
                "Unknown revocation format: \(revocationMessage.revocationFormat). Supported formats are indy-anoncreds and anoncreds"
            )
        }


        let regexes = [
            RevocationIdentifier.v2IndyRevocationIdentifierRegex,
            RevocationIdentifier.v2AnonCredsRevocationIdentifierRegex
        ]

        let credentialIdGroups: [String]? = regexes
            .compactMap { regex in
                regex.firstMatch(in: credentialId, range: NSRange(location: 0, length: credentialId.utf16.count))
                    .map { extractGroups(from: $0, in: credentialId) }
            }
            .first

        
        let anonCredsRevocationRegistryId: String?
        let anonCredsCredentialRevocationId: String?

        if let groups = credentialIdGroups, groups.count >= 3 {
            anonCredsRevocationRegistryId = groups[1]
            anonCredsCredentialRevocationId = groups[2]
            logDebug("✅ Revocation ID parsed successfully: \(anonCredsRevocationRegistryId!) :: \(anonCredsCredentialRevocationId!)")
        } else {
            anonCredsRevocationRegistryId = nil
            anonCredsCredentialRevocationId = nil
            logDebug("""
            ⚠️ Invalid revocation notification credentialId format:
            \(credentialId)
            Expected format: "<revocation_registry_id>::<credential_revocation_id>"
            """)
        }
        
        if anonCredsRevocationRegistryId == nil || anonCredsCredentialRevocationId == nil{
            throw CredoError("""
            ⚠️ Invalid revocation notification credentialId format:
            \(credentialId)
            Expected format: "<revocation_registry_id>::<credential_revocation_id>"
            """)
        }

        let anoncredsType: Bool = {
            guard !credentialId.isEmpty else { return false }
            return RevocationIdentifier.v2AnonCredsRevocationIdentifierRegex.firstMatch(
                in: credentialId,
                options: [],
                range: NSRange(location: 0, length: credentialId.utf16.count)
            ) != nil
        }()
        
        let comment = revocationMessage.comment
        let connection = try messageContext.assertReadyConnection()

        try await processRevocationNotification(
            revocationRegistryId: anonCredsRevocationRegistryId!,
            credentialRevocationId: anonCredsCredentialRevocationId!,
            connection: connection,
            comment: comment,
            anoncredsType: anoncredsType
        )
    }
    
    
    private func extractGroups(from match: NSTextCheckingResult, in originalString: String) -> [String] {
        var groups: [String] = []
        
        for i in 0..<match.numberOfRanges {
            let range = match.range(at: i)
            
            if range.location != NSNotFound, let substringRange = Range(range, in: originalString) {
                groups.append(String(originalString[substringRange]))
            }
        }
        
        return groups
    }

        private func processRevocationNotification(
            revocationRegistryId: String,
            credentialRevocationId: String,
            connection: ConnectionRecord,
            comment: String? = nil,
            threadId: String = UUID().uuidString,
            anoncredsType: Bool = false
        ) async throws {
            var credentialRecord: CredentialExchangeRecord?
            var errorHappens : Bool = false

            do {
                credentialRecord = try await credentialExchangeRepository.getByCredentialRevocationIdAndRevocationRegistryId(
                    credentialRevocationId: credentialRevocationId,
                    revocationRegistryId: revocationRegistryId,
                    anoncredsType: anoncredsType
                )
            } catch {
                logDebug("Not found credential record by CredentialRevocationId and RevocationRegistryId")
                errorHappens = true
            }

            if errorHappens {
                credentialRecord = try await credentialExchangeRepository.getByCredentialRevocationId(credentialRevocationId)
            }

            guard var record = credentialRecord else {
                throw CredoError("Not found credential record by CredentialRevocationId and RevocationRegistryId")
            }

            record.revocationNotification = RevocationNotification(comment: comment, revocationDate: Date())
            record.state = CredentialState.Revoked
            try await agent.credentialExchangeRepository.update(record)
            logDebug("Emitting RevocationNotificationReceivedEventV2")

            agent.agentDelegate?.onRevocationNotificationV2Changed(credentialExchangeRecord: record)
        
        }

        private func registerMessageHandlers(dispatcher: Dispatcher) {
            dispatcher.registerHandler(handler: RevocationNotificationHandlerV2(agent: agent))
        }

        private func registerMessages() {
            MessageSerializer.registerMessage(type: RevocationNotificationMessageV2.type, clazz: RevocationNotificationMessageV2.self)
        }
}
