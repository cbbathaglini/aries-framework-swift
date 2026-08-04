//
//  VerifierHandler.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 06/11/25.
//

import SwiftUI
import AriesFramework

@MainActor
class VerifierHandler: ObservableObject {
    static let shared = VerifierHandler()
    
    private let notificationHandler = NotificationHandler.shared
    
    @Published var verifierRecords: [VerifierRecord] = []
    @Published var lastUpdated: Date? = nil

    private init() {}
    
    // MARK: - Update Verifier Records
    func refreshVerifierRecords() {
        Task {
            do {
                guard let agent = agent else { return }
                let all = try await agent.verifierRepository.getAll()
                await MainActor.run {
                    self.verifierRecords = all
                    self.lastUpdated = Date()
                }
                print("📚 \(all.count) VerifierRecords loaded successfully.")
            } catch {
                print("❌ Error loading VerifierRecords: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Fetch a Specific Record
    func getRecord(by id: String) -> VerifierRecord? {
        verifierRecords.first { $0.id == id }
    }
    
    // MARK: - Offline Verification
    func verifyReceivedPresentation(json: String) async -> Bool {
        do {
            guard let agent else { return false }
            let result = try await agent.proofCommandV2.processPresentationOffline(presentationMessage: json)
            print("✅ Offline verification succeeded: \(result)")
            return true
        } catch {
            print("⚠️ Error processing offline presentation: \(error.localizedDescription)")
            return false
        }
    }
}
