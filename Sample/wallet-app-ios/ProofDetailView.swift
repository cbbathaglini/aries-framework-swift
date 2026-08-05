//
//  ProofDetailView.swift
//  wallet-app-ios
//

import SwiftUI
import AriesFramework

struct ProofDetailView: View {
    let proof: ProofExchangeRecord
    var verifiedOverride: Bool? = nil

    @State private var proofRequest: AnonCredsProofRequest?
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                
                if isLoading {
                    ProgressView("Loading proof request…")
                        .padding()
                } else if let proofRequest = proofRequest {
                    
                    headerSection
                    
                    Divider()
                    proofMetadataSection
                    
                    Divider()
                    proofStatusSection
                    
                    Divider()
                    proofRequestInfo(proofRequest)
                    
                } else {
                    Text("❌ Could not load requested attributes.")
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
        .navigationTitle("Proof Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProofRequest()
        }
    }
}

// MARK: - UI Sections
extension ProofDetailView {
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Proof \(proof.id)")
                .font(.title2.bold())
            
            let requester = proof.comment?.isEmpty == false ? proof.comment! : "Unknown"
            Text("Requested by: \(requester)")
                .font(.headline)
            
            Text(proof.state.rawValue.capitalized)
                .font(.headline)
                .foregroundColor(colorForState(proof.state.rawValue))
        }
    }
    
    private var proofMetadataSection: some View {
        Group {
            
            Label("W3C Credential ID", systemImage: "link")
            Text(proof.chosenCredentialId ?? "empty")
                .font(.footnote)
            
            Label("Connection ID", systemImage: "link")
            Text(proof.connectionId).font(.footnote)
            
            Label("Thread ID", systemImage: "arrow.triangle.branch")
            Text(proof.threadId).font(.footnote)
            
            if let parent = proof.parentThreadId {
                Label("Parent Thread", systemImage: "arrowshape.turn.up.right")
                Text(parent).font(.footnote)
            }
            
            if let pres = proof.presentationId {
                Label("Presentation ID", systemImage: "text.book.closed")
                Text(pres).font(.footnote)
            }
        }
    }
    
    private var proofStatusSection: some View {
        Group {
            Label("Role", systemImage: "person.fill")
            Text(proof.role.rawValue.capitalized).font(.footnote)
            
            if let verified = proof.isVerified ?? verifiedOverride {
                Label("Verified", systemImage: verified ? "checkmark.seal.fill" : "xmark.seal")
                    .foregroundColor(verified ? .green : .red)
            }
            
            Label("Protocol Version", systemImage: "number")
            Text(proof.protocolVersion).font(.footnote)
            
            Label("Created At", systemImage: "calendar")
            Text(proof.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.footnote)
                .foregroundColor(.secondary)
            
            if let updated = proof.updatedAt {
                Label("Updated At", systemImage: "clock.arrow.circlepath")
                Text(updated.formatted(date: .abbreviated, time: .shortened))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            if let error = proof.errorMessage {
                Label("Error Message", systemImage: "exclamationmark.triangle")
                Text(error)
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Proof Request UI
    @ViewBuilder
    private func proofRequestInfo(_ req: AnonCredsProofRequest) -> some View {
        
        Group {
            Label("Nonce", systemImage: "number.circle")
            Text(req.nonce).font(.footnote)
            
            if let nonrev = req.nonRevoked {
                Label("Non-Revoked Interval", systemImage: "clock")
                Text(formatRevocationPeriod(nonrev))
                    .font(.footnote)
            }
        }
        
        Divider()
        
        // ATTRIBUTES
        Section {
            Text("Requested Attributes")
                .font(.headline)
            
            if req.requestedAttributes.isEmpty {
                Text("None").foregroundColor(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(req.requestedAttributes.sorted(by: { $0.key < $1.key }), id: \.key) { key, item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.name ?? key).font(.headline)
                            
                            if let names = item.names {
                                ForEach(names, id: \.self) { n in
                                    Text("• \(n)").font(.subheadline)
                                }
                            }
                            
                            if let restrictions = item.restrictions {
                                Divider()
                                ForEach(restrictions.indices, id: \.self) { i in
                                    if let schema = restrictions[i].schemaName {
                                        Text("Schema: \(schema)").font(.caption)
                                    }
                                    if let cred = restrictions[i].credDefId {
                                        Text("Credential Definition: \(cred)").font(.caption2)
                                    }
                                }
                            }
                            
                            
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                }
            }
        }
        
        Divider()
        
        
        // PREDICATES
        Section {
            Text("Requested Predicates")
                .font(.headline)
            
            if req.requestedPredicates.isEmpty {
                Text("None").foregroundColor(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(req.requestedPredicates.sorted(by: { $0.key < $1.key }), id: \.key) { key, pred in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(pred.name ?? key).font(.headline)
                            
                            Text("Condition: \(pred.pType.rawValue) \(pred.pValue)")
                                .font(.subheadline)
                            
                            if let restrictions = pred.restrictions {
                                Divider()
                                ForEach(restrictions.indices, id: \.self) { i in
                                    if let schema = restrictions[i].schemaName {
                                        Text("Schema: \(schema)").font(.caption)
                                    }
                                    if let cred = restrictions[i].credDefId {
                                        Text("Credential Definition: \(cred)").font(.caption2)
                                    }
                                }
                            }
                            
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                }
            }
        }
    
    
        Section {
            Text("Interval")
                .font(.headline)

            if let interval = req.nonRevoked {
                HStack {
                    Image(systemName: "clock")
                    Text("Validity: \(formatRevocationPeriod(interval))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No interval defined")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Data Load
extension ProofDetailView {
    
    private func loadProofRequest() async {
        do {
            let threadId = proof.threadId

            let verifierRecord = try await agent?.verifierRepository.getByGlobalThreadId(globalThreadId: threadId)
            self.proofRequest = verifierRecord?.proofRequest
            
        } catch {
            print("❌ Error loading verifier record: \(error)")
        }
        
        self.isLoading = false
    }
    
    private func formatRevocationPeriod(_ nonRevoked: AnonCredsNonRevokedInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let from = nonRevoked.from.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        let to   = nonRevoked.to.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        
        switch (from, to) {
        case let (f?, t?):
            return "\(formatter.string(from: f)) → \(formatter.string(from: t))"
        case let (f?, nil):
            return "From \(formatter.string(from: f))"
        case let (nil, t?):
            return "Until \(formatter.string(from: t))"
        default:
            return "No interval defined"
        }
    }
}

// MARK: - Colors
extension ProofDetailView {
    private func colorForState(_ state: String) -> Color {
        switch state.lowercased() {
        case ProofState.ProposalSent.rawValue: return .purple
        case ProofState.ProposalReceived.rawValue: return .indigo
        case ProofState.RequestSent.rawValue: return .orange
        case ProofState.RequestReceived.rawValue: return .yellow
        case ProofState.PresentationSent.rawValue: return .mint
        case ProofState.PresentationReceived.rawValue: return .blue
        case ProofState.Done.rawValue: return .green
        case "abandoned", "error": return .red
        default: return .gray
        }
    }
}
