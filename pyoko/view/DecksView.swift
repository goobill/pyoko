import SwiftUI
import SwiftData

struct DecksView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query(
        sort: \PyokoDeck.importedAt,
        order: .reverse
    )
    private var decks:
        [PyokoDeck]

    @Query
    private var configs:
        [PyokoConfig]

    @State
    private var downloadingDeckKeys:
        Set<String> = []

    @State
    private var deckPendingDeletion:
        PyokoDeck?

    @State
    private var showingDeleteConfirmation =
        false

    @State
    private var showingError =
        false

    @State
    private var errorMessage =
        ""

    var body: some View {

        List {

            importedDecksSection

            builtInDecksSection
        }
        .navigationTitle(
            "Decks"
        )
        .toolbar {

            ToolbarItem(
                placement:
                    .primaryAction
            ) {

                NavigationLink {

                    DataLoaderView()

                } label: {

                    Label(
                        "Import Deck",
                        systemImage:
                            "plus"
                    )
                }
            }
        }
        .onAppear {

            ensureConfigExists()
        }
        .alert(
            "Delete Deck?",
            isPresented:
                $showingDeleteConfirmation
        ) {

            Button(
                "Cancel",
                role:
                    .cancel
            ) {

                deckPendingDeletion =
                    nil
            }

            Button(
                "Delete",
                role:
                    .destructive
            ) {

                deletePendingDeck()
            }

        } message: {

            if let deck =
                deckPendingDeletion {

                Text(
                    "\"\(deck.name)\" and all of its cards will be deleted."
                )
            }
        }
        .alert(
            "Deck Error",
            isPresented:
                $showingError
        ) {

            Button(
                "OK"
            ) {}

        } message: {

            Text(
                errorMessage
            )
        }
    }

    // MARK: - Manager

    private var deckManager:
        DeckManager {

        DeckManager(
            modelContext:
                modelContext
        )
    }

    // MARK: - Config

    private var config:
        PyokoConfig? {

        configs.first
    }

    private func ensureConfigExists() {

        do {

            _ =
                try deckManager
                    .ensureReviewConfigExists()

        } catch {

            showError(
                error
            )
        }
    }

    // MARK: - Imported Decks Section

    private var importedDecksSection:
        some View {

        Section {

            if importedDecks.isEmpty {

                ContentUnavailableView {

                    Label(
                        "No Imported Decks",
                        systemImage:
                            "rectangle.stack"
                    )

                } description: {

                    Text(
                        "Import a CSV, URL, or Google Sheet using the + button above."
                    )
                }

            } else {

                ForEach(
                    importedDecks
                ) { deck in

                    installedDeckRow(
                        deck
                    )
                }
            }

        } header: {

            Text(
                "Imported Decks"
            )

        } footer: {

            Text(
                "Selected decks are included when future review sessions are created."
            )
        }
    }

    // MARK: - Built-in Decks Section

    private var builtInDecksSection:
        some View {

        Section {

            ForEach(
                DefaultDecks.all
            ) { defaultDeck in

                builtInDeckRow(
                    defaultDeck
                )
            }

        } header: {

            Text(
                "Built-in Decks"
            )

        } footer: {

            Text(
                "Deselect a deck to exclude it from future reviews without deleting its cards or progress."
            )
        }
    }

    // MARK: - Imported Deck Row

    private func installedDeckRow(
        _ deck: PyokoDeck
    ) -> some View {

        HStack(
            alignment:
                .center,
            spacing:
                14
        ) {

            VStack(
                alignment:
                    .leading,
                spacing:
                    5
            ) {

                Text(
                    deck.name
                )
                .fontWeight(
                    .medium
                )

                Text(
                    "\(deck.vocabularyCount.formatted()) vocabulary"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )

                DeckOriginView(
                    deck:
                        deck
                )
            }

            Spacer(
                minLength:
                    12
            )

            deckEnabledButton(
                deck
            )

            deleteButton(
                deck
            )
        }
        .padding(
            .vertical,
            4
        )
    }

    // MARK: - Built-in Deck Row

    @ViewBuilder
    private func builtInDeckRow(
        _ defaultDeck:
            DefaultDeck
    ) -> some View {

        if let installedDeck =
            installedBuiltInDeck(
                key:
                    defaultDeck.key
            ) {

            installedBuiltInDeckRow(
                defaultDeck:
                    defaultDeck,
                installedDeck:
                    installedDeck
            )

        } else {

            uninstalledBuiltInDeckRow(
                defaultDeck
            )
        }
    }

    // MARK: - Installed Built-in Deck

    private func installedBuiltInDeckRow(
        defaultDeck:
            DefaultDeck,
        installedDeck:
            PyokoDeck
    ) -> some View {

        HStack(
            alignment:
                .center,
            spacing:
                14
        ) {

            VStack(
                alignment:
                    .leading,
                spacing:
                    5
            ) {

                Text(
                    defaultDeck.name
                )
                .fontWeight(
                    .medium
                )

                Text(
                    defaultDeck.description
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )

                HStack(
                    spacing:
                        5
                ) {

                    Image(
                        systemName:
                            "checkmark.circle"
                    )

                    Text(
                        "Installed"
                    )

                    Text(
                        "•"
                    )

                    Text(
                        "\(installedDeck.vocabularyCount.formatted()) vocabulary"
                    )
                }
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }

            Spacer(
                minLength:
                    12
            )

            deckEnabledButton(
                installedDeck
            )

            deleteButton(
                installedDeck
            )
        }
        .padding(
            .vertical,
            4
        )
    }

    // MARK: - Uninstalled Built-in Deck

    private func uninstalledBuiltInDeckRow(
        _ defaultDeck:
            DefaultDeck
    ) -> some View {

        let downloading =
            downloadingDeckKeys
                .contains(
                    defaultDeck.key
                )

        return HStack(
            alignment:
                .center,
            spacing:
                14
        ) {

            VStack(
                alignment:
                    .leading,
                spacing:
                    5
            ) {

                Text(
                    defaultDeck.name
                )
                .fontWeight(
                    .medium
                )

                Text(
                    defaultDeck.description
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }

            Spacer(
                minLength:
                    12
            )

            if downloading {

                ProgressView()
                    .controlSize(
                        .small
                    )

            } else {

                Button {

                    download(
                        defaultDeck
                    )

                } label: {

                    Label(
                        "Download",
                        systemImage:
                            "arrow.down.circle"
                    )
                }
                .buttonStyle(
                    .bordered
                )
            }
        }
        .padding(
            .vertical,
            4
        )
    }

    // MARK: - Enabled Button

    private func deckEnabledButton(
        _ deck: PyokoDeck
    ) -> some View {

        let enabled =
            isDeckEnabled(
                deck
            )

        return Button {

            setDeckEnabled(
                deck,
                enabled:
                    !enabled
            )

        } label: {

            Image(
                systemName:
                    enabled
                    ? "checkmark.circle.fill"
                    : "circle"
            )
            .font(
                .system(
                    size:
                        24,
                    weight:
                        .regular
                )
            )
            .foregroundStyle(
                enabled
                ? Color.accentColor
                : Color.secondary
            )
            .frame(
                width:
                    36,
                height:
                    36
            )
            .contentShape(
                Circle()
            )
        }
        .buttonStyle(
            .plain
        )
        .accessibilityLabel(
            enabled
            ? "Disable \(deck.name) for review"
            : "Enable \(deck.name) for review"
        )
        .accessibilityValue(
            enabled
            ? "Selected"
            : "Not selected"
        )
        .help(
            enabled
            ? "Disable for Review"
            : "Enable for Review"
        )
    }

    // MARK: - Delete Button

    private func deleteButton(
        _ deck: PyokoDeck
    ) -> some View {

        Button(
            role:
                .destructive
        ) {

            requestDelete(
                deck
            )

        } label: {

            Image(
                systemName:
                    "trash"
            )
            .frame(
                width:
                    36,
                height:
                    36
            )
        }
        .buttonStyle(
            .plain
        )
        .foregroundStyle(
            .red
        )
        .accessibilityLabel(
            "Delete \(deck.name)"
        )
        .help(
            "Delete Deck"
        )
    }

    // MARK: - Enabled State

    private func isDeckEnabled(
        _ deck: PyokoDeck
    ) -> Bool {

        deckManager
            .isEnabledForReview(
                deck,
                config:
                    config
            )
    }

    private func setDeckEnabled(
        _ deck: PyokoDeck,
        enabled: Bool
    ) {

        do {

            try deckManager
                .setEnabledForReview(
                    deck,
                    enabled:
                        enabled,
                    config:
                        config
                )

        } catch {

            showError(
                error
            )
        }
    }

    // MARK: - Deck Lists

    private var importedDecks:
        [PyokoDeck] {

        decks.filter {

            $0.origin !=
                DeckOrigin.builtIn
        }
    }

    private func installedBuiltInDeck(
        key: String
    ) -> PyokoDeck? {

        decks.first {

            $0.catalogKey ==
                key
        }
    }

    // MARK: - Download

    private func download(
        _ defaultDeck:
            DefaultDeck
    ) {

        guard
            !downloadingDeckKeys
                .contains(
                    defaultDeck.key
                )
        else {
            return
        }

        downloadingDeckKeys.insert(
            defaultDeck.key
        )

        Task {

            defer {

                downloadingDeckKeys
                    .remove(
                        defaultDeck.key
                    )
            }

            do {

                try await deckManager
                    .install(
                        defaultDeck
                    )

            } catch {

                showError(
                    error
                )
            }
        }
    }

    // MARK: - Delete

    private func requestDelete(
        _ deck: PyokoDeck
    ) {

        deckPendingDeletion =
            deck

        showingDeleteConfirmation =
            true
    }

    private func deletePendingDeck() {

        guard
            let deck =
                deckPendingDeletion
        else {
            return
        }

        do {

            try deckManager
                .delete(
                    deck
                )

            deckPendingDeletion =
                nil

        } catch {

            deckPendingDeletion =
                nil

            showError(
                error
            )
        }
    }

    // MARK: - Error

    private func showError(
        _ error: Error
    ) {

        errorMessage =
            error.localizedDescription

        showingError =
            true
    }
}
