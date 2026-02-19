//
//  PresentationDetailView.swift
//  wallet-app-ios
//

import SwiftUI
import AriesFramework

struct PresentationDetailViewOld: View {
    let record: ProofExchangeRecord
    @StateObject private var bluetoothManager = BluetoothHandler()
    @ObservedObject private var handler = PresentationHandler.shared
    
    @State private var jsonPreview: String = ""
    @State private var showCopied = false
    
    var body: some View {
        List {
            // MARK: - Presentation Info
            Section(header: Text("Presentation Info")) {
                infoRow(title: "Record ID", value: record.id)

                if let createdAt = record.createdAt as Date? {
                    infoRow(
                        title: "Created At",
                        value: createdAt.formatted(date: .abbreviated, time: .shortened)
                    )
                }
            }
            
            // MARK: - Presentation JSON
            Section(header: Text("Presentation Message")) {
                if jsonPreview.isEmpty {
                    Text("No content available.")
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ScrollView {
                            Text(jsonPreview)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .shadow(radius: 1)
                        }
                        .frame(maxHeight: 300)

                        Button {
                            UIPasteboard.general.string = jsonPreview
                            withAnimation { showCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { showCopied = false }
                            }
                        } label: {
                            Label("Copy content", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 4)
                    }
                }
            }
            
            // MARK: - Devices
            Section(header: Text("Available Devices")) {
                if bluetoothManager.availableDevices.isEmpty {
                    Text("No devices found.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(bluetoothManager.availableDevices, id: \.identifier) { device in
                        HStack {
                            Text(device.name ?? "Unnamed")
                                .foregroundColor(.primary)
                            Spacer()
                            Button("Connect") {
                                bluetoothManager.connectTo(device)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                Button {
                    bluetoothManager.startScan()
                } label: {
                    Label("Search devices", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            
            // MARK: - Bluetooth Transfer
            Section(header: Text("Bluetooth Transfer")) {
                VStack(spacing: 12) {
                    Text("Status: \(bluetoothManager.stateText)")
                    Text("Device: \(bluetoothManager.connectedDevice ?? "—")")
                        .foregroundColor(.secondary)
                    
                    Button {
                        handler.sendViaBluetooth(record: record, bluetooth: bluetoothManager)
                        NotificationHandler.shared.addNotification(
                            title: "Presentation sent",
                            message: "The presentation \(record.id) was successfully sent via Bluetooth.",
                            type: .sendBluetoothPresentationProofv2,
                            proofRecordId: record.id
                        )
                    } label: {
                        Label("Send via Bluetooth", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!bluetoothManager.isReadyToSend)
                }
            }
            
            // MARK: - Logs
            Section(header: Text("Logs")) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(bluetoothManager.logs, id: \.self) { log in
                            Text(log)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(minHeight: 120)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Presentation Details")
        .onAppear {
            bluetoothManager.switchMode(to: .client)
            loadJSONPreview()
        }
        .overlay(
            VStack {
                if showCopied {
                    Text("Copied!")
                        .font(.caption)
                        .padding(8)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .transition(.opacity)
                        .animation(.easeInOut, value: showCopied)
                }
            }
            .padding(.bottom, 50),
            alignment: .bottom
        )
    }
    
    // MARK: - Load JSON Preview
    private func loadJSONPreview() {
        guard let presentation = record.presentationMessage else { return }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.keyEncodingStrategy = .useDefaultKeys
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(presentation),
           let json = String(data: data, encoding: .utf8) {
            jsonPreview = json
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title).fontWeight(.semibold)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}
