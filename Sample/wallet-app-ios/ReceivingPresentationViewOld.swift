//
//  ReceivingPresentationView.swift
//  wallet-app-ios
//

import SwiftUI
import CoreBluetooth

struct ReceivingPresentationViewOld: View {
    @StateObject private var bluetooth = BluetoothHandler()
    @State private var hasReceivedPresentation = false
    @State private var verificationResult: Bool? = nil
    @State private var receivedCreatedAt: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Receiving Presentation")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)

                statusSection

                // BLE Logs
                logsSection

                // Indicators
                if hasReceivedPresentation {
                    if let createdAt = receivedCreatedAt {
                        createdAtView(createdAt)
                    }

                    receivedIndicator
                }

                if let verified = verificationResult {
                    verificationIndicator(isVerified: verified)
                }

                // Received JSON
                if let jsonText = bluetooth.receivedJSON {
                    receivedJSONView(jsonText)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Receive Presentation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startServerMode()
        }
    }

    // MARK: - Status Section
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🔵 Bluetooth State:")
                Spacer()
                Text(bluetooth.stateText)
                    .foregroundColor(.secondary)
            }
            HStack {
                Text("📡 Connected Device:")
                Spacer()
                Text(bluetooth.connectedDevice ?? "—")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    // MARK: - Logs
    private var logsSection: some View {
        VStack(alignment: .leading) {
            Text("Logs")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(bluetooth.logs, id: \.self) { line in
                        Text(line)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .frame(maxHeight: 200)
        }
    }

    // MARK: - Received JSON
    private func receivedJSONView(_ jsonText: String) -> some View {
        VStack(alignment: .leading) {
            Text("📦 Received JSON")
                .font(.headline)
                .padding(.bottom, 4)

            ScrollView {
                Text(jsonText)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 300)
        }
        .padding(.top)
    }

    // MARK: - Indicators
    private var receivedIndicator: some View {
        HStack {
            Image(systemName: "tray.and.arrow.down.fill")
                .foregroundColor(.white)
            Text("Presentation received successfully!")
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green)
        .cornerRadius(12)
        .transition(.scale)
    }

    private func createdAtView(_ createdAt: String) -> some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.blue)
            Text("Presentation created at: \(createdAt)")
                .foregroundColor(.primary)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(10)
        .transition(.opacity)
    }

    private func verificationIndicator(isVerified: Bool) -> some View {
        let color = isVerified ? Color.green : Color.red
        let text = isVerified ? "Presentation successfully verified ✅" : "Verification failed ❌"

        return HStack {
            Image(systemName: isVerified ? "checkmark.shield.fill" : "xmark.shield.fill")
                .foregroundColor(.white)
            Text(text)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color)
        .cornerRadius(12)
        .transition(.scale)
    }

    // MARK: - Bluetooth Server Mode
    private func startServerMode() {
        bluetooth.switchMode(to: .server)

        bluetooth.onReceiveJSON = { jsonText in
            hasReceivedPresentation = true
            print("📩 Received presentation JSON: \(jsonText)")

            if let data = jsonText.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                // try createdAt string or timestamp
                if let createdAtValue = jsonObject["createdAt"] as? String {
                    receivedCreatedAt = createdAtValue
                } else if let createdAtTimestamp = jsonObject["createdAt"] as? Double {
                    let date = Date(timeIntervalSince1970: createdAtTimestamp)
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    receivedCreatedAt = formatter.string(from: date)
                }

                // Validate presentation offline
                Task {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        let resultTuple = try? await agent?.proofCommandV2.processPresentationOffline(
                            presentationMessage: jsonString
                        )
                        
                        let proofRecord = resultTuple?.0
                        let result = resultTuple?.1 ?? false

                        if let proofRecord = proofRecord {
                            try? await agent?.proofCommandV2.processOfflineAck(proofRecord: proofRecord)
                        } else {
                            print("⚠️ No proofRecord returned — ACK ignored")
                        }

                        await MainActor.run {
                            verificationResult = (result != nil)
                        }
                    }
                }
            } else {
                print("⚠️ Received content is not valid JSON, showing raw text.")
                verificationResult = false
            }

            bluetooth.receivedJSON = jsonText
        }
    }
}

#Preview {
    NavigationView {
        ReceivingPresentationView()
    }
}
