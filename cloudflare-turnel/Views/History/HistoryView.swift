//
//  HistoryView.swift
//  iturnel
//

import SwiftUI

struct HistoryView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            if !appState.history.isEmpty {
                HStack {
                    Text("\(appState.history.count) entries")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Clear All") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appState.showingClearHistoryConfirmation = true
                        }
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    if appState.history.isEmpty {
                        EmptyStateView(
                            icon: "clock",
                            title: "No History",
                            message: "Your tunnel history will appear here"
                        )
                        .frame(maxWidth: .infinity, minHeight: 150)
                    } else {
                        ForEach(appState.history) { entry in
                            HistoryRowView(entry: entry)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct HistoryRowView: View {
    @Environment(AppState.self) private var appState
    let entry: HistoryEntry

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: statusIcon)
                    .font(.system(size: 14))
                    .foregroundColor(statusColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.tunnelName)
                    .font(.system(.body, weight: .medium))

                HStack(spacing: 8) {
                    Text(entry.localURL)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let url = entry.publicURL {
                        Text("->")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(url.replacingOccurrences(of: "https://", with: ""))
                            .font(.caption)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                HStack(spacing: 8) {
                    Text(formatDate(entry.startedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if entry.duration != nil {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(entry.formattedDuration)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Recreate button
            if isHovered {
                Button {
                    Task {
                        await appState.recreateTunnelFromHistory(entry)
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Recreate Tunnel")
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var statusColor: Color {
        switch entry.status {
        case .stopped: return .gray
        case .error: return .red
        default: return .green
        }
    }

    private var statusIcon: String {
        switch entry.status {
        case .stopped: return "stop.fill"
        case .error: return "exclamationmark.triangle.fill"
        default: return "checkmark"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    HistoryView()
        .environment(AppState())
        .frame(width: 360)
}
