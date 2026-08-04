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
    @State private var isConnecting = false
    @State private var connectionMessage: String? = nil
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
            homeTab
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            NotificationsView()
                .tabItem {
                    Label("Notifications", systemImage: "bell.fill")
                }
                .badge(notificationHandler.unreadCount)

            settingsTab
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }

    // MARK: - Home Tab
    private var homeTab: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    quickActionsSection
                    walletSections
                    invitationSection
                }
                .padding()
                .autocorrectionDisabled()
            }
            .navigationTitle("Wallet")
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
                ProgressView("Processing...")
                    .padding()
            }
        }
    }

    // MARK: - Settings Tab
    private var settingsTab: some View {
        NavigationView {
            List {
                Section("Wallet") {
                    actionRow(
                        icon: "arrow.counterclockwise.circle.fill",
                        color: .orange,
                        title: "Reset Wallet",
                        subtitle: "Delete all local data, connections and proof records"
                    ) {
                        showResetConfirm = true
                    }

                    actionRow(
                        icon: "rectangle.portrait.and.arrow.right",
                        color: .red,
                        title: "Logout",
                        subtitle: "Close the wallet and end the session"
                    ) {
                        onLogout()
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .overlay(alignment: .bottom) {
                if isLoggingOut || isResetting {
                    ProgressView("Please wait...")
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 20)
                }
            }
            .alert("Reset wallet?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}

                Button("Reset", role: .destructive) {
                    Task { await performReset() }
                }
            } message: {
                Text("This will permanently remove all locally stored wallet data and reset connections, credentials, and proof records.")
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
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 14) {
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 34))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(LinearGradient(colors: [Color.blue, Color.blue.opacity(0.7)],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text("Your Digital Wallet")
                    .font(.headline)
                Text("Credentials, connections and proofs in one place")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        VStack(alignment: .leading, spacing: 12) {
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
            }
        }
    }

    // MARK: - Invitation Input
    private var invitationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connect via Invitation URL")
                .font(.headline)

            HStack {
                TextField("Paste invitation URL", text: $invitation)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.go)
                    .onSubmit { connectToInvitation() }

                Button(action: connectToInvitation) {
                    if isConnecting {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 20, height: 20)
                    } else {
                        Text("Connect")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isConnecting || invitation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let message = connectionMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(message.hasPrefix("✅") ? .green : .red)
            }
        }
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

    private func actionRow(icon: String, color: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(color)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Actions
    private func connectToInvitation() {
        let url = invitation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty, !isConnecting else { return }

        isConnecting = true
        connectionMessage = nil

        Task {
            do {
                try await QRCodeHandler().receiveInvitationAsync(url: url)
                await MainActor.run {
                    connectionMessage = "✅ Invitation received"
                    invitation = ""
                    isConnecting = false
                }
            } catch {
                await MainActor.run {
                    connectionMessage = "❌ Could not connect: \(error.localizedDescription)"
                    isConnecting = false
                }
            }
        }
    }

    @MainActor
    private func performReset() async {
        guard !isResetting else { return }
        isResetting = true
        defer { isResetting = false }

        do {
            guard let agent = agent else {
                throw NSError(domain: "WalletApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Agent not available"])
            }

            try await agent.reset()
            clearInMemoryState()
            onLogout()
        } catch {
            resetErrorMessage = "\(error)"
        }
    }

    @MainActor
    private func clearInMemoryState() {
        invitation = ""
        connectionMessage = nil
        notificationHandler.unreadCount = 0
        notificationHandler.clearAllNotifications()
    }
}

#Preview {
    WalletMainView(onLogout: {})
}
