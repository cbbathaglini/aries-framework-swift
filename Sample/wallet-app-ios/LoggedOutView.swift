//
//  LoggedOutView.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 13/11/25.
//

import SwiftUI

struct LoggedOutView: View {
    var onStartAgain: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("You have closed your wallet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Your session has ended. You can reopen the wallet at any time.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onStartAgain) {
                Text("Start Wallet Again")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 80)
    }
}
