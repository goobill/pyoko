import SwiftUI
import SwiftData

struct HomeView: View {

    @Environment(\.modelContext)
    private var modelContext

    @State
    private var reviewRemaining = 0

    @State
    private var reviewTotal = 0

    var body: some View {

        NavigationStack {

            List {

                studySection

                manageSection
            }
            .navigationTitle("Pyoko")
            .onAppear {

                refreshReviewProgress()
            }
        }
    }

    // MARK: - Study

    private var studySection: some View {

        Section("Study") {

            NavigationLink {

                ReviewView()

            } label: {

                menuRow(
                    title: "Review",
                    subtitle: reviewSubtitle,
                    systemImage: "rectangle.stack"
                )
            }

            NavigationLink {

                SentenceConfigView()

            } label: {

                menuRow(
                    title: "Practice Sentences",
                    subtitle: "Practise your vocabulary in generated sentences.",
                    systemImage: "text.bubble"
                )
            }
        }
    }

    // MARK: - Manage

    private var manageSection: some View {

        Section("Manage") {

            NavigationLink {

                DecksView()

            } label: {

                menuRow(
                    title: "Decks",
                    subtitle: "Import, install, enable and manage decks.",
                    systemImage: "rectangle.stack.badge.plus"
                )
            }

            NavigationLink {

                ConfigurationView()

            } label: {

                menuRow(
                    title: "Configuration",
                    subtitle: "Change your review and display settings.",
                    systemImage: "gearshape"
                )
            }
        }
    }

    // MARK: - Menu Row

    private func menuRow(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {

        HStack(
            spacing: 14
        ) {

            Image(
                systemName: systemImage
            )
            .font(
                .title2
            )
            .foregroundStyle(
                .tint
            )
            .frame(
                width: 32
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    title
                )
                .fontWeight(
                    .medium
                )

                Text(
                    subtitle
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .padding(
            .vertical,
            5
        )
    }

    // MARK: - Review Progress

    private var reviewSubtitle: String {

        if reviewTotal == 0 {

            return "No cards to review."
        }

        if reviewRemaining == 0 {

            return "Today's review is complete."
        }

        return "\(reviewRemaining) of \(reviewTotal) cards remaining."
    }

    private func refreshReviewProgress() {

        let manager =
            CardManager(
                modelContext: modelContext
            )

        manager.startReviewIfNeeded()

        let progress =
            manager.getProgress()

        reviewRemaining =
            progress.remaining

        reviewTotal =
            progress.total
    }
}
