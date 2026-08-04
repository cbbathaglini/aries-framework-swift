//
//  OpenWalletView.swift
//  wallet-app-ios
//

import SwiftUI

struct OpenWalletView: View {
    @StateObject var walletState = WalletState()
    @StateObject var walletOpener = WalletOpener()

    var body: some View {
        VStack {
            if walletState.loggedOut {
                LoggedOutView {
                    Task {
                        walletState.loggedOut = false
                        await walletOpener.openWallet(walletState: walletState)
                    }
                }
            }
            else if walletState.walletOpened {
                WalletMainView(onLogout: handleLogout)
            }
            else {
                VStack {
                    Text("Opening your wallet...")
                    ProgressView().padding(.top)
                }
            }
        }
        .task {
            if !walletState.walletOpened && !walletState.loggedOut {
                await walletOpener.openWallet(walletState: walletState)
            }
        }
    }

    private func handleLogout() {
        Task {
            try? await agent?.shutdown()
            await MainActor.run {
                walletState.walletOpened = false
                walletState.loggedOut = true
            }
        }
    }
}
