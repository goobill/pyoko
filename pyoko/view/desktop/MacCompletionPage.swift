import SwiftUI

#if os(macOS)
/// Shared completion presentation; callers retain their existing session actions.
struct MacCompletionPage<Summary: View, Actions: View>: View {
    let title: String
    let message: String
    let icon: String
    let summary: Summary
    let actions: Actions

    init(title: String, message: String, icon: String,
         @ViewBuilder summary: () -> Summary, @ViewBuilder actions: () -> Actions) {
        self.title = title; self.message = message; self.icon = icon
        self.summary = summary(); self.actions = actions()
    }

    var body: some View {
        MacPanelPage {
            VStack(spacing: 28) {
                Image(systemName: icon).font(.system(size: 56)).foregroundStyle(.tint)
                Text(title).font(.system(size: 32, weight: .semibold))
                Text(message).font(.title3).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                GroupBox("Session summary") {
                    VStack(spacing: 24) {
                        summary.frame(maxWidth: .infinity)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                            actions
                        }
                    }
                }
            }
            .frame(maxWidth: 850)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
        .accessibilityIdentifier("completion.desktop")
    }
}

struct MacCompletionButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.headline).multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.accentColor)
        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
    }
}
#endif
