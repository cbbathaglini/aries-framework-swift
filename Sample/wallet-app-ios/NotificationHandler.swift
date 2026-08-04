//
//  NotificationHandler.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 14/10/25.
//

import SwiftUI
import Foundation
import Combine

enum NotificationType: String, Codable {
    case issueCredentialv1
    case issueCredentialv2
    case issuedCredentialDetailv1
    case issuedCredentialDetailv2
    case acceptProofRequestv1
    case acceptProofRequestv2
    case declineCredentialv2
    case proofRequestv1
    case proofRequestv2
    case presentationProofv1
    case presentationProofv2
    case sendBluetoothPresentationProofv2
    case proofDonev2
    case abandonedProofv2
    case declineProofv2
    case proofRequestSent
    case receivedBluetoothPresentationProofv2
    case proofv2
    case revocationNotificationV2
    case connection
    case error                        
    case other
}

struct NotificationItem: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let message: String
    let date: Date
    var isRead: Bool = false
    var type: NotificationType = .other
    var credentialId: String? = nil
    var proofRecordId: String? = nil
    var presentationMessageId: String? = nil
}

@MainActor
class NotificationHandler: ObservableObject {
    static let shared = NotificationHandler()
        
    @Published var notifications: [NotificationItem] = [] {
        didSet { saveNotifications() }
    }
    @Published var unreadCount: Int = 0
    
    private let storageKey = "saved_notifications"
    
    private init() {
        loadNotifications()
    }
    
    func addNotification(title: String, message: String, type: NotificationType? = nil, credentialId: String? = nil, proofRecordId: String? = nil, presentationMessageId:String?=nil) {
        Task { @MainActor in
            let newNotification = NotificationItem(
                id: UUID(),
                title: title,
                message: message,
                date: Date(),
                isRead: false,
                type: type ?? .other,
                credentialId: credentialId,
                proofRecordId: proofRecordId,
                presentationMessageId: presentationMessageId
            )

            notifications.insert(newNotification, at: 0)
            unreadCount = notifications.filter { !$0.isRead }.count
            saveNotifications()

            print("🔔 Notification added. Total unread: \(unreadCount)")
        }
    }
    
    func markAllAsRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
        unreadCount = 0
        saveNotifications()
    }
    
    
    public func saveNotifications() {
        do {
            let data = try JSONEncoder().encode(notifications)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("⚠️ Failed to save notifications: \(error)")
        }
    }
    
    private func loadNotifications() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            notifications = try JSONDecoder().decode([NotificationItem].self, from: data)
            unreadCount = notifications.filter { !$0.isRead }.count
            print("✅ \(notifications.count) notifications loaded from disk")
        } catch {
            print("⚠️ Failed to load notifications: \(error)")
            notifications = []
        }
    }
    
    func clearAllNotifications() {
        notifications.removeAll()
        unreadCount = 0
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("🧹 All notifications was cleaned")
    }
}
