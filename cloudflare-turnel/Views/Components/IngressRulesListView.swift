//
//  IngressRulesListView.swift
//  iturnel
//

import SwiftUI

struct IngressRulesListView: View {
    @Binding var rules: [IngressRule]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ingress Rules")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        rules.append(IngressRule())
                    }
                } label: {
                    Label("Add Route", systemImage: "plus.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
            }

            if rules.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No routes configured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Add at least one route to map hostnames to local services")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
            } else {
                ForEach(Array(rules.enumerated()), id: \.element.id) { index, rule in
                    IngressRuleRowView(
                        rule: Binding(
                            get: { rules.indices.contains(index) ? rules[index] : rule },
                            set: { if rules.indices.contains(index) { rules[index] = $0 } }
                        ),
                        onDelete: {
                            let idToRemove = rule.id
                            withAnimation(.easeInOut(duration: 0.2)) {
                                rules.removeAll { $0.id == idToRemove }
                            }
                        }
                    )
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Examples:")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Group {
                    Text("api.example.com -> http://localhost:3000")
                    Text("app.example.com -> http://localhost:8080")
                    Text("*.dev.example.com -> http://localhost:4000")
                }
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(.top, 4)
        }
    }
}

#Preview {
    IngressRulesListView(rules: .constant([
        IngressRule(hostname: "api.example.com", service: "http://localhost:3000"),
        IngressRule(hostname: "*.dev.example.com", service: "http://localhost:8080")
    ]))
    .padding()
    .frame(width: 400)
}
