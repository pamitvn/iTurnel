//
//  Tunnel.swift
//  cloudflare-turnel
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

    // For named tunnels
    var tunnelToken: String?
    var tunnelName: String?

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
        tunnelToken: String? = nil,
        tunnelName: String? = nil
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
        self.tunnelToken = tunnelToken
        self.tunnelName = tunnelName
    }
}

struct TunnelConfiguration: Codable, Equatable {
    var name: String
    var localHost: String
    var localPort: Int
    var tunnelProtocol: TunnelProtocol
    var tunnelType: TunnelType

    // For named tunnels
    var tunnelToken: String?
    var tunnelName: String?

    // Advanced options
    var noTLSVerify: Bool
    var httpHostHeader: String?
    var originServerName: String?

    var localURL: String {
        "\(tunnelProtocol.rawValue)://\(localHost):\(localPort)"
    }

    init(
        name: String,
        localHost: String = "localhost",
        localPort: Int = 8080,
        tunnelProtocol: TunnelProtocol = .http,
        tunnelType: TunnelType = .namedTunnel,
        tunnelToken: String? = nil,
        tunnelName: String? = nil,
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
        self.noTLSVerify = noTLSVerify
        self.httpHostHeader = httpHostHeader
        self.originServerName = originServerName
    }
}
