//
//  QRCodeHandler.swift
//  wallet-app-ios
//

import SwiftUI
import CodeScanner
import os
import AriesFramework

class QRCodeHandler {
    let logger = Logger(subsystem: "AriesApp", category: "QRCodeHandler")
    let credentialHandler = CredentialHandler.shared
    let notificationHandler = NotificationHandler.shared
    
    public func receiveInvitation(url: String) {
        logger.info("receiveInvitation init \(url)")
        
        Task {
            do {
                let (_, connection) = try await agent!.oob.receiveInvitationFromUrl(url)
                logger.info("Connected with \(connection?.theirLabel ?? "unknown agent")")
                
                await MainActor.run {
                    notificationHandler.addNotification(
                        title: "Connection established",
                        message: "Connected with \(connection?.theirLabel ?? "Unknown agent")"
                    )
                }

            } catch {
                logger.error("Error in receiveInvitation \(error.localizedDescription)")
                
                await MainActor.run {
                    notificationHandler.addNotification(
                        title: "Connection failed",
                        message: "Failed to connect with \(url.prefix(50))..."
                    )
                }
            }
        }
    }

    @MainActor
    public func handleResult(_ result: Result<ScanResult, ScanError>) {
        switch result {
        case .success(let result):
            print("Scanned code: [\(result.string)]")
            credentialHandler.menu = nil
            receiveInvitation(url: result.string.trimmingCharacters(in: .whitespacesAndNewlines))
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
}
