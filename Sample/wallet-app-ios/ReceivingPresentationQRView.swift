//
//  ReceivingPresentationQRView.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 11/03/26.
//


import SwiftUI
import AriesFramework

struct ReceivingPresentationQRView: View {
    @StateObject private var viewModel = ReceivingPresentationQRViewModel()

    var body: some View {
        ZStack {
            if viewModel.showCamera {
                QRScannerView(
                    isScanning: $viewModel.isScanning,
                    onCodeScanned: { code in
                        viewModel.handleScannedQRCode(code)
                    }
                )
                .ignoresSafeArea()

                VStack {
                    Spacer()

                    RoundedRectangle(cornerRadius: 16)
                        .stroke(viewModel.overlayColor, lineWidth: 4)
                        .frame(width: 260, height: 260)
                        .background(Color.clear)
                        .padding(.bottom, 80)

                    Text(viewModel.statusText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .padding(.bottom, 40)
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Receiving Presentation")
                            .font(.title2)
                            .bold()

                        HStack {
                            Image(systemName: "tray.and.arrow.down.fill")
                                .foregroundColor(.white)
                            Text("QR read successfully")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)

                        if let createdAt = viewModel.receivedCreatedAt {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("📅 Created At")
                                    .font(.headline)

                                Text(createdAt)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }

                        if let verified = viewModel.verificationResult {
                            HStack {
                                Image(systemName: verified ? "checkmark.shield.fill" : "xmark.shield.fill")
                                    .foregroundColor(.white)
                                Text(verified ? "Verified successfully" : "Verification failed")
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(verified ? Color.green : Color.red)
                            .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("📦 Result")
                                .font(.headline)

                            ScrollView {
                                Text(viewModel.resultText)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            .frame(maxHeight: 320)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("🪵 Logs")
                                .font(.headline)

                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(viewModel.logs.enumerated()), id: \.offset) { _, log in
                                        Text(log)
                                            .font(.system(.footnote, design: .monospaced))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .frame(maxHeight: 220)
                        }

                        Button("Scan Again") {
                            viewModel.reset()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Receive QR")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Erro", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
