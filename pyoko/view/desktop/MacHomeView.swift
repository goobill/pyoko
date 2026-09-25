import SwiftUI
import SwiftData

#if os(macOS)
private enum HomeDestination: Hashable { case review, config, quick, decks, widget }

struct MacHomeView: View {
    @State private var selection: HomeDestination? = .review
    var body: some View {
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
            .font(.system(size: 15))
            .environment(\.defaultMinListRowHeight, 42)
            .pyokoSurface()
            .navigationSplitViewColumnWidth(min: 220, ideal: 250)
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
        .controlSize(.large)
        .frame(minWidth: 760, minHeight: 620)
    }
}

/// A landing page keeps the session in a pushed destination, so Exit also works on Mac.
private struct ReviewStartView: View {
    @Query private var reviews: [PyokoReviewCard]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            let summary = ReviewSessionSummary(reviews: reviews, now: timeline.date)
            MacPanelPage {
                VStack(alignment: .leading, spacing: 24) {
                    Label("Review", systemImage: "rectangle.stack")
                        .font(.system(size: 34, weight: .bold))
                    Text("Your scheduled Japanese practice")
                        .font(.title2).foregroundStyle(.secondary)
                    GroupBox("Today's session") {
                        VStack(alignment: .leading, spacing: 18) {
                            if summary.total > 0 {
                                HStack(spacing: 40) {
                                    metric("Completed", summary.completed)
                                    metric("Remaining", summary.remaining)
                                }
                                ProgressView(value: Double(summary.completed), total: Double(summary.total))
                                Text(summary.remaining > 0
                                     ? "Your progress is saved. Resume with the next unanswered card."
                                     : "This batch is complete. Open Review to check for another available batch.")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("No saved session for today. Start Review to create a batch using your review config.")
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 16) {
                                NavigationLink { ReviewView() } label: {
                                    Text(summary.actionTitle).font(.headline)
                                        .frame(minWidth: 150, minHeight: 40)
                                }
                                .accessibilityIdentifier("review.start")
                                .buttonStyle(.borderedProminent)
                                NavigationLink { ConfigView() } label: {
                                    Label("Review Config", systemImage: "slider.horizontal.3")
                                        .font(.headline).frame(minHeight: 40)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .accessibilityIdentifier("review.summary")
                }
                .frame(maxWidth: 850, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .pyokoSurface()
        .navigationTitle("Review")
    }

    private func metric(_ title: String, _ count: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(count)").font(.system(size: 32, weight: .semibold)).monospacedDigit()
            Text(title).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("review.summary.\(title.lowercased())")
        .accessibilityValue("\(count)")
    }
}
#endif
