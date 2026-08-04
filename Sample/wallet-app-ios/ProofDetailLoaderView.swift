import SwiftUI
import AriesFramework
import Foundation

struct ProofDetailLoaderView: View {
    let notification: NotificationItem
    
    @State private var proof: ProofExchangeRecord?
    @State private var proofRequest: AnonCredsProofRequest?
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading proof...")
            }
            else if let proof = proof, let request = proofRequest {
                ProofDetailView(proof: proof)
            }
            else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.largeTitle)
                    Text(errorMessage ?? "❌ Failed to load proof data.")
                        .font(.headline)
                }
            }
        }
        .task { await loadProof() }
        .navigationTitle("Proof Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadProof() async {
        do {
        
            guard let proofId = notification.proofRecordId else {
                await MainActor.run {
                    errorMessage = "Missing proofRecordId"
                    isLoading = false
                }
                return
            }
            
            guard let record = try await agent?.proofRepository.getById(proofId) else {
                await MainActor.run {
                    errorMessage = "Proof not found"
                    isLoading = false
                }
                return
            }
            
        
            var verifierRecord: VerifierRecord? = nil
            
            let threadId = record.threadId

            if !threadId.isEmpty {
                verifierRecord = try await agent?.verifierRepository.getByGlobalThreadId(globalThreadId: threadId)
            }
            
            guard let verifier = verifierRecord else {
                await MainActor.run {
                    errorMessage = "Verifier record not found"
                    isLoading = false
                }
                return
            }
            
    
            guard let request = verifier.proofRequest else {
                await MainActor.run {
                    errorMessage = "Proof request is missing"
                    isLoading = false
                }
                return
            }
            
            await MainActor.run {
                self.proof = record
                self.proofRequest = request
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
