//
//  IngressRule.swift
//  iturnel
//

import Foundation

struct IngressRule: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var hostname: String
    var service: String
    var path: String?
    var noTLSVerify: Bool
    var httpHostHeader: String?
    var originServerName: String?

    init(
        id: UUID = UUID(),
        hostname: String = "",
        service: String = "http://localhost:8080",
        path: String? = nil,
        noTLSVerify: Bool = false,
        httpHostHeader: String? = nil,
        originServerName: String? = nil
    ) {
        self.id = id
        self.hostname = hostname
        self.service = service
        self.path = path
        self.noTLSVerify = noTLSVerify
        self.httpHostHeader = httpHostHeader
        self.originServerName = originServerName
    }

    var isWildcard: Bool {
        hostname.hasPrefix("*.")
    }

    var isCatchAll: Bool {
        hostname.isEmpty
    }
}
