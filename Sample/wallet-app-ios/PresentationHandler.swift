//
//  PresentationHandler.swift
//  wallet-app-ios
//

import SwiftUI
import AriesFramework
import CoreBluetooth

@MainActor
class PresentationHandler: ObservableObject, AgentDelegate {
    static let shared = PresentationHandler()

    private let notificationHandler = NotificationHandler.shared

    @Published var proofRecords: [ProofExchangeRecord] = []
    @Published var verifierRecords: [VerifierRecord] = []
    @Published var lastUpdated: Date? = nil
    @Published var menu: MainMenu?

    private init() {}

    // MARK: - Agent event listener
    func onProofStateChangedV2(proofRecord: ProofExchangeRecord) {
        Task { @MainActor in
            switch proofRecord.state {
            case .PresentationReceived:
                handlePresentationReceived(proofRecord)
            case .Done:
                handlePresentationDone(proofRecord)
            case .Abandoned:
                handlePresentationAbandoned(proofRecord)
            default:
                break
            }
        }
    }

    // MARK: - Presentation events
    private func handlePresentationReceived(_ proofRecord: ProofExchangeRecord) {
        notificationHandler.addNotification(
            title: "📩 Presentation received",
            message: "Version 2.0 | ID: \(proofRecord.id)",
            type: .proofRequestv2,
            proofRecordId: proofRecord.id
        )
        refreshVerifierRecords()
    }

    private func handlePresentationDone(_ proofRecord: ProofExchangeRecord) {
        notificationHandler.addNotification(
            title: "✅ Presentation completed",
            message: "Proof \(proofRecord.id) successfully finished",
            type: .proofRequestv2,
            proofRecordId: proofRecord.id
        )
        refreshVerifierRecords()
    }
    
    private func handlePresentationAbandoned(_ proofRecord: ProofExchangeRecord) {
        notificationHandler.addNotification(
            title: "❌ Presentation abandoned",
            message: "Proof \(proofRecord.id) not valid",
            type: .abandonedProofv2,
            proofRecordId: proofRecord.id
        )
        refreshVerifierRecords()
    }
    
    
    
    public func verifyReceivedPresentation(json: String) {
        Task {
            let result = try await agent!.proofCommandV2.processPresentationOffline(presentationMessage: json)
            print("Result: \(result)")
        }
    }

    // MARK: - Refresh repository
    func refreshVerifierRecords() {
        Task {
            do {
                guard let agent = agent else { return }
                let all = await agent.proofRepository.getAll()
                
                await MainActor.run {
                    self.proofRecords = all
                    self.lastUpdated = Date()
                }
                print("📚 \(all.count) proof records loaded.")
            } catch {
                print("❌ Error loading proof records: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Fetch specific record
    func getRecord(by id: String) -> ProofExchangeRecord? {
        proofRecords.first { $0.id == id }
    }

    // MARK: - Bluetooth sending
    func sendViaBluetooth(record: ProofExchangeRecord, bluetooth: BluetoothHandler) {
        guard let presentation = record.presentationMessage else {
            notificationHandler.addNotification(
                title: "⚠️ No presentation available",
                message: "Record \(record.id) does not contain a presentationMessage"
            )
            return
        }

        do {
            let data = try JSONEncoder().encode(presentation)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                bluetooth.sendJSON(json)
                notificationHandler.addNotification(
                    title: "📤 Presentation sent via Bluetooth",
                    message: "Record \(record.id)"
                )
            }
        } catch {
            notificationHandler.addNotification(
                title: "❌ Failed to send presentation",
                message: error.localizedDescription
            )
        }
    }
}
