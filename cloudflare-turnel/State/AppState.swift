//
//  AppState.swift
//  iturnel
//

import SwiftUI
import AppKit

@Observable
@MainActor
final class AppState {
    // Active tunnels
    var tunnels: [Tunnel] = []

    // Saved presets
    var presets: [Preset] = []

    // History
    var history: [HistoryEntry] = []

    // Settings
    var settings: AppSettings = .default

    // UI State
    var selectedTab: Tab = .tunnels
    var showingNewTunnel = false
    var showingSettings = false
    var isInitialized = false
    var editingPreset: Preset? = nil
    var showingClearHistoryConfirmation = false

    // Error handling
    var errorMessage: String?
    var showingError = false

    // Services
    private let cloudflaredService = CloudflaredService()
    private let configFileService = ConfigFileService()
    private let persistenceService = PersistenceService.shared
    private let notificationService = NotificationService.shared

    enum Tab: String, CaseIterable {
        case tunnels = "Tunnels"
        case presets = "Presets"
        case history = "History"
    }

    // MARK: - Computed Properties

    var hasActiveTunnels: Bool {
        tunnels.contains { $0.status == .connected || $0.status == .starting }
    }

    var connectedTunnelCount: Int {
        tunnels.filter { $0.status == .connected }.count
    }

    var statusText: String {
        let connected = connectedTunnelCount
        if connected == 0 {
            return "No active tunnels"
        } else if connected == 1 {
            return "1 tunnel active"
        } else {
            return "\(connected) tunnels active"
        }
    }

    // MARK: - Initialization

    func initialize() async {
        guard !isInitialized else { return }

        loadPersistedData()

        if settings.showNotifications {
            _ = await notificationService.requestPermission()
        }

        if settings.autoStartPresetsOnLaunch {
            await startAutoStartPresets()
        }

        isInitialized = true
    }

    private func loadPersistedData() {
        presets = persistenceService.loadPresets()
        history = persistenceService.loadHistory()
        settings = persistenceService.loadSettings()

        // Load default token from keychain if exists
        if let token = KeychainService.getToken() {
            settings.defaultTunnelToken = token
        }
    }

    private func startAutoStartPresets() async {
        for preset in presets where preset.autoStartOnLaunch {
            await startTunnelFromPreset(preset)
        }
    }

    // MARK: - Tunnel Management

    func startTunnel(config: TunnelConfiguration) async {
        var tunnel = Tunnel(
            id: UUID(),
            name: config.name,
            type: config.tunnelType,
            localPort: config.localPort,
            localHost: config.localHost,
            tunnelProtocol: config.tunnelProtocol,
            status: .starting,
            startedAt: Date(),
            tunnelToken: config.tunnelToken,
            tunnelName: config.tunnelName,
            namedTunnelMode: config.namedTunnelMode,
            ingressRules: config.ingressRules
        )

        tunnels.append(tunnel)

        do {
            if config.tunnelType == .quickTunnel {
                try await cloudflaredService.startQuickTunnel(
                    id: tunnel.id,
                    localURL: config.localURL,
                    cloudflaredPath: settings.cloudflaredPath,
                    onOutput: { [weak self] output in
                        Task { @MainActor in
                            self?.handleTunnelOutput(id: tunnel.id, output: output)
                        }
                    },
                    onStatusChange: { [weak self] status, url in
                        Task { @MainActor in
                            self?.handleStatusChange(id: tunnel.id, status: status, publicURL: url)
                        }
                    }
                )
            } else if config.usesLocalIngress {
                // Config-based named tunnel with local ingress rules
                guard let tunnelUUID = config.tunnelUUID,
                      let credentialsPath = config.credentialsFilePath else {
                    throw CloudflaredError.tunnelFailed("Missing tunnel UUID or credentials path")
                }

                // Generate config file
                let configPath = try await configFileService.generateConfigFile(
                    tunnelId: tunnel.id,
                    tunnelUUID: tunnelUUID,
                    credentialsPath: credentialsPath,
                    ingressRules: config.ingressRules,
                    defaultService: config.localURL
                )

                // Update tunnel with config path
                if let index = tunnels.firstIndex(where: { $0.id == tunnel.id }) {
                    tunnels[index].configFilePath = configPath.path
                }

                try await cloudflaredService.startConfigBasedTunnel(
                    id: tunnel.id,
                    configFilePath: configPath.path,
                    tunnelName: tunnelUUID,
                    cloudflaredPath: settings.cloudflaredPath,
                    onOutput: { [weak self] output in
                        Task { @MainActor in
                            self?.handleTunnelOutput(id: tunnel.id, output: output)
                        }
                    },
                    onStatusChange: { [weak self] status, url in
                        Task { @MainActor in
                            self?.handleStatusChange(id: tunnel.id, status: status, publicURL: url)
                        }
                    }
                )
            } else {
                // Token-based named tunnel
                guard let token = config.tunnelToken ?? settings.defaultTunnelToken else {
                    throw CloudflaredError.tunnelFailed("No tunnel token provided")
                }

                try await cloudflaredService.startNamedTunnel(
                    id: tunnel.id,
                    token: token,
                    localURL: config.localURL,
                    cloudflaredPath: settings.cloudflaredPath,
                    onOutput: { [weak self] output in
                        Task { @MainActor in
                            self?.handleTunnelOutput(id: tunnel.id, output: output)
                        }
                    },
                    onStatusChange: { [weak self] status, url in
                        Task { @MainActor in
                            self?.handleStatusChange(id: tunnel.id, status: status, publicURL: url)
                        }
                    }
                )
            }
        } catch {
            // Clean up config file if it was generated
            await configFileService.deleteConfigFile(tunnelId: tunnel.id)
            // Remove the failed tunnel from the list
            tunnels.removeAll { $0.id == tunnel.id }
            showError(error.localizedDescription)
        }
    }

