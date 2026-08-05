//
//  RequestHandler.swift
//  wallet-app-ios
//

import SwiftUI
import AriesFramework

extension Data {
    func string() -> String {
        return String(decoding: self, as: UTF8.self)
    }
}

@MainActor
class CredentialHandler: ObservableObject, AgentDelegate {
    static let shared = CredentialHandler()

    private let notificationHandler = NotificationHandler.shared

    @Published var menu: MainMenu?
    var credentialRecordId = ""
    var proofRecordId = ""

    @Published var credentials: [CredentialExchangeRecord] = []

    private init() {}

    func refreshCredentials() {
        Task {
            guard let agent = agent else { return }
            let all = await agent.credentialExchangeRepository.getAll()
            await MainActor.run {
                self.credentials = all
            }
            print("✅ \(all.count) credentials loaded.")
        }
    }

    // MARK: - CREDENTIALS 1.0
    func onCredentialStateChanged(credentialRecord: CredentialExchangeRecord) {
        if credentialRecord.state == .OfferReceived {
            credentialRecordId = credentialRecord.id

            notificationHandler.addNotification(
                title: "New credential offer (1.0)",
                message: "ConnectionID: \(credentialRecord.connectionId ?? "")",
                type: .issueCredentialv1,
                credentialId: credentialRecord.id
            )

        } else if credentialRecord.state == .Done {
            notificationHandler.addNotification(
                title: "Credential received (1.0)",
                message: "ID: \(credentialRecord.id)",
                type: .issuedCredentialDetailv1,
                credentialId: credentialRecord.id
            )

            Task { @MainActor in self.menu = nil }
        }
    }

    // MARK: - CREDENTIALS 2.0
    func onCredentialStateV2Changed(credentialRecord: CredentialExchangeRecord) {
        switch credentialRecord.state {
        case .OfferReceived:
            Task { @MainActor in
                self.credentialRecordId = credentialRecord.id
                self.notificationHandler.addNotification(
                    title: "New credential offer (2.0)",
                    message: "ConnectionID: \(credentialRecord.connectionId ?? "")",
                    type: .issueCredentialv2,
                    credentialId: credentialRecord.id
                )
            }

        case .Done:
            Task { @MainActor in
                self.notificationHandler.addNotification(
                    title: "Credential 2.0 received",
                    message: "ID: \(credentialRecord.id)",
                    type: .issuedCredentialDetailv2,
                    credentialId: credentialRecord.id
                )
                self.menu = nil
            }

        default:
            break
        }
    }

    // MARK: - PROOFS 1.0
    func onProofStateChanged(proofRecord: ProofExchangeRecord) {
        switch proofRecord.state {
        case .RequestReceived:
            proofRecordId = proofRecord.id
            notificationHandler.addNotification(
                title: "Proof request received",
                message: "(1.0)",
                type: .acceptProofRequestv1
            )

        case .Done:
            notificationHandler.addNotification(
                title: "Proof completed",
                message: "(1.0)",
                type: .proofRequestv1
            )
            menu = nil

        case .PresentationReceived:
            notificationHandler.addNotification(
                title: "Proof presentation received",
                message: "Verified: \(proofRecord.isVerified ?? false)"
            )
            menu = nil

        case .PresentationSent:
            notificationHandler.addNotification(
                title: "Proof presentation sent",
                message: "(1.0)",
                type: .presentationProofv1
            )
            menu = nil

        default:
            break
        }
    }

