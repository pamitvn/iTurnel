//
//  ErrorView.swift
//  cloudflare-turnel
//

import SwiftUI

struct ErrorView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Text("Error")
                    .font(.headline)
                Spacer()
            }
            .padding()

            Divider()

            // Error content
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)

                Text("Something went wrong")
                    .font(.headline)

                Text(appState.errorMessage ?? "Unknown error")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Check if it's a cloudflared not found error
                if appState.errorMessage?.contains("cloudflared not found") == true {
                    VStack(spacing: 8) {
                        Text("Install cloudflared via Homebrew:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Text("brew install cloudflared")
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(4)

                            Button {
                                appState.copyToClipboard("brew install cloudflared")
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.plain)
                            .help("Copy command")
                        }

                        Button("Open Settings to configure path") {
                            appState.showingError = false
                            // Open settings window
                            if let url = URL(string: "x-apple.systempreferences:") {
                                NSWorkspace.shared.open(url)
                            }
                            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        }
                        .buttonStyle(.link)
                        .padding(.top, 8)
                    }
                }

                Spacer()
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Dismiss button
            HStack {
                Spacer()

                Button("OK") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.showingError = false
                        appState.errorMessage = nil
                    }
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ErrorView()
        .environment({
            let state = AppState()
            state.errorMessage = "cloudflared not found at /opt/homebrew/bin/cloudflared. Please install it via Homebrew: brew install cloudflared"
            state.showingError = true
            return state
        }())
        .frame(width: 380, height: 400)
}
