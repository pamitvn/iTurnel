//
//  SettingsView.swift
//  iturnel
//

import SwiftUI

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general
        case tokens
        case about
    }

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)

            TokenSettingsView()
                .tabItem {
                    Label("Tokens", systemImage: "key")
                }
                .tag(Tabs.tokens)

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(Tabs.about)
        }
        .frame(width: 450, height: 320)
    }
}

struct GeneralSettingsView: View {
    @State private var settings = PersistenceService.shared.loadSettings()
    @State private var launchAtLogin = false
    @State private var cloudflaredExists = false

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        Task { @MainActor in
                            do {
                                if newValue {
                                    try LaunchAgentService.shared.enable()
                                } else {
                                    try LaunchAgentService.shared.disable()
                                }
                            } catch {
                                print("Failed to toggle launch agent: \(error)")
                            }
                        }
                    }

                Toggle("Auto-start Presets on Launch", isOn: $settings.autoStartPresetsOnLaunch)
                    .onChange(of: settings.autoStartPresetsOnLaunch) { _, _ in
                        saveSettings()
                    }
            }

            Section("Notifications") {
                Toggle("Show Notifications", isOn: $settings.showNotifications)
                    .onChange(of: settings.showNotifications) { _, _ in
                        saveSettings()
                    }

                Toggle("Copy URL on Connect", isOn: $settings.copyURLOnConnect)
                    .onChange(of: settings.copyURLOnConnect) { _, _ in
                        saveSettings()
                    }
            }

            Section("cloudflared Binary") {
                HStack {
                    TextField("Path", text: $settings.cloudflaredPath)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: settings.cloudflaredPath) { _, _ in
                            checkCloudflaredExists()
                            saveSettings()
                        }

                    Button("Browse...") {
                        browseForCloudflared()
                    }
                }

                HStack {
                    Circle()
                        .fill(cloudflaredExists ? .green : .red)
                        .frame(width: 8, height: 8)

                    Text(cloudflaredExists ? "cloudflared found" : "cloudflared not found")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if !cloudflaredExists {
                        Link("Install via Homebrew", destination: URL(string: "https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/")!)
                            .font(.caption)
                    }
                }
            }

            Section("Defaults") {
                Picker("Default Protocol", selection: $settings.defaultProtocol) {
                    ForEach(TunnelProtocol.allCases, id: \.self) { proto in
                        Text(proto.rawValue.uppercased()).tag(proto)
                    }
                }
                .onChange(of: settings.defaultProtocol) { _, _ in
                    saveSettings()
                }

                HStack {
                    TextField("Default Host", text: $settings.defaultLocalHost)
                        .textFieldStyle(.roundedBorder)

                    TextField("Default Port", value: $settings.defaultLocalPort, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                .onChange(of: settings.defaultLocalHost) { _, _ in
                    saveSettings()
                }
                .onChange(of: settings.defaultLocalPort) { _, _ in
                    saveSettings()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            launchAtLogin = LaunchAgentService.shared.isEnabled
            checkCloudflaredExists()
        }
    }

    private func saveSettings() {
        PersistenceService.shared.saveSettings(settings)
    }

    private func checkCloudflaredExists() {
        cloudflaredExists = FileManager.default.fileExists(atPath: settings.cloudflaredPath)
    }

    private func browseForCloudflared() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Select the cloudflared binary"

        if panel.runModal() == .OK, let url = panel.url {
            settings.cloudflaredPath = url.path
            checkCloudflaredExists()
            saveSettings()
        }
    }
}

struct TokenSettingsView: View {
    @State private var defaultToken = ""
    @State private var showToken = false
    @State private var isSaved = false

    var body: some View {
        Form {
            Section("Default Tunnel Token") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Store your Cloudflare Tunnel token securely in the Keychain")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        if showToken {
                            TextField("Token", text: $defaultToken)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("Token", text: $defaultToken)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button {
                            showToken.toggle()
                        } label: {
                            Image(systemName: showToken ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.plain)
                    }

                    HStack {
                        Button("Save Token") {
                            saveToken()
                        }
                        .disabled(defaultToken.isEmpty)

                        if isSaved {
                            Text("Saved!")
                                .font(.caption)
                                .foregroundColor(.green)
                        }

                        Spacer()

                        if KeychainService.getToken() != nil {
                            Button("Clear Token") {
                                clearToken()
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }

            Section("Getting a Token") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("To get a tunnel token:")
                        .font(.caption)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("1. Go to the Cloudflare Zero Trust dashboard")
                        Text("2. Navigate to Networks > Tunnels")
                        Text("3. Create a new tunnel or select existing")
                        Text("4. Copy the tunnel token")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    Link("Open Zero Trust Dashboard", destination: URL(string: "https://one.dash.cloudflare.com/")!)
                        .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            if let token = KeychainService.getToken() {
                defaultToken = token
            }
        }
    }

    private func saveToken() {
        do {
            try KeychainService.saveToken(defaultToken)
            isSaved = true

            // Update settings
            var settings = PersistenceService.shared.loadSettings()
            settings.defaultTunnelToken = defaultToken
            PersistenceService.shared.saveSettings(settings)

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isSaved = false
            }
        } catch {
            print("Failed to save token: \(error)")
        }
    }

    private func clearToken() {
        KeychainService.deleteToken()
        defaultToken = ""

        // Update settings
        var settings = PersistenceService.shared.loadSettings()
        settings.defaultTunnelToken = nil
        PersistenceService.shared.saveSettings(settings)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "network")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            VStack(spacing: 4) {
                Text("iTurnel")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Manage Cloudflare Tunnels from your menu bar. Forward local ports to the internet securely.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Divider()

            VStack(spacing: 8) {
                Link("Cloudflare Tunnel Documentation", destination: URL(string: "https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/")!)
                    .font(.caption)

                Link("Zero Trust Dashboard", destination: URL(string: "https://one.dash.cloudflare.com/")!)
                    .font(.caption)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
}