    // MARK: - PROOFS 2.0
    func onProofStateChangedV2(proofRecord: ProofExchangeRecord) {
        Task { @MainActor in
            switch proofRecord.state {

            case .RequestReceived:
                var message = "Proof ID: \(proofRecord.id)"

                if let comment = proofRecord.comment, !comment.isEmpty {
                    message = "A proof has been requested by \(comment)"
                }

                notificationHandler.addNotification(
                    title: "A proof presentation has been requested",
                    message: message,
                    type: .acceptProofRequestv2,
                    proofRecordId: proofRecord.id,
                    presentationMessageId: proofRecord.presentationMessage?.id
                )

            case .Done:
                var effectiveVerified = proofRecord.isVerified

                if effectiveVerified == nil, let agent, !proofRecord.id.isEmpty {
                    do {
                        let stored = try await agent.proofRepository.getById(proofRecord.id)
                        effectiveVerified = stored.isVerified
                    } catch {
                        effectiveVerified = proofRecord.isVerified
                    }
                }

                let verifiedText = effectiveVerified.map { $0 ? "Yes" : "No" } ?? "Unknown"

                notificationHandler.addNotification(
                    title: "Proof completed",
                    message: "Proof ID: \(proofRecord.id) - verified? \(verifiedText)",
                    type: .proofDonev2,
                    proofRecordId: proofRecord.id
                )
                menu = nil

            case .PresentationReceived:
                receivePresentation(proofRecord: proofRecord)

                let verified = proofRecord.isVerified ?? false
                let text = verified ? "Yes" : "No"

                notificationHandler.addNotification(
                    title: "Proof received",
                    message: "Version 2.0 | Verified? \(text)",
                    proofRecordId: proofRecordId
                )
                menu = nil

            case .PresentationSent:
                notificationHandler.addNotification(
                    title: "Proof presentation sent",
                    message: "(2.0)",
                    type: .presentationProofv2,
                    proofRecordId: proofRecordId
                )
                menu = nil

            default:
                break
            }
        }
    }

    // MARK: - REVOCATION
    func onMediationStateChanged(mediationRecord: MediationRecord) {
        notificationHandler.addNotification(
            title: "Mediator \(mediationRecord.state.rawValue)",
            message: "ConnectionID: \(mediationRecord.connectionId)",
            type: .connection
        )
    }

    func onRevocationNotificationChanged(credentialExchangeRecord: CredentialExchangeRecord) {
        notificationHandler.addNotification(
            title: "Credential revoked",
            message: "(1.0)"
        )
    }

    func onRevocationNotificationV2Changed(credentialExchangeRecord: CredentialExchangeRecord) {
        print("🚨 Revocation notification V2 received for credential -> \(credentialExchangeRecord.id)")
        
        //agent?.credentialsV2.updateRevocation(credentialExchangeRecord.id)
        Task { @MainActor in
            notificationHandler.addNotification(
                title: "Credential \(credentialExchangeRecord.id) was revoked",
                message: "(2.0)",
                type: .revocationNotificationV2,
                credentialId: credentialExchangeRecord.id
            )
        }
    }

    // MARK: - BASIC MESSAGE
    func onBasicMessageChanged(record: BasicMessageRecord) {
        notificationHandler.addNotification(title: "Message received", message: record.content)
    }

    // MARK: - CONNECTIONS
    func onConnectionStateChanged(connectionRecord: ConnectionRecord) {
        print("🔗 Connection state changed: \(connectionRecord.state.rawValue)")

        guard connectionRecord.state == .Complete else { return }

        notificationHandler.addNotification(
            title: "New active connection",
            message: "Connected with \(connectionRecord.theirLabel ?? "unknown agent")",
            type: .connection
        )
    }

    // MARK: - ACCEPT CREDENTIAL
    func getCredential(version: String) {
        Task {
            do {
                await MainActor.run { self.menu = .loading }
                try await acceptCredentialOffer(version: version)
                await MainActor.run { self.menu = nil }
            } catch {
                await MainActor.run {
                    self.menu = nil
                    notificationHandler.addNotification(
                        title: "❌ Error accepting credential",
                        message: error.localizedDescription,
                        type: .error
                    )
                }
            }
        }
    }

