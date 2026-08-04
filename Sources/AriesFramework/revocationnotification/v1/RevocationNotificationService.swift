//
//  RevocationNotificationService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/25.
//

import os
import Foundation

public class RevocationNotificationService {
    let agent: Agent
    let dispatcher: Dispatcher
    private let logger = Logger(subsystem: "AriesFramework", category: "RevocationNotificationService")
    
    private var credentialRepository: CredentialRepository {
        return agent.credentialRepository
    }
    
    init(agent: Agent, dispatcher: Dispatcher) {
        self.agent = agent
        self.dispatcher = dispatcher
        registerMessageHandlers(dispatcher: dispatcher)
        registerMessages()
    }
    
    func createRevocationNotification(options: RevocationNotificationMessageV1Options) -> [String: RevocationNotificationMessageV1] {
            let message = RevocationNotificationMessageV1(
                issueThread: options.issueThread,
                comment: options.comment,
                pleaseAck: options.pleaseAck
            )
            return ["message": message]
        }

        func processRevocationNotification(messageContext: InboundMessageContext) async throws {
            logDebug("processRevocationNotification init")

            logDebug("revocationMessage: \(String(describing: messageContext.message))")
            let revocationMessage = try JSONDecoder().decode(RevocationNotificationMessageV1.self, from: Data(messageContext.plaintextMessage.utf8))
            
            logDebug("revocationMessage: \(String(describing: revocationMessage))")
            
            let threadId = revocationMessage.issueThread
            guard threadId.hasPrefix("indy::") else {
                throw IllegalArgumentError(message: "Invalid threadId format: \(threadId). Expected format: indy::<revocation_registry_id>::<credential_revocation_id>")
            }

           
            guard let regex = RevocationIdentifier.v1ThreadRegex.firstMatch(
                in: threadId,
                options: [],
                range: NSRange(location: 0, length: threadId.utf16.count)
            ) else {
                throw CredoError("Incorrect revocation notification threadId format: \(threadId) does not match\n" +
                                 "\"indy::<revocation_registry_id>::<credential_revocation_id>\"")
            }

            // Extracting capture groups
            var threadIdGroups: [String] = []
            for i in 0..<regex.numberOfRanges {
                let range = regex.range(at: i)
                if range.location != NSNotFound, let substringRange = Range(range, in: threadId) {
                    threadIdGroups.append(String(threadId[substringRange]))
                }
            }

            guard threadIdGroups.count >= 3 else {
                throw CredoError("Incorrect revocation notification threadId format: \(threadId) does not match\n" +
                                 "\"indy::<revocation_registry_id>::<credential_revocation_id>\"")
            }

            let anonCredsRevocationRegistryId = threadIdGroups[2]
            let anonCredsCredentialRevocationId = threadIdGroups[3]

            let comment = revocationMessage.comment
            let connection = try messageContext.assertReadyConnection()

            try await processRevocationNotification(
                revocationRegistryId: anonCredsRevocationRegistryId,
                credentialRevocationId: anonCredsCredentialRevocationId,
                connection: connection,
                comment: comment,
                threadId: threadId
            )
        }

        private func processRevocationNotification(
            revocationRegistryId: String,
            credentialRevocationId: String,
            connection: ConnectionRecord,
            comment: String? = nil,
            threadId: String
        ) async throws {
            var credentialRecord: CredentialRecord?
            var errorHappens : Bool = false

            do {
                credentialRecord = try await credentialRepository.getByCredentialRevocationIdAndRevocationRegistryId(
                    credentialRevocationId,
                    revocationRegistryId
                )
            } catch {
                logger.warning("Not found credential record by CredentialRevocationId and RevocationRegistryId")
                errorHappens = true
            }

            if errorHappens {
                credentialRecord = try await credentialRepository.getByCredentialRevocationId(credentialRevocationId)
            }

            guard var record = credentialRecord else {
                throw CredoError("Not found credential record by CredentialRevocationId and RevocationRegistryId")
            }

            record.revocationNotification = RevocationNotification(comment: comment)
            try await agent.credentialRepository.update(record)

            logger.trace("Emitting RevocationNotificationReceivedEvent")

            let credentialExchangeRecord = record.toCredentialExchangeRecord(
                connectionId: connection.id,
                threadId: threadId,
                state: .Revoked,
                protocolVersion: "v1",
                role: .holder
            )

            agent.agentDelegate?.onRevocationNotificationChanged(credentialExchangeRecord: credentialExchangeRecord)
        
        }

        private func registerMessageHandlers(dispatcher: Dispatcher) {
            dispatcher.registerHandler(handler: RevocationNotificationHandlerV1(agent: agent))
        }

        private func registerMessages() {
            MessageSerializer.registerMessage(type: RevocationNotificationMessageV1.type, clazz: RevocationNotificationMessageV1.self)
        }
}
