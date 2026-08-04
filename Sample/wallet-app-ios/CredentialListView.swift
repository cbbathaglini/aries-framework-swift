//
//  CredentialListView.swift
//  wallet-app-ios
//

import SwiftUI
import AriesFramework
import Anoncreds

class CredentialList: ObservableObject {
    @Published var list: [CredentialInfo] = []
}

struct CredentialInfo: Decodable {
    var id: String
    var w3cId: String = "none"
    var attrs: [String: String] = [:]
    var schema_id: String? = "none"
    var type: [String]? = []
    var state: CredentialState? = nil
    var credentialDefinitionId: String? = "none"
    var revRegId: String? = "not revokable"
    var createdAt: Date
    var isRevoked: Bool = false
}

struct CredentialListView: View {
    @StateObject private var credentials = CredentialList()
    var connectionId: String?

    var body: some View {
        NavigationView {
            List {
                ForEach(
                    $credentials.list.sorted(by: { $0.wrappedValue.createdAt > $1.wrappedValue.createdAt }),
                    id: \.wrappedValue.id
                ) { credential in
                    NavigationLink(destination: CredentialDetailView(credential: credential.wrappedValue)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Credential \(credential.wrappedValue.id)")
                                .font(.headline)

                            // STATUS BADGE
                            HStack {
                                Circle()
                                    .fill(statusColor(for: credential.wrappedValue.state))
                                    .frame(width: 10, height: 10)

                                Text(statusText(for: credential.wrappedValue.state))
                                    .foregroundColor(statusColor(for: credential.wrappedValue.state))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }

                            Text("Created at: \(credential.wrappedValue.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(connectionId == nil ? "All Credentials" : "Connection Credentials")
            .task {
                await loadCredentials()
            }
        }
    }


    private func loadCredentials() async {
        let allRecords = await agent!.credentialExchangeRepository.getAll()

        let filteredRecords: [CredentialExchangeRecord]
        if let connectionId = connectionId {
            filteredRecords = allRecords.filter { $0.connectionId == connectionId }
        } else {
            filteredRecords = allRecords
        }

        credentials.list = filteredRecords.map { record in
            let attributesDict = Dictionary(
                uniqueKeysWithValues: (record.credentialAttributes ?? []).map { ($0.name, $0.value) }
            )

            let recordTypes = record.credentials.map { $0.credentialRecordType }

            return CredentialInfo(
                id: record.id,
                w3cId: record.w3cCredentialId ?? "not informed",
                attrs: attributesDict,
                schema_id: record.schemaId,
                type: recordTypes,
                state: record.state,
                credentialDefinitionId: record.credentialDefinitionId ?? "not informed",
                revRegId: record.revRegId ?? "not revokable",
                createdAt: record.createdAt,
                isRevoked: record.state == .Revoked
            )
        }
    }
    
    private func statusText(for state: CredentialState?) -> String {
        switch state {
        case .ProposalSent: return "Proposal Sent"
        case .ProposalReceived: return "Proposal Received"
        case .OfferSent: return "Offer Sent"
        case .OfferReceived: return "Offer Received"
        case .Declined: return "Declined"
        case .RequestSent: return "Request Sent"
        case .RequestReceived: return "Request Received"
        case .CredentialIssued: return "Credential Issued"
        case .CredentialReceived: return "Credential Received"
        case .Done: return "Done"
        case .Revoked: return "Revoked"
        case .Default, .none: return "Unknown"
        }
    }

    private func statusColor(for state: CredentialState?) -> Color {
        switch state {
        case .Revoked, .Declined:
            return .red
        case .Done, .CredentialReceived, .CredentialIssued:
            return .green
        case .OfferReceived, .OfferSent, .RequestReceived, .RequestSent:
            return .blue
        case .ProposalSent, .ProposalReceived:
            return .orange
        default:
            return .gray
        }
    }
}

#Preview {
    CredentialListView()

    CredentialListView(connectionId: "12345-ABCD")
}
