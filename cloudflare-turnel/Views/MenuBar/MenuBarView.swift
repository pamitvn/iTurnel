//
//  MenuBarView.swift
//  cloudflare-turnel
//

import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.showingError {
                // Show error view inline
                ErrorView()
                    .environment(appState)
            } else if appState.showingClearHistoryConfirmation {
                // Show clear history confirmation inline
                ClearHistoryConfirmationView()
                    .environment(appState)
            } else if appState.showingNewTunnel {
                // Show New Tunnel form inline
                NewTunnelView()
                    .environment(appState)
            } else if appState.editingPreset != nil {
                // Show Edit Preset form inline
                PresetFormView(preset: appState.editingPreset, isEditing: true)
                    .environment(appState)
            } else {
                // Show main content
                mainContent
            }
        }
        .frame(width: 380)
        .task {
            await appState.initialize()
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Tab selector
            tabSelector

            // Content
            contentView

            Divider()

            // Footer
            footerView
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Cloudflare Tunnel")
                    .font(.headline)
                Text(appState.statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.showingNewTunnel = true
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .help("Create new tunnel")
        }
        .padding()
    }

    private var tabSelector: some View {
        Picker("", selection: Binding(
            get: { appState.selectedTab },
            set: { appState.selectedTab = $0 }
        )) {
            ForEach(AppState.Tab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var contentView: some View {
        Group {
            switch appState.selectedTab {
            case .tunnels:
                TunnelListView()
            case .presets:
                PresetListView()
            case .history:
                HistoryView()
            }
        }
        .frame(minHeight: 200, maxHeight: 350)
    }

    private var footerView: some View {
        HStack {
            SettingsLink {
                Text("Settings...")
            }
            .buttonStyle(.link)

            Spacer()

            if appState.hasActiveTunnels {
                Button("Stop All") {
                    Task {
                        await appState.stopAllTunnels()
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }

            Button("Quit") {
                // Stop all tunnels before quitting
                Task {
                    await appState.stopAllTunnels()
                    NSApplication.shared.terminate(nil)
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

#Preview {
    MenuBarView()
        .environment(AppState())
}
