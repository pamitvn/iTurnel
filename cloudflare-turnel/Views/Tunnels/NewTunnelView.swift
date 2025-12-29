//
//  NewTunnelView.swift
//  iturnel
//

import SwiftUI
import UniformTypeIdentifiers

struct NewTunnelView: View {
    @Environment(AppState.self) private var appState

    @State private var name = ""
    @State private var localHost = "localhost"
    @State private var localPort = "8080"
    @State private var selectedProtocol: TunnelProtocol = .http
    @State private var tunnelType: TunnelType = .namedTunnel
    @State private var tunnelToken = ""
    @State private var saveAsPreset = false
    @State private var autoStartOnLaunch = false
    @State private var useDefaultToken = true

    // Config mode state
    @State private var namedTunnelMode: NamedTunnelMode = .token
    @State private var tunnelUUID = ""
    @State private var credentialsPath = ""
    @State private var ingressRules: [IngressRule] = []

    private var isValid: Bool {
        guard !name.isEmpty && !localPort.isEmpty && Int(localPort) != nil else {
            return false
        }

        if tunnelType == .quickTunnel {
            return true
        }

        // Named tunnel validation
        if namedTunnelMode == .token {
            return !effectiveToken.isEmpty
        } else {
            // Config mode requires UUID, credentials, and at least one ingress rule
            return !tunnelUUID.isEmpty && !credentialsPath.isEmpty && !ingressRules.isEmpty
        }
    }

    private var effectiveToken: String {
        useDefaultToken ? (appState.settings.defaultTunnelToken ?? "") : tunnelToken
    }

    private func closeForm() {
        withAnimation(.easeInOut(duration: 0.2)) {
            appState.showingNewTunnel = false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    closeForm()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("New Tunnel")
                    .font(.headline)

                Spacer()

                // Invisible spacer for centering
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .opacity(0)
            }
            .padding()

            Divider()

            // Form content in ScrollView
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Basic info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("My Tunnel", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tunnel Type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("", selection: $tunnelType) {
                            ForEach(TunnelType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Divider()

                    // Local Service
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Local Service")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Protocol")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Picker("", selection: $selectedProtocol) {
                                    ForEach(TunnelProtocol.allCases, id: \.self) { proto in
                                        Text(proto.rawValue.uppercased()).tag(proto)
                                    }
                                }
                                .frame(width: 80)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Host")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("localhost", text: $localHost)
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Port")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("8080", text: $localPort)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 70)
                            }
                        }

                        Text("\(selectedProtocol.rawValue)://\(localHost):\(localPort)")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.top, 2)
                    }

                    if tunnelType == .namedTunnel {
                        Divider()

                        // Configuration Mode
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Configuration Mode")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Picker("", selection: $namedTunnelMode) {
                                ForEach(NamedTunnelMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text(namedTunnelMode == .token
                                ? "Ingress rules are configured in Cloudflare Dashboard"
                                : "Define local ingress rules below")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if namedTunnelMode == .token {
                            Divider()

                            // Token Authentication
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Authentication")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                if appState.settings.defaultTunnelToken != nil {
                                    Toggle("Use default token", isOn: $useDefaultToken)
                                }

                                if !useDefaultToken || appState.settings.defaultTunnelToken == nil {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Tunnel Token")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        SecureField("Enter your tunnel token", text: $tunnelToken)
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    Text("Get your token from the Cloudflare Zero Trust dashboard")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Divider()

                            // Config File Mode
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tunnel Configuration")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Tunnel UUID")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", text: $tunnelUUID)
                                        .textFieldStyle(.roundedBorder)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Credentials File")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Button("Browse...") {
                                            selectCredentialsFile()
                                        }
                                        .font(.caption)
                                    }
                                    TextField("~/.cloudflared/xxx.json", text: $credentialsPath)
                                        .textFieldStyle(.roundedBorder)
                                }

                                Text("Run 'cloudflared tunnel login' to create credentials")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Divider()

                            // Ingress Rules
                            IngressRulesListView(rules: $ingressRules)
                        }
                    }

                    Divider()

                    // Options
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Save as Preset", isOn: $saveAsPreset)

                        if saveAsPreset {
                            Toggle("Auto-start on Launch", isOn: $autoStartOnLaunch)
                                .padding(.leading, 20)
                        }
                    }
                }
                .padding()
            }

            Divider()

            // Actions
            HStack {
                Button("Cancel") {
                    closeForm()
                }

                Spacer()

                Button("Create Tunnel") {
                    createTunnel()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding()
        }
        .onAppear {
            localHost = appState.settings.defaultLocalHost
            localPort = String(appState.settings.defaultLocalPort)
            selectedProtocol = appState.settings.defaultProtocol
        }
    }

    private func createTunnel() {
        let config = TunnelConfiguration(
            name: name,
            localHost: localHost,
            localPort: Int(localPort) ?? 8080,
            tunnelProtocol: selectedProtocol,
            tunnelType: tunnelType,
            tunnelToken: tunnelType == .namedTunnel && namedTunnelMode == .token ? effectiveToken : nil,
            tunnelName: tunnelType == .namedTunnel && namedTunnelMode == .configFile ? tunnelUUID : nil,
            namedTunnelMode: namedTunnelMode,
            tunnelUUID: namedTunnelMode == .configFile ? tunnelUUID : nil,
            credentialsFilePath: namedTunnelMode == .configFile ? credentialsPath : nil,
            ingressRules: namedTunnelMode == .configFile ? ingressRules : [],
            noTLSVerify: false
        )

        if saveAsPreset {
            let preset = Preset(
                name: name,
                configuration: config,
                autoStartOnLaunch: autoStartOnLaunch
            )
            appState.addPreset(preset)
        }

        Task {
            await appState.startTunnel(config: config)
        }

        closeForm()
    }

    private func selectCredentialsFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json]
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".cloudflared")

        if panel.runModal() == .OK, let url = panel.url {
            credentialsPath = url.path
        }
    }
}

#Preview {
    NewTunnelView()
        .environment(AppState())
        .frame(width: 380)
}
