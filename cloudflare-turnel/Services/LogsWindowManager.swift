//
//  LogsWindowManager.swift
//  iturnel
//

import SwiftUI
import AppKit

@MainActor
class LogsWindowManager {
    static let shared = LogsWindowManager()

    private var windows: [UUID: NSWindow] = [:]

    private init() {}

    func showLogs(for tunnel: Tunnel, appState: AppState) {
        // If window already exists for this tunnel, bring it to front
        if let existingWindow = windows[tunnel.id] {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create new window
        let contentView = TunnelLogsWindowView(tunnelId: tunnel.id)
            .environment(appState)

        let hostingView = NSHostingView(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 450),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.title = "\(tunnel.name) - Logs"
        window.center()
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 400, height: 300)

        // Store reference and set delegate to clean up when closed
        windows[tunnel.id] = window

        let delegate = WindowDelegate { [weak self] in
            self?.windows.removeValue(forKey: tunnel.id)
        }
        window.delegate = delegate
        // Keep delegate alive
        objc_setAssociatedObject(window, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeWindow(for tunnelId: UUID) {
        windows[tunnelId]?.close()
        windows.removeValue(forKey: tunnelId)
    }
}

private class WindowDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

struct TunnelLogsWindowView: View {
    let tunnelId: UUID
    @Environment(AppState.self) private var appState

    private var tunnel: Tunnel? {
        appState.tunnels.first { $0.id == tunnelId }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let tunnel = tunnel {
                // Toolbar
                HStack {
                    Text("\(tunnel.logs.count) lines")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button {
                        copyLogs()
                    } label: {
                        Label("Copy All", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        clearLogs()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(8)

                Divider()

                // Logs content
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 1) {
                            if tunnel.logs.isEmpty {
                                Text("No logs yet...")
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 50)
                            } else {
                                ForEach(Array(tunnel.logs.enumerated()), id: \.offset) { index, line in
                                    Text(line)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.primary)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .id(index)
                                }
                            }
                        }
                        .padding(8)
                    }
                    .background(Color(nsColor: .textBackgroundColor))
                    .onChange(of: tunnel.logs.count) { _, newCount in
                        // Auto-scroll to bottom
                        if newCount > 0 {
                            withAnimation(.easeOut(duration: 0.1)) {
                                proxy.scrollTo(newCount - 1, anchor: .bottom)
                            }
                        }
                    }
                }
            } else {
                VStack {
                    Text("Tunnel no longer active")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func copyLogs() {
        guard let tunnel = tunnel else { return }
        let logsText = tunnel.logs.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(logsText, forType: .string)
    }

    private func clearLogs() {
        guard let index = appState.tunnels.firstIndex(where: { $0.id == tunnelId }) else { return }
        appState.tunnels[index].logs.removeAll()
    }
}
