//
//  ClearHistoryConfirmationView.swift
//  iturnel
//

import SwiftUI

struct ClearHistoryConfirmationView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    closeView()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Clear History")
                    .font(.headline)

                Spacer()

                // Invisible spacer for centering
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .opacity(0)
            }
            .padding()

            Divider()

            // Content
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "trash.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)

                Text("Clear All History?")
                    .font(.headline)

                Text("This will permanently delete all \(appState.history.count) tunnel history entries. This action cannot be undone.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Actions
            HStack(spacing: 16) {
                Button("Cancel") {
                    closeView()
                }
                .buttonStyle(.bordered)

                Button("Clear All") {
                    appState.clearHistory()
                    closeView()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
        }
    }

    private func closeView() {
        withAnimation(.easeInOut(duration: 0.2)) {
            appState.showingClearHistoryConfirmation = false
        }
    }
}

#Preview {
    ClearHistoryConfirmationView()
        .environment(AppState())
        .frame(width: 380, height: 350)
}
