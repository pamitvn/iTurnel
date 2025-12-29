//
//  LaunchAgentService.swift
//  iturnel
//

import Foundation
import ServiceManagement

@MainActor
class LaunchAgentService {
    static let shared = LaunchAgentService()

    private init() {}

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .enabled:
            return "Enabled"
        case .notRegistered:
            return "Not Registered"
        case .notFound:
            return "Not Found"
        case .requiresApproval:
            return "Requires Approval"
        @unknown default:
            return "Unknown"
        }
    }

    func enable() throws {
        try SMAppService.mainApp.register()
    }

    func disable() throws {
        try SMAppService.mainApp.unregister()
    }

    func toggle() throws {
        if isEnabled {
            try disable()
        } else {
            try enable()
        }
    }
}
