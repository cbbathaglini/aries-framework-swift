//
//  ConnectionDetailView.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 13/10/25.
//

import SwiftUI
import AriesFramework

struct ConnectionDetailView: View {
    let connection: ConnectionRecord
    @State private var showCopyAlert = false
    @State private var navigateToProofRequest = false
    @State private var navigateToCredentialList = false 

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                VStack(alignment: .leading, spacing: 6) {
                    Text(connection.theirLabel ?? "Without name")
                        .font(.title2)
                        .bold()
                    Text("State: \(connection.state.rawValue)")
                        .font(.headline)
                        .foregroundColor(connection.state == .Complete ? .green : .orange)
                }

                Divider()

                Group {
                    detailRow(title: "ID", value: connection.id)
                    if let alias = connection.alias {
                        detailRow(title: "Alias", value: alias)
                    }
                    if let did = connection.theirDid {
                        detailRow(title: "Remote DID", value: did)
                    }
                    detailRow(title: "Created at", value: formatDate(connection.createdAt))
                }

                Spacer()

                if let did = connection.theirDid {
                    Button {
                        UIPasteboard.general.string = did
                        showCopyAlert = true
                    } label: {
                        Label("Copy DID", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 10)
                }

                NavigationLink(destination: RequestProofViewConnectionLess(connectionId: connection.id), //connectionless
                               isActive: $navigateToProofRequest) {
                    EmptyView()
                }

                NavigationLink(destination: CredentialListView(connectionId: connection.id),
                               isActive: $navigateToCredentialList) {
                    EmptyView()
                }

                Button {
                    navigateToProofRequest = true
                } label: {
                    Label("Request proof", systemImage: "checkmark.seal")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 20)


                Button {
                    navigateToCredentialList = true
                } label: {
                    Label("View Issued Credentials", systemImage: "list.bullet.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .padding(.top, 10)
            }
            .padding()
        }
        .navigationTitle("Connection details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Copied!", isPresented: $showCopyAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The DID has been copied to the clipboard.")
        }
    }


    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: date)
    }

    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
                .padding(.bottom, 8)
            Divider()
        }
    }
}
