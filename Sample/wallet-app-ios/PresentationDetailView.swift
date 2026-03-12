//
// PresentationDetailView.swift
// wallet-app-ios
//


import SwiftUI
import UIKit
import AriesFramework

struct PresentationDetailView: View {

    let record: ProofExchangeRecord

    @State private var jsonPreview = ""
    @State private var logs: [String] = []
    @State private var qrImages: [UIImage] = []
    @State private var currentQRIndex = 0
    @State private var isShowingQR = false
    @State private var qrTimer: Timer?
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                if !isShowingQR {
                    mainContent
                } else {
                    qrContent
                }
            }
            .padding(16)
        }
        .navigationTitle("Presentation Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadJSON()
        }
        .onDisappear {
            stopQRCycle()
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Presentation Details")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 6) {
                Text("ID: \(record.id)")
                    .font(.body)

                Text("Created at: \(formattedCreatedAt)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("JSON Content")
                    .font(.headline)

                ScrollView {
                    Text(jsonPreview.isEmpty ? "—" : jsonPreview)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
                .frame(height: 220)

                Button {
                    copyJSON()
                } label: {
                    Text("Copy Content")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            VStack(alignment: .leading, spacing: 8) {
                Button {
                    sendQRCode()
                } label: {
                    Text("Send via QR Code")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Logs")
                    .font(.headline)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(logs.enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(.footnote, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 2)
                                    .id(index)
                            }
                        }
                        .padding(8)
                    }
                    .frame(height: 180)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onChange(of: logs.count) { _ in
                        if let last = logs.indices.last {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }

                Button {
                    copyLogs()
                } label: {
                    Text("Copy Logs")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var qrContent: some View {
        VStack(spacing: 16) {
            if !qrImages.isEmpty {
                Image(uiImage: qrImages[currentQRIndex])
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
            } else {
                ProgressView("Generating QR...")
            }

            Text("Frame \(currentQRIndex + 1) of \(max(qrImages.count, 1))")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                stopQRCycle()
                isShowingQR = false
                appendLog("Closed QR presentation")
            } label: {
                Text("Back")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
    }

    private var formattedCreatedAt: String {
        record.createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    private func loadJSON() {
        guard let presentation = record.presentationMessage else {
            jsonPreview = "No content available"
            appendLog("No presentation message available")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            let data = try encoder.encode(presentation)
            jsonPreview = String(data: data, encoding: .utf8) ?? "{}"
            appendLog("✅ JSON loaded successfully")
        } catch {
            jsonPreview = "{}"
            appendLog("❌ Error generating JSON: \(error.localizedDescription)")
        }
    }

    private func copyJSON() {
        guard !jsonPreview.isEmpty else {
            showSimpleError("No JSON available to copy.")
            return
        }

        UIPasteboard.general.string = jsonPreview
        appendLog("📋 JSON copied to clipboard")
    }

    private func copyLogs() {
        let allLogs = logs.joined(separator: "\n")
        guard !allLogs.isEmpty else {
            showSimpleError("No logs to copy.")
            return
        }

        UIPasteboard.general.string = allLogs
        appendLog("Logs copied to clipboard")
    }

    private func sendQRCode() {
        guard !jsonPreview.isEmpty else {
            showSimpleError("No JSON available.")
            return
        }

        do {
            let generated = try QRCode().buildQRCode(jsonPreview)
            qrImages = generated
            currentQRIndex = 0
            isShowingQR = true
            appendLog("QR code generated with \(generated.count) frame(s)")
            startQRCycle()
        } catch {
            appendLog("Failed to generate QR: \(error.localizedDescription)")
            showSimpleError("Failed to generate QR: \(error.localizedDescription)")
        }
    }

    private func startQRCycle() {
        stopQRCycle()

        guard qrImages.count > 1 else { return }

        qrTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            guard !qrImages.isEmpty else { return }
            currentQRIndex = (currentQRIndex + 1) % qrImages.count
        }
    }

    private func stopQRCycle() {
        qrTimer?.invalidate()
        qrTimer = nil
    }

    private func appendLog(_ line: String) {
        logs.append(line)
    }

    private func showSimpleError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}
