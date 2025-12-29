//
//  EmptyStateView.swift
//  iturnel
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))

            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    EmptyStateView(
        icon: "network",
        title: "No Active Tunnels",
        message: "Click + to create a new tunnel"
    )
}
