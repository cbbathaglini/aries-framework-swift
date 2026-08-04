import SwiftUI
import AriesFramework

struct NotificationsView: View {
    @ObservedObject var notificationHandler = NotificationHandler.shared
    @ObservedObject var credentialHandler = CredentialHandler.shared

    @State private var showProofDetails = false
    @State private var selectedProof: String?

    @State private var showCredentialDetail = false
    @State private var selectedCredentialId: String?

    
    var body: some View {
        NavigationView {
            List {
                ForEach(notificationHandler.notifications) { notification in
                    VStack(alignment: .leading, spacing: 6) {
                        headerRow(notification)
                        
                        Text(notification.message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(notification.date, style: .time)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if notification.type == .declineCredentialv2 {
                            Text("Credential declined")
                                .font(.headline)
                                .foregroundColor(.red)
                                .padding(.top, 6)
                        }
                    
                        if notification.type == .issueCredentialv2 {
                            issueCredV2(notification: notification)
                        }
                        
                        if notification.type == .acceptProofRequestv2 {
                            proofActions(notification)
                        }
                        
                        if notification.type == .issuedCredentialDetailv2 {
                            Button("Details of credential") {
                                Task {
                                    await openCredentialDetail(notification: notification)
                                    markAsRead(notification)
                                }
                            }
                            .buttonStyle(.bordered)
                            .padding(.top, 4)
                        }
                        
                        if notification.type == .revocationNotificationV2 {
                            Button("Details of revoked credential") {
                                Task {
                                    await openCredentialDetail(notification: notification)
                                    markAsRead(notification)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .padding(.top, 4)
                        }
                        
                        if notification.type == .proofDonev2 {
                            proofDoneActions(notification)
                        }
                        
                        
                        if notification.type == .proofRequestv2 {
                            Button("Details of proof") {
                                selectedProof = notification.proofRecordId
                                showProofDetails = true
                                markAsRead(notification)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .padding(.top, 4)
                        }
                        
                        if notification.type == .proofRequestSent {
                            Button("Request sent") {
                                selectedProof = notification.proofRecordId
                                showProofDetails = true
                                markAsRead(notification)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Mark all as read") {
                        notificationHandler.markAllAsRead()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        notificationHandler.clearAllNotifications()
                    } label: {
                        Label("Clean all", systemImage: "trash")
                    }
                }
            }
            .sheet(isPresented: $showCredentialDetail) {
                if let credentialId = selectedCredentialId {
                    CredentialDetailLoaderView(credentialId: credentialId)
                } else {
                    Text("Loading credential details...")
                }
            }
            .sheet(isPresented: $showProofDetails) {
                if let notification = notificationHandler.notifications.first(where: { notif in
                    notif.proofRecordId == selectedProof || notif.presentationMessageId == selectedProof
                }) {
                    
                    switch notification.type {
                        
                    case .proofDonev2:
                        ProofDetailLoaderView(notification: notification)
                        
                    case .proofRequestv2, .acceptProofRequestv2:
                        RequestProofView(
                            presentationMessageId: notification.presentationMessageId,
                            proofRecordId: notification.proofRecordId,
                            status: notification.type
                        )
                        
                    case .declineProofv2:
                        ProofDetailLoaderView(notification: notification)
                        
                    default:
                        VStack {
                            Text("Notification type not supported")
                        }
                    }
                    
                } else {
                    VStack(spacing: 16) {
                        ProgressView("Loading details...")
                        Text("Waiting for presentation data")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        
    }

    @ViewBuilder
    private func headerRow(_ notification: NotificationItem) -> some View {
        HStack {
            Text(notification.title)
                .font(.headline)
            if !notification.isRead {
                Circle().fill(Color.blue).frame(width: 8, height: 8)
            }
            Spacer()
            Button {
                deleteNotification(notification)
            } label: {
                Image(systemName: "trash").foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }

    @ViewBuilder
    private func issueCredV2(notification: NotificationItem) -> some View {

        if notification.type == .declineCredentialv2 {
            Text("Credential declined")
                .font(.headline)
                .foregroundColor(.red)
                .padding(.top, 6)
            
        }else{
        
            if !notification.isRead {
                HStack {
                    Button {
                        Task { await openCredentialDetail(notification: notification) }
                    } label: {
                        Image(systemName: "eye.fill")
                            .frame(width: 20)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)

                    Button("Accept") {
                        credentialHandler.getCredential(version: "2.0")
                        markAsRead(notification)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Decline") {
                        if let index = notificationHandler.notifications.firstIndex(where: { $0.id == notification.id }) {
                            notificationHandler.notifications[index].type = .declineCredentialv2
                            notificationHandler.saveNotifications()
                        }

                        markAsRead(notification)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(.top, 4)
                
            } else {
                Text("Credential sent")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
    }
    
    @ViewBuilder
    private func proofDoneActions(_ notification: NotificationItem) -> some View {
        Button {
            showProofDetails = true
        } label: {
            Text("Details of proof")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .padding(.top, 4)
    
    }

    @ViewBuilder
    private func proofActions(_ notification: NotificationItem) -> some View {

        let proofDoneExists = notificationHandler.notifications.contains {
            $0.type == .proofDonev2 && $0.proofRecordId == notification.proofRecordId
        }

        let proofDeclinedExists = notificationHandler.notifications.contains {
            $0.type == .declineProofv2 && $0.proofRecordId == notification.proofRecordId
        }

        if proofDeclinedExists {
            Button {
                selectedProof = notification.proofRecordId
                showProofDetails = true
                markAsRead(notification)
            } label: {
                Label("Declined proof — see details", systemImage: "xmark.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .foregroundColor(.red)
                    .font(.callout)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .padding(.top, 4)

        } else if proofDoneExists {
            Text("✅ Proof done")
                .font(.caption)
                .foregroundColor(.green)
                .padding(.top, 4)

        } else {
            HStack(spacing: 12) {

                Button("Details") {
                    selectedProof = notification.presentationMessageId ?? notification.proofRecordId
                    showProofDetails = true
                    markAsRead(notification)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                Button("Decline") {
                    Task {
                        guard let agent = agent,
                              let proofId = notification.proofRecordId else { return }

                        do {
                            try await agent.proofCommandV2.declineRequest(proofRecordId: proofId)

                            notificationHandler.addNotification(
                                title: "Proof declined",
                                message: "You declined a proof solicitation",
                                type: .declineProofv2,
                                proofRecordId: proofId
                            )

                            markAsRead(notification)

                        } catch {
                            print("❌ Error declining proof -> \(error)")
                        }
                    }
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(.top, 4)
        }
    }

    
    private func markAsRead(_ notification: NotificationItem) {
        guard let index = notificationHandler.notifications.firstIndex(where: { $0.id == notification.id }) else {
            return
        }

        notificationHandler.notifications[index].isRead = true

        notificationHandler.unreadCount =
            notificationHandler.notifications.filter { !$0.isRead }.count

        notificationHandler.saveNotifications()
    }
   

    private func deleteNotification(_ notification: NotificationItem) {
        if let index = notificationHandler.notifications.firstIndex(of: notification) {
            withAnimation {
                notificationHandler.notifications.remove(at: index)
            }
            notificationHandler.unreadCount = notificationHandler.notifications.filter { !$0.isRead }.count
            notificationHandler.saveNotifications()
            print("🗑️ Removed notification: \(notification.title)")
        }
    }

    
    private func openCredentialDetail(notification: NotificationItem) async {
            guard let credentialId = notification.credentialId else {
                print("⚠️ Notification without credentialId.")
                return
            }

            await MainActor.run {
                selectedCredentialId = credentialId
                showCredentialDetail = true
            }
        }
    
}
