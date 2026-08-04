//
//  ConnectionsHistoricalView.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 10/10/25.
//
import SwiftUI
import AriesFramework
import CoreImage.CIFilterBuiltins

struct ConnectionsHistoricalView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var connections: [ConnectionRecord] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    let connectionHandler = ConnectionHandler.shared

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading connections...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else if connections.isEmpty {
                    Text("No connections found")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(connections, id: \.id) { connection in
                        NavigationLink(destination: ConnectionDetailView(connection: connection)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(connection.theirLabel ?? "Without name")
                                    .font(.headline)
                                Text("State: \(connection.state.rawValue)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationBarTitle("Connection History", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }
            .task {
                do {
                    if let allConnections = await connectionHandler.getAllConnections() {
                        connections = allConnections
                    } else {
                        errorMessage = "Unable to load connections"
                    }
                } catch {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        }
    }
}

#Preview {
    ConnectionsHistoricalView()
}
