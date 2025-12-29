//
//  Constants.swift
//  iturnel
//

import Foundation

enum Constants {
    static let appName = "iTurnel"
    static let bundleIdentifier = "io.trustshop.iturnel"
    static let keychainService = "io.trustshop.iturnel.tokens"

    static let defaultCloudflaredPaths = [
        "/opt/homebrew/bin/cloudflared",
        "/usr/local/bin/cloudflared",
        "/usr/bin/cloudflared"
    ]

    static let presetsFileName = "presets.json"
    static let historyFileName = "history.json"

    enum Regex {
        static let trycloudflareURL = #"https://[a-zA-Z0-9-]+\.trycloudflare\.com"#
        static let customDomainURL = #"https://[a-zA-Z0-9-]+\.[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#
        static let connectionRegistered = "Registered tunnel connection|Connection.*registered|INF.*Registered"
        static let tunnelReady = "Your quick Tunnel has been created"
    }
}
