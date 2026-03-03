//
//  WalletMainView.swift
//  wallet-app-ios
//

import SwiftUI
import CodeScanner
import AriesFramework

enum MainMenu: Identifiable {
    case qrcode, list, loading, request
    var id: Int { hashValue }
}

struct WalletMainView: View {
    let onLogout: () -> Void
    @State private var invitation: String = ""
    @StateObject private var credentialHandler = CredentialHandler.shared
    @ObservedObject private var notificationHandler = NotificationHandler.shared
    @StateObject private var connectionHandler = ConnectionHandler.shared
    @StateObject private var appState = AppState.shared
    
    @State private var isLoggingOut = false
    @State private var isResetting = false
    @State private var showResetConfirm = false
    @State private var resetErrorMessage: String? = nil

    var body: some View {
        TabView {
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        
                        headerSection
                        quickActionsSection
                        walletSections
                        offlineSection
                        invitationSection
                    }
                    .padding()
                }
                .navigationTitle("Wallet App")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button("Reset") {
                            showResetConfirm = true
                        }
                        .disabled(isResetting || isLoggingOut)

                        Button("Logout") {
                            onLogout()
                        }
                        .disabled(isResetting || isLoggingOut)
                    }
                }
                .alert("Reset wallet?", isPresented: $showResetConfirm) {
                    Button("Cancel", role: .cancel) {}

                    Button("Reset", role: .destructive) {
                        Task { await performReset() }
                    }
                } message: {
                    Text("This will permanently remove all locally stored wallet data (Askar) and reset connections, credentials, and proof records. Wallet initialization will be required again.")
                }
                .alert("Failed to reset wallet", isPresented: Binding(
                    get: { resetErrorMessage != nil },
                    set: { if !$0 { resetErrorMessage = nil } }
                )) {
                    Button("OK", role: .cancel) { resetErrorMessage = nil }
                } message: {
                    Text(resetErrorMessage ?? "")
                }
            }
            .sheet(item: $credentialHandler.menu) { item in
                switch item {
                case .qrcode:
                    CodeScannerView(codeTypes: [.qr], completion: QRCodeHandler().handleResult)
                case .list:
                    CredentialListView()
                case .request:
                    RequestProofViewConnectionLess()
                case .loading:
                    ProgressView("Processing ...")
                        .padding()
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NotificationsView()
                .tabItem {
                    Label("Notifications", systemImage: "bell.fill")
                }
                .badge(notificationHandler.unreadCount)
        }
    }
    
    @MainActor
   private func performReset() async {
       guard !isResetting else { return }
       isResetting = true
       defer { isResetting = false }

       do {
        
           guard let agent = agent else {
               throw NSError(domain: "WalletApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Agent não disponível no AppState"])
           }

           try await agent.reset()
           clearInMemoryState()

           withAnimation {
               onLogout()
           }
       } catch {
           resetErrorMessage = "\(error)"
       }
   }
    
    @MainActor
       private func clearInMemoryState() {
           invitation = ""
           notificationHandler.unreadCount = 0
           notificationHandler.clearAllNotifications()
       }


    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Welcome to your Digital Wallet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Manage credentials, connections and proofs easily")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
            
            HStack(spacing: 16) {
                actionCard(
                    title: "Connect",
                    icon: "qrcode.viewfinder",
                    color: .blue
                ) {
                    credentialHandler.menu = .qrcode
                }

                actionCard(
                    title: "Credentials",
                    icon: "person.text.rectangle",
                    color: .purple
                ) {
                    credentialHandler.menu = .list
                }
            }
        }
    }

    // MARK: - Wallet Sections
    private var walletSections: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manage Wallet")
                .font(.headline)

            VStack(spacing: 12) {
                NavigationLink(destination: ConnectionsHistoricalView()) {
                    navigationRow(icon: "link.circle.fill", title: "Connection History", subtitle: "Review previous connections")
                }
                
                NavigationLink(destination: ProofListView()) {
                    navigationRow(icon: "checkmark.seal.fill", title: "Proofs", subtitle: "Manage proof requests")
                }
                
                NavigationLink(destination: InvitationView()) {
                    navigationRow(icon: "envelope.open.fill", title: "Generate Invitation", subtitle: "Create invitations for new agents")
                }
                
                NavigationLink(destination: W3cCredentialView()) {
                    navigationRow(icon: "envelope.open.fill", title: "W3C Credential", subtitle: "Eca w3c credential")
                }
                
            }
        }
    }

    // MARK: - Offline Features
    private var offlineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Offline Proofs")
                .font(.headline)
            
            VStack(spacing: 12) {
                Button("(Verifier) Request Proof") {
                    credentialHandler.menu = .request
                }
                .buttonStyle(.borderedProminent)
                
                NavigationLink("(Holder) Scan Proof", destination: VerifierProofView())
                NavigationLink("(Verifier) Receive Presentation", destination: ReceivingPresentationView())
                NavigationLink("(Holder) Presentation List", destination: PresentationListView())
                NavigationLink("(Verifier) Received Presentations", destination: ReceivedPresentationListView())
            }
        }
    }

    // MARK: - Invitation Input
    private var invitationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connect via Invitation URL")
                .font(.headline)
            HStack {
                TextField("Paste invitation URL", text: $invitation)
                    .textFieldStyle(.roundedBorder)
                Button("Clear") { invitation = "" }
                    .buttonStyle(.bordered)
                Button("Connect") {
                    QRCodeHandler().receiveInvitation(url: invitation)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Components
    private func actionCard(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .padding()
                    .background(color)
                    .clipShape(Circle())
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private func navigationRow(icon: String, title: String, subtitle: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 30)
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Logout Logic
    private func logout() async {
        guard !isLoggingOut else { return }
        isLoggingOut = true

        do {
            try await agent?.shutdown()

//            connectionHandler.connections = []
//            credentialHandler.credentials = []

        } catch {
            print("❌ Logout failed: \(error)")
        }

        withAnimation {
            appState.isWalletActive = false
        }
        
        isLoggingOut = false
    }
}

#Preview {
    WalletMainView(onLogout: {})
}
