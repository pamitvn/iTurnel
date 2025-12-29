//
//  TunnelListView.swift
//  iturnel
//

import SwiftUI

struct TunnelListView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if appState.tunnels.isEmpty {
                    EmptyStateView(
                        icon: "network",
                        title: "No Active Tunnels",
                        message: "Click + to create a new tunnel"
                    )
                    .frame(maxWidth: .infinity, minHeight: 150)
                } else {
                    ForEach(appState.tunnels) { tunnel in
                        TunnelRowView(tunnel: tunnel)
                    }
                }
            }
            .padding()
        }
    }
}

struct TunnelRowView: View {
    @Environment(AppState.self) private var appState
    let tunnel: Tunnel

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            statusIndicator

            // Tunnel info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tunnel.name)
                        .font(.system(.body, weight: .medium))

                    if tunnel.type == .namedTunnel {
                        Image(systemName: "key.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .help("Named Tunnel")
                    }
                }

                Text(tunnel.publicURL ?? tunnel.localURL)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let error = tunnel.errorMessage, tunnel.status == .error {
                    Text(error.prefix(50))
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Actions
            if isHovered || tunnel.status == .connected {
                actionButtons
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.2))
                .frame(width: 24, height: 24)

            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            if tunnel.status == .starting || tunnel.status == .stopping {
                Circle()
                    .stroke(statusColor, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(isHovered ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isHovered)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button {
                LogsWindowManager.shared.showLogs(for: tunnel, appState: appState)
            } label: {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("View Logs")

            if let url = tunnel.publicURL {
                Button {
                    appState.copyToClipboard(url)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Copy URL")

                Button {
                    if let url = URL(string: url) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Open in Browser")
            }

            if tunnel.status != .stopping {
                Button {
                    Task {
                        await appState.stopTunnel(id: tunnel.id)
                    }
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Stop Tunnel")
            }
        }
    }

    private var statusColor: Color {
        switch tunnel.status {
        case .connected: return .green
        case .starting: return .yellow
        case .stopping: return .orange
        case .error: return .red
        case .stopped: return .gray
        }
    }

    private var borderColor: Color {
        switch tunnel.status {
        case .connected: return .green.opacity(0.3)
        case .error: return .red.opacity(0.3)
        default: return .clear
        }
    }
}

#Preview {
    TunnelListView()
        .environment(AppState())
        .frame(width: 360)
}
