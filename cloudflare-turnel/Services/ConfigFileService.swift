//
//  ConfigFileService.swift
//  iturnel
//

import Foundation

actor ConfigFileService {
    private let fileManager = FileManager.default

    private var configsDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("iTurnel")
            .appendingPathComponent("configs")
    }

    init() {
        try? fileManager.createDirectory(at: configsDirectory, withIntermediateDirectories: true)
    }

    func generateConfigFile(
        tunnelId: UUID,
        tunnelUUID: String,
        credentialsPath: String,
        ingressRules: [IngressRule],
        defaultService: String
    ) throws -> URL {
        var yaml = """
        tunnel: \(tunnelUUID)
        credentials-file: \(credentialsPath)

        ingress:
        """

        for rule in ingressRules where !rule.hostname.isEmpty {
            yaml += "\n  - hostname: \(rule.hostname)"
            if let path = rule.path, !path.isEmpty {
                yaml += "\n    path: \(path)"
            }
            yaml += "\n    service: \(rule.service)"

            var hasOriginRequest = false
            var originRequestContent = ""

            if rule.noTLSVerify {
                originRequestContent += "\n      noTLSVerify: true"
                hasOriginRequest = true
            }
            if let header = rule.httpHostHeader, !header.isEmpty {
                originRequestContent += "\n      httpHostHeader: \(header)"
                hasOriginRequest = true
            }
            if let sni = rule.originServerName, !sni.isEmpty {
                originRequestContent += "\n      originServerName: \(sni)"
                hasOriginRequest = true
            }

            if hasOriginRequest {
                yaml += "\n    originRequest:" + originRequestContent
            }
        }

        // Always add catch-all rule (required by cloudflared)
        yaml += "\n  - service: \(defaultService.isEmpty ? "http_status:404" : defaultService)"

        let configURL = configsDirectory.appendingPathComponent("\(tunnelId.uuidString).yml")
        try yaml.write(to: configURL, atomically: true, encoding: .utf8)

        return configURL
    }

    func deleteConfigFile(tunnelId: UUID) {
        let configURL = configsDirectory.appendingPathComponent("\(tunnelId.uuidString).yml")
        try? fileManager.removeItem(at: configURL)
    }

    func configFilePath(tunnelId: UUID) -> URL {
        configsDirectory.appendingPathComponent("\(tunnelId.uuidString).yml")
    }

    func cleanupOrphanedConfigs(activeTunnelIds: Set<UUID>) {
        guard let contents = try? fileManager.contentsOfDirectory(at: configsDirectory, includingPropertiesForKeys: nil) else {
            return
        }

        for fileURL in contents where fileURL.pathExtension == "yml" {
            let filename = fileURL.deletingPathExtension().lastPathComponent
            if let uuid = UUID(uuidString: filename), !activeTunnelIds.contains(uuid) {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
}
