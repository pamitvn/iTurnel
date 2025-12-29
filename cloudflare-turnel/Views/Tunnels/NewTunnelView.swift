//
//  NewTunnelView.swift
//  cloudflare-turnel
//

import SwiftUI

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

    private var isValid: Bool {
        !name.isEmpty && !localPort.isEmpty && Int(localPort) != nil &&
        (tunnelType == .quickTunnel || !effectiveToken.isEmpty)
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

                        // Authentication
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
            tunnelToken: tunnelType == .namedTunnel ? effectiveToken : nil,
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
}

#Preview {
    NewTunnelView()
        .environment(AppState())
        .frame(width: 380)
}
