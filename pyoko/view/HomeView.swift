import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var selection: HomeDestination? = .review

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List(selection: $selection) {
                Section("Review") {
                    Label("Review", systemImage: "rectangle.stack").tag(HomeDestination.review).accessibilityIdentifier("home.review")
                    Label("Config", systemImage: "slider.horizontal.3").tag(HomeDestination.config).accessibilityIdentifier("home.config")
                }
                Section("Quick Review") {
                    Label("Quick Review", systemImage: "bolt").tag(HomeDestination.quick).accessibilityIdentifier("home.quick")
                }
                Section("Widget") {
                    Label("Config", systemImage: "square.grid.2x2").tag(HomeDestination.widget).accessibilityIdentifier("home.widget")
                }
                Section("Manage") {
                    Label("Decks", systemImage: "rectangle.stack.badge.plus").tag(HomeDestination.decks).accessibilityIdentifier("home.decks")
                }
            }
            .pyokoSurface()
            .navigationSplitViewColumnWidth(min: 200, ideal: 230)
            .safeAreaInset(edge: .top) {
                HStack {
                    Text("Pyoko").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("home.title")
                    Spacer()
                    SettingsLink { Image(systemName: "gearshape").font(.title3) }
                        .buttonStyle(.plain)
                        .frame(width: 44, height: 44)
                        .accessibilityIdentifier("home.settings")
                        .accessibilityLabel("Settings")
                        .help("Settings")
                }
                .padding(.horizontal, 16)
                .pyokoSurface()
            }
        } detail: {
            NavigationStack {
                switch selection ?? .review {
                case .review: ReviewStartView()
                case .config: ConfigView()
                case .quick: QuickConfigView()
                case .decks: DecksView()
                case .widget: WidgetConfigView()
                }
            }
            // Clear any pushed session when switching sidebar destinations.
            .id(selection)
        }
        .frame(minWidth: 760, minHeight: 620)
        #else
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
        #endif
    }
}

private enum HomeDestination: Hashable {
    case review, config, quick, decks, widget
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

/// A landing page keeps the session in a pushed destination, so Exit also works on Mac.
private struct ReviewStartView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack").font(.system(size: 44)).foregroundStyle(.tint)
            Text("Review").font(.largeTitle.bold())
            Text("Study the vocabulary due in your review schedule.")
                .foregroundStyle(.secondary)
            NavigationLink("Start Review") { ReviewView() }
                .accessibilityIdentifier("review.start")
                .buttonStyle(.borderedProminent)
            NavigationLink("Config") { ConfigView() }
                .buttonStyle(.bordered)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pyokoSurface()
        .navigationTitle("Review")
    }
}

extension View {
    @ViewBuilder
    func pyokoHideBackButton() -> some View {
        #if os(iOS)
        navigationBarBackButtonHidden(true)
        #else
        self
        #endif
    }
}
