//
//  ReceivedPresentationDetailView.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 11/06/25.
//

import SwiftUI
import AriesFramework

struct ReceivedPresentationDetailView: View {
    let record: VerifierRecord
    @State private var proofs: [Int: ProofExchangeRecord] = [:] // local cache
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Thread ID: \(record.globalThreadId ?? "N/A")")
                .font(.headline)
                .padding()

            if let presentations = record.presentation, presentations.isEmpty {
                Text("No presentations available.")
                    .foregroundColor(.secondary)
                    .padding()
            } else if let presentations = record.presentation {
                List {
                    ForEach(Array(presentations.enumerated()), id: \.offset) { index, presentation in
                        NavigationLink {
                            if let proof = proofs[index] {
                                ProofDetailView(proof: proof)
                            } else {
                                ProgressView("Loading...")
                            }
                        } label: {
                            presentationCell(index: index, presentation: presentation)
                        }
                        .task {
                            await loadProof(for: presentation, at: index)
                        }
                    }
                }
                .listStyle(.plain)
            }

            Spacer()
        }
        .navigationTitle("Presentations")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadProof(for presentation: PresentationVerifier, at index: Int) async {
        guard proofs[index] == nil else { return }

        guard let agent = agent,
              let proofRecordId = presentation.proofRecordId else {
            print("⚠️ Incomplete data for presentation #\(index + 1)")
            return
        }

        do {
            let proof = try await agent.proofRepository.getById(proofRecordId)
            await MainActor.run {
                proofs[index] = proof
            }
            print("✅ Proof loaded for presentation #\(index + 1)")
        } catch {
            print("❌ Error fetching ProofRecord: \(error)")
        }
    }

    private func presentationCell(index: Int, presentation: PresentationVerifier) -> some View {
        VStack(alignment: .leading) {
            Text("#\(index + 1)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("ID: \(presentation.proofRecordId ?? "N/A")")
                .font(.body)
            HStack {
                Text("Status: \((presentation.isVerified ?? false) ? "✅ Verified" : "⚠️ Not verified")")
                Spacer()
                Text("Source: \((presentation.isOffline ?? false) ? "📴 Offline" : "🌐 Online")")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
