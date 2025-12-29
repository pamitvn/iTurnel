//
//  CloudflaredService.swift
//  iturnel
//

import Foundation

actor CloudflaredService {
    private var runningProcesses: [UUID: Process] = [:]
    private var outputPipes: [UUID: Pipe] = [:]

    func startQuickTunnel(
        id: UUID,
        localURL: String,
        cloudflaredPath: String,
        onOutput: @escaping @Sendable (String) -> Void,
        onStatusChange: @escaping @Sendable (TunnelStatus, String?) -> Void
    ) async throws {
        guard FileManager.default.fileExists(atPath: cloudflaredPath) else {
            throw CloudflaredError.binaryNotFound(cloudflaredPath)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: cloudflaredPath)
        process.arguments = ["tunnel", "--url", localURL]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        // Track state for Quick Tunnel - need BOTH URL and connection registered
        var pendingURL: String?
        var connectionRegistered = false

        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else { return }

            onOutput(output)

            // Track URL when found (but don't mark connected yet)
            if let url = Self.parsePublicURL(from: output) {
                pendingURL = url
            }

            // Track when connection is registered
            if Self.isConnectionRegistered(output) {
                connectionRegistered = true
            }

            // Only mark as connected when BOTH URL found AND connection registered
            if let url = pendingURL, connectionRegistered {
                onStatusChange(.connected, url)
                pendingURL = nil  // Clear to avoid duplicate callbacks
            }

            // Check for errors
            if output.lowercased().contains("error") || output.lowercased().contains("failed") {
                if !output.contains("retrying") {
                    onStatusChange(.error, output)
                }
            }
        }

        process.terminationHandler = { _ in
            onStatusChange(.stopped, nil)
        }

        do {
            try process.run()
            runningProcesses[id] = process
            outputPipes[id] = outputPipe
            onStatusChange(.starting, nil)
        } catch {
            throw CloudflaredError.processStartFailed(error.localizedDescription)
        }
    }

    func startNamedTunnel(
        id: UUID,
        token: String,
        localURL: String?,
        cloudflaredPath: String,
        onOutput: @escaping @Sendable (String) -> Void,
        onStatusChange: @escaping @Sendable (TunnelStatus, String?) -> Void
    ) async throws {
        guard FileManager.default.fileExists(atPath: cloudflaredPath) else {
            throw CloudflaredError.binaryNotFound(cloudflaredPath)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: cloudflaredPath)

        var arguments = ["tunnel", "run", "--token", token]
        if let localURL = localURL {
            arguments += ["--url", localURL]
        }

        process.arguments = arguments

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else { return }

            onOutput(output)

            // Check for connection registered
            if Self.isConnectionRegistered(output) {
                // For named tunnels, extract the hostname from output if available
                let url = Self.parsePublicURL(from: output)
                onStatusChange(.connected, url)
            }

            // Check for errors
            if output.lowercased().contains("error") || output.lowercased().contains("failed") {
                if !output.contains("retrying") {
                    onStatusChange(.error, output)
                }
            }
        }

        process.terminationHandler = { _ in
            onStatusChange(.stopped, nil)
        }

        do {
            try process.run()
            runningProcesses[id] = process
            outputPipes[id] = outputPipe
            onStatusChange(.starting, nil)
        } catch {
            throw CloudflaredError.processStartFailed(error.localizedDescription)
        }
    }

    func startConfigBasedTunnel(
        id: UUID,
        configFilePath: String,
        tunnelName: String,
        cloudflaredPath: String,
        onOutput: @escaping @Sendable (String) -> Void,
        onStatusChange: @escaping @Sendable (TunnelStatus, String?) -> Void
    ) async throws {
        guard FileManager.default.fileExists(atPath: cloudflaredPath) else {
            throw CloudflaredError.binaryNotFound(cloudflaredPath)
        }

        guard FileManager.default.fileExists(atPath: configFilePath) else {
            throw CloudflaredError.configFileNotFound(configFilePath)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: cloudflaredPath)
        process.arguments = ["tunnel", "--config", configFilePath, "run", tunnelName]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else { return }

            onOutput(output)

            // Check for connection registered
            if Self.isConnectionRegistered(output) {
                let url = Self.parsePublicURL(from: output)
                onStatusChange(.connected, url)
            }

            // Check for errors
            if output.lowercased().contains("error") || output.lowercased().contains("failed") {
                if !output.contains("retrying") {
                    onStatusChange(.error, output)
                }
            }
        }

        process.terminationHandler = { _ in
            onStatusChange(.stopped, nil)
        }

        do {
            try process.run()
            runningProcesses[id] = process
            outputPipes[id] = outputPipe
            onStatusChange(.starting, nil)
        } catch {
            throw CloudflaredError.processStartFailed(error.localizedDescription)
        }
    }

    func stopTunnel(id: UUID) async {
        guard let process = runningProcesses[id] else { return }

        // Remove readability handler before terminating
        if let pipe = outputPipes[id] {
            pipe.fileHandleForReading.readabilityHandler = nil
        }

        process.terminate()
        runningProcesses.removeValue(forKey: id)
        outputPipes.removeValue(forKey: id)
    }

    func stopAllTunnels() async {
        for id in runningProcesses.keys {
            await stopTunnel(id: id)
        }
    }

    func isRunning(id: UUID) -> Bool {
        guard let process = runningProcesses[id] else { return false }
        return process.isRunning
    }

    // MARK: - Output Parsing

    private static func parsePublicURL(from output: String) -> String? {
        // Try trycloudflare.com URL first
        if let range = output.range(of: Constants.Regex.trycloudflareURL, options: .regularExpression) {
            return String(output[range])
        }

        // Try custom domain URL
        if let range = output.range(of: Constants.Regex.customDomainURL, options: .regularExpression) {
            return String(output[range])
        }

        return nil
    }

    private static func isConnectionRegistered(_ output: String) -> Bool {
        output.range(of: Constants.Regex.connectionRegistered, options: .regularExpression) != nil
    }
}

// MARK: - Errors

enum CloudflaredError: LocalizedError {
    case binaryNotFound(String)
    case processStartFailed(String)
    case tunnelFailed(String)
    case configFileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .binaryNotFound(let path):
            return "cloudflared not found at \(path). Please install it via Homebrew: brew install cloudflared"
        case .processStartFailed(let reason):
            return "Failed to start tunnel process: \(reason)"
        case .tunnelFailed(let reason):
            return "Tunnel failed: \(reason)"
        case .configFileNotFound(let path):
            return "Config file not found at \(path)"
        }
    }
}
