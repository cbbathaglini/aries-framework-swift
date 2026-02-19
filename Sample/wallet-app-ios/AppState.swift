//
//  AppState.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 10/10/25.
//

import SwiftUI

enum AppRoute: Equatable {
    case none
    case connectionsHistorical

}

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var currentRoute: AppRoute = .none
    @Published var isWalletActive: Bool = true

    private init() {}
    
    func reset() {
        isWalletActive = false
    }

    func startAgain() {
        isWalletActive = true
    }
}
