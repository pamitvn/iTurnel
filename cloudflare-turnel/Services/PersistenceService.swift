//
//  PersistenceService.swift
//  cloudflare-turnel
//

import Foundation

class PersistenceService {
    static let shared = PersistenceService()

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var appSupportURL: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CloudflareTunnel")
    }

    private init() {
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        // Create app support directory if needed
        try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
    }

    // MARK: - Presets

    func savePresets(_ presets: [Preset]) throws {
        let url = appSupportURL.appendingPathComponent(Constants.presetsFileName)
        let data = try encoder.encode(presets)
        try data.write(to: url)
    }

    func loadPresets() -> [Preset] {
        let url = appSupportURL.appendingPathComponent(Constants.presetsFileName)
        guard fileManager.fileExists(atPath: url.path) else { return [] }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([Preset].self, from: data)
        } catch {
            print("Failed to load presets: \(error)")
            return []
        }
    }

    // MARK: - History

    func saveHistory(_ entries: [HistoryEntry]) throws {
        let url = appSupportURL.appendingPathComponent(Constants.historyFileName)
        let data = try encoder.encode(entries)
        try data.write(to: url)
    }

    func loadHistory() -> [HistoryEntry] {
        let url = appSupportURL.appendingPathComponent(Constants.historyFileName)
        guard fileManager.fileExists(atPath: url.path) else { return [] }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([HistoryEntry].self, from: data)
        } catch {
            print("Failed to load history: \(error)")
            return []
        }
    }

    func addHistoryEntry(_ entry: HistoryEntry, maxEntries: Int) {
        var history = loadHistory()
        history.insert(entry, at: 0)

        if history.count > maxEntries {
            history = Array(history.prefix(maxEntries))
        }

        try? saveHistory(history)
    }

    func clearHistory() {
        let url = appSupportURL.appendingPathComponent(Constants.historyFileName)
        try? fileManager.removeItem(at: url)
    }

    // MARK: - Settings (UserDefaults)

    func saveSettings(_ settings: AppSettings) {
        if let data = try? encoder.encode(settings) {
            UserDefaults.standard.set(data, forKey: "appSettings")
        }
    }

    func loadSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: "appSettings"),
              let settings = try? decoder.decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }
}