    private func acceptCredentialOffer(version: String) async throws {
        if version == "1.0" {
            _ = try await agent!.credentials.acceptOffer(
                options: AcceptOfferOptions(
                    credentialRecordId: credentialRecordId,
                    autoAcceptCredential: .always
                )
            )
        } else if version == "2.0" {
            try await Task.sleep(nanoseconds: 300_000_000)

            guard let record = try? await agent?.credentialExchangeRepository.getById(credentialRecordId) else {
                throw NSError(domain: "CredentialHandler", code: 404, userInfo: [NSLocalizedDescriptionKey: "Record not found"])
            }

            _ = try await agent!.credentialsV2.acceptOffer(
                options: AcceptCredentialOfferOptionsV2(
                    credentialExchangeRecord: record,
                    autoAcceptCredential: .always
                )
            )
        }
    }

    // MARK: - SEND PROOF
    func sendProof(version: String, proofRecordId: String, chosenCredentialId: String? = nil) async throws {
        do {
            // Timeout of 10 seconds
            try await withThrowingTaskGroup(of: Void.self) { group in

                group.addTask {
                    if version == "1.0" {
                        try await self.proofV1(proofRecordId: proofRecordId)
                    } else {
                        try await self.proofV2(proofRecordId: proofRecordId, chosenCredentialId: chosenCredentialId)
                    }
                }

                group.addTask {
                    try await Task.sleep(nanoseconds: 10_000_000_000)
                    throw NSError(domain: "Timeout", code: 408, userInfo: [NSLocalizedDescriptionKey: "Proof processing timed out"])
                }

                try await group.next()
                group.cancelAll()
            }

        } catch {
            await MainActor.run {
                self.notificationHandler.addNotification(
                    title: "❌ Error sending proof",
                    message: error.localizedDescription,
                    type: .error
                )
            }
            throw error
        }
    }

    private func proofV1(proofRecordId: String) async throws {
        let retrieved = try await agent!.proofs.getRequestedCredentialsForProofRequest(proofRecordId: proofRecordId)
        let selected = try await agent!.proofService.autoSelectCredentialsForProofRequest(retrievedCredentials: retrieved)
        _ = try await agent!.proofs.acceptRequest(proofRecordId: proofRecordId, requestedCredentials: selected)
    }

    private func proofV2(proofRecordId: String, chosenCredentialId: String? = nil) async throws {
        _ = try await agent!.proofCommandV2.acceptRequest(proofRecordId: proofRecordId, chosenCredentialId: chosenCredentialId)
    }

    // MARK: - RECEIVE PRESENTATION
    func receivePresentation(proofRecord: ProofExchangeRecord) {
        Task {
            do {
                var mutable = proofRecord
                let (message, proofRecord) = try await agent!.proofServiceV2.createAck(proofRecord: &mutable)
                let connection = try await agent!.connectionRepository.getById(proofRecord.connectionId)
                try await agent!.messageSender.send(message: OutboundMessage(payload: message, connection: connection))

            } catch {
                await MainActor.run {
                    notificationHandler.addNotification(
                        title: "❌ Error receiving presentation",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    // MARK: - CONNECTIONS
    func getAllConnections() async throws -> [ConnectionRecord]? {
        try await agent!.connectionRepository.getAll()
    }

    func createProofInvitation() async throws -> String {
        let attributes = ["attributes1": ProofAttributeInfo(names: ["name", "email"])]
        let nonce = try ProofService.generateProofRequestNonce()

        let proofRequest = ProofRequest(
            nonce: nonce,
            requestedAttributes: attributes,
            requestedPredicates: [:]
        )

        let (message, _) = try await agent!.proofService.createRequest(proofRequest: proofRequest)

        let oobRecord = try await agent!.oob.createInvitation(
            config: CreateOutOfBandInvitationConfig(handshake: false, messages: [message])
        )

        print("message: \(message)")
        return try oobRecord.outOfBandInvitation.toUrl(domain: "http://example.com")
    }
}
