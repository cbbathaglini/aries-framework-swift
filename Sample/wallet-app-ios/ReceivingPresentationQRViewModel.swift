//
//  ReceivingPresentationQRViewModel.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 11/03/26.
//

import Foundation
import SwiftUI
import AriesFramework

final class ReceivingPresentationQRViewModel: ObservableObject {
    @Published var isScanning: Bool = true
    @Published var showCamera: Bool = true
    @Published var resultText: String = ""
    @Published var overlayColor: Color = .white
    @Published var statusText: String = "Point the camera at the QR code"
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""

    @Published var verificationResult: Bool? = nil
    @Published var receivedCreatedAt: String? = nil
    @Published var receivedJSON: String? = nil
    @Published var logs: [String] = []

    private var chunkList: [Int: String] = [:]
    private var expectedChunks: Int?


    func handleScannedQRCode(_ qrValue: String) {
        guard isScanning else { return }

        do {
            let headerEnd = try findHeaderEnd(in: qrValue)
            let header = String(qrValue.prefix(headerEnd))
            let payload = String(qrValue.dropFirst(headerEnd + 2))

            let headerValues = header.split(separator: "/")
            guard headerValues.count == 2,
                  let chunkIndex = Int(headerValues[0]),
                  let totalChunks = Int(headerValues[1]) else {
                throw QRReceiveError.invalidHeader
            }

            expectedChunks = totalChunks
            chunkList[chunkIndex] = payload

            overlayColor = .green
            statusText = "Chunk \(chunkIndex + 1)/\(totalChunks) received"
            appendLog("📥 Chunk \(chunkIndex + 1)/\(totalChunks) received")

            if chunkList.count == totalChunks {
                isScanning = false
                statusText = "Reassembling QR..."
                appendLog("🔗 Reassembling QR payload...")
                try finishReading()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.overlayColor = .white
                }
            }

        } catch {
            show(error: error)
        }
    }

    func reset() {
        chunkList.removeAll()
        expectedChunks = nil
        resultText = ""
        receivedJSON = nil
        overlayColor = .white
        statusText = "Point the camera at the QR code"
        showCamera = true
        isScanning = true
        verificationResult = nil
        receivedCreatedAt = nil
        logs.removeAll()
    }

    private func finishReading() throws {
        let sorted = chunkList.sorted { $0.key < $1.key }
        let zipB91 = sorted.map(\.value).joined()

        appendLog("📦 Decoding Base91...")
        let zipBytes = try Base91.decode(zipB91)

        appendLog("🗜 Decompressing XZ...")
        let outputData = try XZDecompressor.decompress(Data(zipBytes))

        guard let outputStr = String(data: outputData, encoding: .utf8) else {
            throw QRReceiveError.invalidUTF8
        }

        resultText = outputStr
        receivedJSON = outputStr
        showCamera = false
        appendLog("✅ JSON reconstructed successfully")

        processReceivedJSON(outputStr)
    }

    private func findHeaderEnd(in value: String) throws -> Int {
        guard let range = value.range(of: "\n\n") else {
            throw QRReceiveError.invalidHeader
        }
        return value.distance(from: value.startIndex, to: range.lowerBound)
    }

    private func show(error: Error) {
        errorMessage = error.localizedDescription
        showErrorAlert = true
        overlayColor = .red
        statusText = "Read error"
        appendLog("❌ \(error.localizedDescription)")
    }

    private func appendLog(_ line: String) {
        logs.append(line)
    }

    private func processReceivedJSON(_ json: String) {
        appendLog("🔍 Processing JSON...")

        guard let data = json.data(using: .utf8) else {
            appendLog("❌ Failed to convert JSON string to Data")
            return
        }

        if let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let created = parsed["createdAt"] as? String {
            receivedCreatedAt = created
            appendLog("📅 createdAt found: \(created)")
        }

        Task {
            guard let agent = agent else {
                appendLog("⚠️ Agent unavailable")
                return
            }

            do {
                let tuple = try await agent.proofCommandV2.processPresentationOffline(
                    presentationMessage: json
                )

                let valid = tuple.1
                verificationResult = valid

                appendLog(valid ? "✅ Verified" : "❌ Not valid")
            } catch {
                verificationResult = false
                appendLog("❌ Verification failed: \(error.localizedDescription)")
            }
        }
    }
}

enum QRReceiveError: LocalizedError {
    case invalidHeader
    case invalidUTF8

    var errorDescription: String? {
        switch self {
        case .invalidHeader:
            return "Invalid QR chunk header."
        case .invalidUTF8:
            return "Could not convert result to UTF-8 text."
        }
    }
}