    func startTunnelFromPreset(_ preset: Preset) async {
        // Update preset usage
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index].lastUsedAt = Date()
            presets[index].usageCount += 1
            try? persistenceService.savePresets(presets)
        }

        await startTunnel(config: preset.configuration)
    }

    func stopTunnel(id: UUID) async {
        guard let tunnel = tunnels.first(where: { $0.id == id }) else { return }

        // Update status to stopping
        updateTunnelStatus(id: id, status: .stopping)

        await cloudflaredService.stopTunnel(id: id)

        // Clean up config file if it was generated
        if tunnel.configFilePath != nil {
            await configFileService.deleteConfigFile(tunnelId: id)
        }

        // Add to history
        let entry = HistoryEntry(
            tunnelName: tunnel.name,
            localURL: tunnel.localURL,
            publicURL: tunnel.publicURL,
            tunnelType: tunnel.type,
            startedAt: tunnel.startedAt ?? Date(),
            endedAt: Date(),
            duration: tunnel.startedAt.map { Date().timeIntervalSince($0) },
            status: .stopped
        )

        history.insert(entry, at: 0)
        if history.count > settings.maxHistoryEntries {
            history = Array(history.prefix(settings.maxHistoryEntries))
        }
        try? persistenceService.saveHistory(history)

        tunnels.removeAll { $0.id == id }

        if settings.showNotifications {
            notificationService.sendTunnelDisconnected(name: tunnel.name)
        }
    }

    func stopAllTunnels() async {
        let tunnelIds = tunnels.map { $0.id }
        for id in tunnelIds {
            await stopTunnel(id: id)
        }
    }

    // MARK: - Status Handling

    private func handleStatusChange(id: UUID, status: TunnelStatus, publicURL: String?) {
        guard let index = tunnels.firstIndex(where: { $0.id == id }) else { return }

        tunnels[index].status = status

        if let url = publicURL {
            tunnels[index].publicURL = url

            if settings.copyURLOnConnect {
                copyToClipboard(url)
            }

            if settings.showNotifications {
                notificationService.sendTunnelConnected(name: tunnels[index].name, url: url)
            }
        } else if status == .connected && settings.showNotifications {
            notificationService.sendTunnelConnected(name: tunnels[index].name, url: nil)
        }
    }

    private func handleTunnelOutput(id: UUID, output: String) {
        guard let index = tunnels.firstIndex(where: { $0.id == id }) else { return }

        // Split output into lines and append
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        tunnels[index].logs.append(contentsOf: lines)

        // Trim logs if exceeding max limit
        if tunnels[index].logs.count > Tunnel.maxLogLines {
            tunnels[index].logs = Array(tunnels[index].logs.suffix(Tunnel.maxLogLines))
        }

        #if DEBUG
        print("[Tunnel \(id.uuidString.prefix(8))] \(output)")
        #endif
    }

    private func updateTunnelStatus(id: UUID, status: TunnelStatus, error: String? = nil) {
        guard let index = tunnels.firstIndex(where: { $0.id == id }) else { return }
        tunnels[index].status = status
        tunnels[index].errorMessage = error

        if status == .error, settings.showNotifications, let error = error {
            notificationService.sendTunnelError(name: tunnels[index].name, error: error)
        }
    }

    // MARK: - Preset Management

    func addPreset(_ preset: Preset) {
        presets.append(preset)
        try? persistenceService.savePresets(presets)
    }

    func updatePreset(_ preset: Preset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
            try? persistenceService.savePresets(presets)
        }
    }

    func deletePreset(_ preset: Preset) {
        presets.removeAll { $0.id == preset.id }
        try? persistenceService.savePresets(presets)
    }

    // MARK: - History Management

    func clearHistory() {
        history.removeAll()
        persistenceService.clearHistory()
    }

    func recreateTunnelFromHistory(_ entry: HistoryEntry) async {
        let config = TunnelConfiguration(
            name: entry.tunnelName,
            localHost: "localhost",
            localPort: extractPort(from: entry.localURL) ?? 8080,
            tunnelProtocol: extractProtocol(from: entry.localURL),
            tunnelType: entry.tunnelType
        )

        await startTunnel(config: config)
    }

    private func extractPort(from url: String) -> Int? {
        let components = url.components(separatedBy: ":")
        guard components.count >= 3, let port = Int(components.last ?? "") else {
            return nil
        }
        return port
    }

    private func extractProtocol(from url: String) -> TunnelProtocol {
        if url.hasPrefix("https") { return .https }
        if url.hasPrefix("tcp") { return .tcp }
        if url.hasPrefix("ssh") { return .ssh }
        return .http
    }

    // MARK: - Settings Management

    func saveSettings() {
        persistenceService.saveSettings(settings)
    }

    func saveDefaultToken(_ token: String) {
        do {
            try KeychainService.saveToken(token)
            settings.defaultTunnelToken = token
        } catch {
            showError("Failed to save token: \(error.localizedDescription)")
        }
    }

    // MARK: - Utilities

    func copyToClipboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }

    func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}
