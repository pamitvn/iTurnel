//
//  PresetListView.swift
//  iturnel
//

import SwiftUI

struct PresetListView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if appState.presets.isEmpty {
                    EmptyStateView(
                        icon: "star",
                        title: "No Presets",
                        message: "Save tunnel configurations as presets for quick access"
                    )
                    .frame(maxWidth: .infinity, minHeight: 150)
                } else {
                    ForEach(appState.presets) { preset in
                        PresetRowView(
                            preset: preset,
                            onEdit: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    appState.editingPreset = preset
                                }
                            }
                        )
                    }
                }
            }
            .padding()
        }
    }
}

struct PresetRowView: View {
    @Environment(AppState.self) private var appState
    let preset: Preset
    let onEdit: () -> Void

    @State private var isHovered = false
    @State private var isStarting = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(preset.autoStartOnLaunch ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: preset.autoStartOnLaunch ? "bolt.fill" : "star.fill")
                    .foregroundColor(preset.autoStartOnLaunch ? .orange : .blue)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(preset.name)
                        .font(.system(.body, weight: .medium))

                    if preset.configuration.tunnelType == .namedTunnel {
                        Image(systemName: "key.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }

                Text(preset.configuration.localURL)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if preset.usageCount > 0 {
                    Text("Used \(preset.usageCount) time\(preset.usageCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions
            if isHovered {
                HStack(spacing: 8) {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Edit Preset")

                    Button {
                        appState.deletePreset(preset)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete Preset")
                }
            }

            // Start button
            Button {
                isStarting = true
                Task {
                    await appState.startTunnelFromPreset(preset)
                    isStarting = false
                }
            } label: {
                if isStarting {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .buttonStyle(.plain)
            .disabled(isStarting)
            .help("Start Tunnel")
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

struct PresetFormView: View {
    @Environment(AppState.self) private var appState

    let preset: Preset?
    let isEditing: Bool

    @State private var name = ""
    @State private var localHost = "localhost"
    @State private var localPort = "8080"
    @State private var selectedProtocol: TunnelProtocol = .http
    @State private var tunnelType: TunnelType = .namedTunnel
    @State private var autoStartOnLaunch = false

    init(preset: Preset? = nil, isEditing: Bool = false) {
        self.preset = preset
        self.isEditing = isEditing
    }

    private func closeForm() {
        withAnimation(.easeInOut(duration: 0.2)) {
            appState.editingPreset = nil
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

                Text(isEditing ? "Edit Preset" : "New Preset")
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

            // Form content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Preset Name", text: $name)
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
                    }

                    Divider()

                    Toggle("Auto-start on Launch", isOn: $autoStartOnLaunch)
                }
                .padding()
            }

            Divider()

            HStack {
                Button("Cancel") {
                    closeForm()
                }

                Spacer()

                Button(isEditing ? "Save" : "Create") {
                    savePreset()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .onAppear {
            if let preset = preset {
                name = preset.name
                localHost = preset.configuration.localHost
                localPort = String(preset.configuration.localPort)
                selectedProtocol = preset.configuration.tunnelProtocol
                tunnelType = preset.configuration.tunnelType
                autoStartOnLaunch = preset.autoStartOnLaunch
            }
        }
    }

    private func savePreset() {
        let config = TunnelConfiguration(
            name: name,
            localHost: localHost,
            localPort: Int(localPort) ?? 8080,
            tunnelProtocol: selectedProtocol,
            tunnelType: tunnelType
        )

        if isEditing, let existing = preset {
            var updated = existing
            updated.name = name
            updated.configuration = config
            updated.autoStartOnLaunch = autoStartOnLaunch
            appState.updatePreset(updated)
        } else {
            let newPreset = Preset(
                name: name,
                configuration: config,
                autoStartOnLaunch: autoStartOnLaunch
            )
            appState.addPreset(newPreset)
        }

        closeForm()
    }
}

#Preview {
    PresetListView()
        .environment(AppState())
        .frame(width: 360)
}
