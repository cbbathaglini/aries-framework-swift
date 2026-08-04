//
//  ReceivingPresentationView.swift
//  wallet-app-ios
//

import SwiftUI
import AriesFramework

struct ReceivingPresentationView: View {

    @State private var hasReceivedPresentation = false
    @State private var verificationResult: Bool? = nil
    @State private var receivedCreatedAt: String? = nil
    @State private var receivedJSON: String? = nil
    @State private var logs: [String] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                Text("Receiving Presentation")
                    .font(.title2)
                    .bold()
                
                if hasReceivedPresentation {
                    receivedIndicator

                    if let createdAt = receivedCreatedAt {
                        createdAtView(createdAt)
                    }
                }

                if let verified = verificationResult {
                    verificationIndicator(isVerified: verified)
                }

                if let json = receivedJSON {
                    receivedJSONView(json)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Receive Presentation")
        .onAppear {
        
        }
        .onDisappear {
           
        }
    }



    private func receivedJSONView(_ json: String) -> some View {
        VStack(alignment: .leading) {
            Text("📦 Received JSON").font(.headline)
            ScrollView {
                Text(json)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .frame(maxHeight: 350)
        }
    }

    private var receivedIndicator: some View {
        HStack {
            Image(systemName: "tray.and.arrow.down.fill").foregroundColor(.white)
            Text("Received successfully!").foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green)
        .cornerRadius(12)
    }

    private func createdAtView(_ c: String) -> some View {
        HStack {
            Image(systemName: "calendar")
            Text("Created at: \(c)")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray5))
        .cornerRadius(10)
    }

    private func verificationIndicator(isVerified: Bool) -> some View {
        let color = isVerified ? Color.green : Color.red
        let text = isVerified ? "Verified successfully" : "Verification failed"

        return HStack {
            Image(systemName: isVerified ? "checkmark.shield.fill" : "xmark.shield.fill")
                .foregroundColor(.white)
            Text(text)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color)
        .cornerRadius(12)
    }

    private func processReceivedJSON(_ json: String) {
        logs.append("🔍 Processing JSON...")

        guard let data = json.data(using: .utf8) else { return }

        if let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let created = parsed["createdAt"] as? String {
            receivedCreatedAt = created
        }

        Task {
            if let agent = agent {
                let tuple = try? await agent.proofCommandV2.processPresentationOffline(
                    presentationMessage: json
                )

                let valid = tuple?.1 ?? false
                verificationResult = valid

                logs.append(valid ? "✅ Verified" : "❌ Not valid")
            } else {
                logs.append("⚠️ Agent unavailable")
            }
        }
    }
}
