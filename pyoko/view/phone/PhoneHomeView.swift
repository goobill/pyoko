import SwiftUI

#if os(iOS)
struct PhoneHomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Review") {
                    NavigationLink { ReviewView() } label: {
                        HomeMenuRow(title: "Review", subtitle: "Continue your scheduled vocabulary practice.", icon: "rectangle.stack")
                    }.accessibilityIdentifier("home.review")
                    NavigationLink { ConfigView() } label: {
                        Label("Config", systemImage: "slider.horizontal.3")
                    }.accessibilityIdentifier("home.config")
                }
                Section("Quick Review") {
                    NavigationLink { QuickConfigView() } label: {
                        HomeMenuRow(title: "Quick Review", subtitle: "Practise without changing your review schedule.", icon: "bolt")
                    }.accessibilityIdentifier("home.quick")
                }
                Section("Widget") {
                    NavigationLink { WidgetConfigView() } label: {
                        Label("Config", systemImage: "square.grid.2x2")
                    }.accessibilityIdentifier("home.widget")
                }
                Section("Manage") {
                    NavigationLink { DecksView() } label: {
                        HomeMenuRow(title: "Decks", subtitle: "Install, import, enable and manage decks.", icon: "rectangle.stack.badge.plus")
                    }.accessibilityIdentifier("home.decks")
                }
            }
            .pyokoSurface()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    Text("Pyoko")
                        .accessibilityIdentifier("home.title")
                        .font(.largeTitle.bold())
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    NavigationLink { SettingsView() } label: {
                        Image(systemName: "gearshape").font(.title2)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.settings")
                    .accessibilityLabel("Settings")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .pyokoSurface()
            }
        }
    }
}

private struct HomeMenuRow: View {
    let title: String
    let subtitle: String
    let icon: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title2).foregroundStyle(.tint).frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).fontWeight(.medium)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

#endif
