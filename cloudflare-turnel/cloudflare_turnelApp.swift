//
//  cloudflare_turnelApp.swift
//  iturnel
//
//  Created by TrustShop Develop on 29/12/25.
//

import SwiftUI

@main
struct CloudflareTunnelApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        // Menu bar app
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            MenuBarLabel(hasActiveTunnels: appState.hasActiveTunnels)
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Settings {
            SettingsView()
        }
    }
}

struct MenuBarLabel: View {
    let hasActiveTunnels: Bool

    var body: some View {
        Image(hasActiveTunnels ? "MenuBarIconFill" : "MenuBarIconEmpty")
            .renderingMode(.template)
    }
}
