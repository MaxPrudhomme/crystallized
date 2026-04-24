//
//  ContentView.swift
//  crystallized
//
//  Created by Max PRUDHOMME on 23/04/2026.
//

import AppKit
import Combine
import SwiftUI

private enum MenuLayout {
    static let contentWidth: CGFloat = 292
    static let outerPadding: CGFloat = 6
}

struct ContentView: View {
    @AppStorage("thoughtWebhookURL") private var webhookURL = ""
    @AppStorage("thoughtWebhookSecretKey") private var webhookSecretKey = ""
    @ObservedObject private var thoughtGenerator: ThoughtGenerator
    @ObservedObject private var webhookSender: WebhookSender
    @State private var isSettingsExpanded = false
    @State private var lastSeenAt = Date()
    @State private var now = Date()

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    init(thoughtGenerator: ThoughtGenerator, webhookSender: WebhookSender) {
        self.thoughtGenerator = thoughtGenerator
        self.webhookSender = webhookSender
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Header(relativeLastSeen: relativeLastSeen)

            Divider()

            ThoughtText(thought: thoughtGenerator.thought)

            Divider()

            MenuRowButton(
                "Settings",
                trailingSystemImage: isSettingsExpanded ? "chevron.down" : "chevron.right",
                action: toggleSettings
            )

            if isSettingsExpanded {
                WebhookSettings(
                    webhookURL: $webhookURL,
                    webhookSecretKey: $webhookSecretKey
                )
            }

            Divider()

            MenuRowButton("Quit Crystallized") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(MenuLayout.outerPadding)
        .frame(width: MenuLayout.contentWidth + (MenuLayout.outerPadding * 2), alignment: .leading)
        .onReceive(timer) { date in
            now = date
        }
        .onChange(of: thoughtGenerator.thought) {
            lastSeenAt = Date()
            now = lastSeenAt
        }
    }

    private var relativeLastSeen: String {
        let elapsed = max(0, Int(now.timeIntervalSince(lastSeenAt)))

        if elapsed < 60 {
            return "\(elapsed)s ago"
        }

        let minutes = elapsed / 60
        if minutes < 60 {
            return "\(minutes)m ago"
        }

        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)h ago"
        }

        let days = hours / 24
        return "\(days)d ago"
    }

    private func toggleSettings() {
        withAnimation(.snappy(duration: 0.16)) {
            isSettingsExpanded.toggle()
        }
    }
}

private struct Header: View {
    let relativeLastSeen: String

    var body: some View {
        HStack(spacing: 10) {
            Text("Crystallized")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            Text("Last seen \(relativeLastSeen)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .frame(height: 20)
                .background(.quaternary, in: Capsule(style: .continuous))
        }
        .padding(.horizontal, 6)
        .frame(height: 30)
        .frame(width: MenuLayout.contentWidth)
    }
}

private struct ThoughtText: View {
    let thought: String

    var body: some View {
        Text(thought.isEmpty ? "No thought yet." : thought)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(thought.isEmpty ? .secondary : .primary)
            .lineLimit(6)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .frame(width: MenuLayout.contentWidth, alignment: .leading)
    }
}

private struct WebhookSettings: View {
    @Binding var webhookURL: String
    @Binding var webhookSecretKey: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            TextField("Webhook URL", text: $webhookURL)
                .textFieldStyle(.roundedBorder)

            SecureField("Secret key (optional)", text: $webhookSecretKey)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal, 6)
        .padding(.top, 2)
        .frame(width: MenuLayout.contentWidth, alignment: .leading)
    }
}

private struct SecondaryText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct MenuRowButton: View {
    let title: String
    let trailingSystemImage: String?
    let action: () -> Void

    @State private var isHovering = false

    init(_ title: String, trailingSystemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.trailingSystemImage = trailingSystemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                if let trailingSystemImage {
                    Image(systemName: trailingSystemImage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 7)
            .frame(height: 22)
            .background {
                if isHovering {
                    Capsule(style: .continuous)
                        .fill(.quaternary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            thoughtGenerator: ThoughtGenerator(
                thought: "A clear thought is often just the next small action made visible. Let the rest wait its turn."
            ),
            webhookSender: WebhookSender()
        )
        .padding()
    }
}
