//
//  HistoryEntry.swift
//  iturnel
//

import Foundation

struct HistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let tunnelName: String
    let localURL: String
    let publicURL: String?
    let tunnelType: TunnelType
    let startedAt: Date
    let endedAt: Date?
    let duration: TimeInterval?
    let status: TunnelStatus

    init(
        id: UUID = UUID(),
        tunnelName: String,
        localURL: String,
        publicURL: String? = nil,
        tunnelType: TunnelType,
        startedAt: Date,
        endedAt: Date? = nil,
        duration: TimeInterval? = nil,
        status: TunnelStatus = .stopped
    ) {
        self.id = id
        self.tunnelName = tunnelName
        self.localURL = localURL
        self.publicURL = publicURL
        self.tunnelType = tunnelType
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = duration
        self.status = status
    }

    var formattedDuration: String {
        guard let duration = duration else { return "N/A" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}
