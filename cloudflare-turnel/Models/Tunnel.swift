//
//  Tunnel.swift
//  iturnel
//

import Foundation

enum TunnelStatus: String, Codable {
    case stopped
    case starting
    case connected
    case error
    case stopping
}

enum TunnelType: String, Codable, CaseIterable {
    case quickTunnel = "Quick Tunnel"
    case namedTunnel = "Named Tunnel"
}

enum TunnelProtocol: String, Codable, CaseIterable {
    case http
    case https
    case tcp
    case ssh
}

enum NamedTunnelMode: String, Codable, CaseIterable {
    case token = "Token"
    case configFile = "Config File"
}

struct Tunnel: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var type: TunnelType
    var localPort: Int
    var localHost: String
    var tunnelProtocol: TunnelProtocol
    var publicURL: String?
    var status: TunnelStatus
    var processId: Int32?
    var startedAt: Date?
    var errorMessage: String?
    var logs: [String] = []

    // For named tunnels
    var tunnelToken: String?
    var tunnelName: String?

    // For config-based named tunnels
    var namedTunnelMode: NamedTunnelMode?
    var ingressRules: [IngressRule]
    var configFilePath: String?

    // Max log lines to prevent memory issues
    static let maxLogLines = 1000

    var localURL: String {
        "\(tunnelProtocol.rawValue)://\(localHost):\(localPort)"
    }

    init(
        id: UUID = UUID(),
        name: String,
        type: TunnelType = .namedTunnel,
        localPort: Int,
        localHost: String = "localhost",
        tunnelProtocol: TunnelProtocol = .http,
        publicURL: String? = nil,
        status: TunnelStatus = .stopped,
        processId: Int32? = nil,
        startedAt: Date? = nil,
        errorMessage: String? = nil,
        logs: [String] = [],
        tunnelToken: String? = nil,
        tunnelName: String? = nil,
        namedTunnelMode: NamedTunnelMode? = nil,
        ingressRules: [IngressRule] = [],
        configFilePath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.localPort = localPort
        self.localHost = localHost
        self.tunnelProtocol = tunnelProtocol
        self.publicURL = publicURL
        self.status = status
        self.processId = processId
        self.startedAt = startedAt
        self.errorMessage = errorMessage
        self.logs = logs
        self.tunnelToken = tunnelToken
        self.tunnelName = tunnelName
        self.namedTunnelMode = namedTunnelMode
        self.ingressRules = ingressRules
        self.configFilePath = configFilePath
    }
}

struct TunnelConfiguration: Codable, Equatable {
    var name: String
    var localHost: String
    var localPort: Int
    var tunnelProtocol: TunnelProtocol
    var tunnelType: TunnelType

    // For named tunnels - Token mode
    var tunnelToken: String?
    var tunnelName: String?

    // For named tunnels - Config mode
    var namedTunnelMode: NamedTunnelMode
    var tunnelUUID: String?
    var credentialsFilePath: String?
    var ingressRules: [IngressRule]

    // Advanced options
    var noTLSVerify: Bool
    var httpHostHeader: String?
    var originServerName: String?

    var localURL: String {
        "\(tunnelProtocol.rawValue)://\(localHost):\(localPort)"
    }

    var usesLocalIngress: Bool {
        tunnelType == .namedTunnel &&
        namedTunnelMode == .configFile &&
        !ingressRules.isEmpty
    }

    init(
        name: String,
        localHost: String = "localhost",
        localPort: Int = 8080,
        tunnelProtocol: TunnelProtocol = .http,
        tunnelType: TunnelType = .namedTunnel,
        tunnelToken: String? = nil,
        tunnelName: String? = nil,
        namedTunnelMode: NamedTunnelMode = .token,
        tunnelUUID: String? = nil,
        credentialsFilePath: String? = nil,
        ingressRules: [IngressRule] = [],
        noTLSVerify: Bool = false,
        httpHostHeader: String? = nil,
        originServerName: String? = nil
    ) {
        self.name = name
        self.localHost = localHost
        self.localPort = localPort
        self.tunnelProtocol = tunnelProtocol
        self.tunnelType = tunnelType
        self.tunnelToken = tunnelToken
        self.tunnelName = tunnelName
        self.namedTunnelMode = namedTunnelMode
        self.tunnelUUID = tunnelUUID
        self.credentialsFilePath = credentialsFilePath
        self.ingressRules = ingressRules
        self.noTLSVerify = noTLSVerify
        self.httpHostHeader = httpHostHeader
        self.originServerName = originServerName
    }

    // Custom decoder for backwards compatibility with existing presets
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        localHost = try container.decode(String.self, forKey: .localHost)
        localPort = try container.decode(Int.self, forKey: .localPort)
        tunnelProtocol = try container.decode(TunnelProtocol.self, forKey: .tunnelProtocol)
        tunnelType = try container.decode(TunnelType.self, forKey: .tunnelType)
        tunnelToken = try container.decodeIfPresent(String.self, forKey: .tunnelToken)
        tunnelName = try container.decodeIfPresent(String.self, forKey: .tunnelName)

        // New fields with defaults for backwards compatibility
        namedTunnelMode = try container.decodeIfPresent(NamedTunnelMode.self, forKey: .namedTunnelMode) ?? .token
        tunnelUUID = try container.decodeIfPresent(String.self, forKey: .tunnelUUID)
        credentialsFilePath = try container.decodeIfPresent(String.self, forKey: .credentialsFilePath)
        ingressRules = try container.decodeIfPresent([IngressRule].self, forKey: .ingressRules) ?? []

        noTLSVerify = try container.decodeIfPresent(Bool.self, forKey: .noTLSVerify) ?? false
        httpHostHeader = try container.decodeIfPresent(String.self, forKey: .httpHostHeader)
        originServerName = try container.decodeIfPresent(String.self, forKey: .originServerName)
    }

    private enum CodingKeys: String, CodingKey {
        case name, localHost, localPort, tunnelProtocol, tunnelType
        case tunnelToken, tunnelName
        case namedTunnelMode, tunnelUUID, credentialsFilePath, ingressRules
        case noTLSVerify, httpHostHeader, originServerName
    }
}
