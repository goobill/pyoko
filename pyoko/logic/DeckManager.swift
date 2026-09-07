import Foundation
import SwiftData

@MainActor
final class DeckManager {

    private let modelContext:
        ModelContext

    init(
        modelContext: ModelContext
    ) {

        self.modelContext =
            modelContext
    }

    // MARK: - Install

    func install(
        _ deck: DefaultDeck
    ) async throws {

        let loader =
            DataLoader(
                modelContext:
                    modelContext
            )

        try await loader.loadFromURL(
            deckName:
                deck.name,
            urlString:
                deck.urlString,
            createRecognition:
                true,
            createRecall:
                true,
            catalogKey:
                deck.key,
            origin:
                DeckOrigin.builtIn,
            originName:
                deck.name,
            originIdentifier:
                deck.key
        )

        /*
         DataLoader calls
         enableNewlyImportedDeck(_:)
         after creating the deck.

         Therefore built-in and manually
         imported decks follow exactly
         the same enablement behaviour.
         */
    }

    // MARK: - Delete

    func delete(
        _ deck: PyokoDeck
    ) throws {

        /*
         Remove the deck explicitly from
         the review config before
         deleting it.

         SwiftData should nullify the
         relationship anyway, but doing
         this explicitly also lets us
         clean up unavailable tag filters.
         */

        if let config =
            try fetchReviewConfig() {

            config.selectedDecks =
                (
                    config
                        .selectedDecks ??
                    []
                )
                .filter {
                    $0.id != deck.id
                }

            removeUnavailableSelectedTags(
                from:
                    config
            )
        }

        modelContext.delete(
            deck
        )

        try modelContext.save()
    }

    // MARK: - Review Config

    @discardableResult
    func ensureReviewConfigExists()
        throws -> PyokoConfig {

        if let config =
            try fetchReviewConfig() {

            return config
        }

        let deckDescriptor =
            FetchDescriptor<PyokoDeck>()

        let installedDecks =
            try modelContext.fetch(
                deckDescriptor
            )

        let config =
            PyokoConfig()

        /*
         First-time behaviour:
         all currently installed decks
         start enabled.
         */

        config.selectedDecks =
            installedDecks

        config.selectedTags =
            []

        modelContext.insert(
            config
        )

        try modelContext.save()

        return config
    }

    // MARK: - Enabled State

    func isEnabledForReview(
        _ deck: PyokoDeck,
        config:
            PyokoConfig?
    ) -> Bool {

        /*
         Before the first config
         has been created, the default
         behaviour is that installed decks
         are enabled.

         ensureReviewConfigExists()
         will persist that state.
         */

        guard
            let config
        else {
            return true
        }

        return (
            config
                .selectedDecks ??
            []
        )
        .contains {
            $0.id == deck.id
        }
    }

    func setEnabledForReview(
        _ deck: PyokoDeck,
        enabled: Bool,
        config:
            PyokoConfig? = nil
    ) throws {

        let config =
            try config ??
            ensureReviewConfigExists()

        var selectedDecks =
            config
                .selectedDecks ??
            []

        if enabled {

            let alreadyEnabled =
                selectedDecks.contains {
                    $0.id == deck.id
                }

            if !alreadyEnabled {

                selectedDecks.append(
                    deck
                )
            }

        } else {

            selectedDecks.removeAll {
                $0.id == deck.id
            }
        }

        config.selectedDecks =
            selectedDecks

        /*
         If disabling this deck makes
         previously selected tag filters
         impossible, remove those filters.
         */

        removeUnavailableSelectedTags(
            from:
                config
        )

        try modelContext.save()
    }

    // MARK: - Newly Imported Deck

    func enableNewlyImportedDeck(
        _ deck: PyokoDeck
    ) throws {

        /*
         Preserve the behaviour we already
         established:

         If the user already has a review
         config, the newly imported
         deck becomes enabled.

         If no config exists yet,
         do nothing. When the first
         config is later created,
         all installed decks are selected.
         */

        guard
            let config =
                try fetchReviewConfig()
        else {
            return
        }

        var selectedDecks =
            config
                .selectedDecks ??
            []

        guard
            !selectedDecks.contains(
                where: {
                    $0.id == deck.id
                }
            )
        else {
            return
        }

        selectedDecks.append(
            deck
        )

        config.selectedDecks =
            selectedDecks
    }

    // MARK: - Config Fetch

    private func fetchReviewConfig()
        throws -> PyokoConfig? {

        let descriptor =
            FetchDescriptor<
                PyokoConfig
            >()

        return try modelContext
            .fetch(
                descriptor
            )
            .first
    }

    // MARK: - Tag Cleanup

    private func removeUnavailableSelectedTags(
        from config:
            PyokoConfig
    ) {

        let selectedDecks =
            config
                .selectedDecks ??
            []

        let availableTagIDs =
            Set(
                selectedDecks
                    .flatMap {
                        $0.cards ?? []
                    }
                    .flatMap {
                        $0.tags ?? []
                    }
                    .map(
                        \.id
                    )
            )

        config.selectedTags =
            (
                config
                    .selectedTags ??
                []
            )
            .filter {

                availableTagIDs
                    .contains(
                        $0.id
                    )
            }
    }
}
