//
//  AppSettings.swift
//  iturnel
//

import Foundation

struct AppSettings: Codable, Equatable {
    var showNotifications: Bool
    var autoStartPresetsOnLaunch: Bool
    var cloudflaredPath: String
    var defaultProtocol: TunnelProtocol
    var defaultLocalHost: String
    var defaultLocalPort: Int
    var maxHistoryEntries: Int
    var copyURLOnConnect: Bool
    var defaultTunnelToken: String?

    static var `default`: AppSettings {
        AppSettings(
            showNotifications: true,
            autoStartPresetsOnLaunch: false,
            cloudflaredPath: detectCloudflaredPath(),
            defaultProtocol: .http,
            defaultLocalHost: "localhost",
            defaultLocalPort: 8080,
            maxHistoryEntries: 100,
            copyURLOnConnect: true,
            defaultTunnelToken: nil
        )
    }

    private static func detectCloudflaredPath() -> String {
        let paths = [
            "/opt/homebrew/bin/cloudflared",
            "/usr/local/bin/cloudflared",
            "/usr/bin/cloudflared"
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        return "/opt/homebrew/bin/cloudflared"
    }
}
