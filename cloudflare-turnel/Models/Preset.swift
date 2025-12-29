//
//  Preset.swift
//  iturnel
//

import Foundation

struct Preset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var configuration: TunnelConfiguration
    var createdAt: Date
    var lastUsedAt: Date?
    var usageCount: Int
    var autoStartOnLaunch: Bool

    init(
        id: UUID = UUID(),
        name: String,
        configuration: TunnelConfiguration,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        usageCount: Int = 0,
        autoStartOnLaunch: Bool = false
    ) {
        self.id = id
        self.name = name
        self.configuration = configuration
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.usageCount = usageCount
        self.autoStartOnLaunch = autoStartOnLaunch
    }
}
