//
//  IngressRuleRowView.swift
//  iturnel
//

import SwiftUI

struct IngressRuleRowView: View {
    @Binding var rule: IngressRule
    let onDelete: () -> Void
    @State private var showAdvanced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hostname")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("api.example.com", text: $rule.hostname)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 120)
                }

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                    .font(.caption)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Service")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("http://localhost:3000", text: $rule.service)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 140)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAdvanced.toggle()
                    }
                } label: {
                    Image(systemName: showAdvanced ? "gear.circle.fill" : "gear")
                        .foregroundColor(showAdvanced ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .help("Advanced Options")

                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Remove Rule")
            }

            if showAdvanced {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Path:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        TextField("/api/*", text: Binding(
                            get: { rule.path ?? "" },
                            set: { rule.path = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 150)
                    }

                    Toggle("Skip TLS Verification", isOn: $rule.noTLSVerify)
                        .font(.caption)

                    HStack {
                        Text("Host Header:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        TextField("custom-host.example.com", text: Binding(
                            get: { rule.httpHostHeader ?? "" },
                            set: { rule.httpHostHeader = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("Origin SNI:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        TextField("origin.example.com", text: Binding(
                            get: { rule.originServerName ?? "" },
                            set: { rule.originServerName = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.leading, 8)
                .padding(.top, 4)
            }
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

#Preview {
    IngressRuleRowView(
        rule: .constant(IngressRule(hostname: "api.example.com", service: "http://localhost:3000")),
        onDelete: {}
    )
    .padding()
    .frame(width: 400)
}
