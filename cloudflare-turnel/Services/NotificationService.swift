//
//  NotificationService.swift
//  cloudflare-turnel
//

import Foundation
import UserNotifications

@MainActor
class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    func sendTunnelConnected(name: String, url: String?) {
        let content = UNMutableNotificationContent()
        content.title = "Tunnel Connected"
        if let url = url {
            content.body = "\(name) is now available at \(url)"
        } else {
            content.body = "\(name) is now connected"
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func sendTunnelDisconnected(name: String) {
        let content = UNMutableNotificationContent()
        content.title = "Tunnel Disconnected"
        content.body = "\(name) has been stopped"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func sendTunnelError(name: String, error: String) {
        let content = UNMutableNotificationContent()
        content.title = "Tunnel Error"
        content.body = "\(name): \(error.prefix(100))"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func sendURLCopied(url: String) {
        let content = UNMutableNotificationContent()
        content.title = "URL Copied"
        content.body = url
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
