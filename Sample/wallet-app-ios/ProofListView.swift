//
//  ProofListView.swift
//  wallet-app-ios
//
//  Criado em 13/10/25
//

import SwiftUI
import AriesFramework

@MainActor
class ProofList: ObservableObject {
    @Published var list: [ProofExchangeRecord] = []

    func loadProofs(connectionId: String? = nil) async {
        guard let agent = agent else { return }

        do {
            let allProofs = await agent.proofRepository.getAll()
            let filteredProofs = connectionId != nil
                ? allProofs.filter { $0.connectionId == connectionId }
                : allProofs

            self.list = filteredProofs.sorted(by: { $0.createdAt > $1.createdAt })
        } catch {
            print("Error loading proofs: \(error.localizedDescription)")
        }
    }
}

struct ProofListView: View {
    @StateObject private var proofs = ProofList()
    var connectionId: String?

    var body: some View {
        NavigationView {
            List {
                ForEach(proofs.list, id: \.id) { proof in
                    NavigationLink(destination: ProofDetailView(proof: proof)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Proof \(proof.id)")
                                .font(.headline)

                            HStack {
                                Label(proof.state.rawValue.capitalized, systemImage: "checkmark.seal")
                                    .font(.caption)
                                    .foregroundColor(colorForState(proof.state.rawValue))

                                Spacer()

                                Text(proof.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(connectionId == nil ? "All Proofs" : "Connection Proofs")
            .task {
                await proofs.loadProofs(connectionId: connectionId)
            }
        }
    }

    private func colorForState(_ state: String) -> Color {
        switch state.lowercased() {
        case ProofState.ProposalSent.rawValue:
               return .purple
           case ProofState.ProposalReceived.rawValue:
               return .indigo
           case ProofState.RequestSent.rawValue:
               return .orange
           case ProofState.RequestReceived.rawValue:
               return .yellow
           case ProofState.PresentationSent.rawValue:
               return .mint
           case ProofState.PresentationSentOffline.rawValue:
               return .mint
           case ProofState.PresentationReceived.rawValue:
               return .blue
           case ProofState.Done.rawValue:
               return .green
           case "abandoned", "error":
               return .red
           default:
               return .gray
           }
    }
}

// MARK: - Preview
#Preview {
    ProofListView()
}
