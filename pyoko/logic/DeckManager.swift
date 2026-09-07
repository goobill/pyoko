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
         the review configuration before
         deleting it.

         SwiftData should nullify the
         relationship anyway, but doing
         this explicitly also lets us
         clean up unavailable tag filters.
         */

        if let configuration =
            try fetchReviewConfiguration() {

            configuration.selectedDecks =
                (
                    configuration
                        .selectedDecks ??
                    []
                )
                .filter {
                    $0.id != deck.id
                }

            removeUnavailableSelectedTags(
                from:
                    configuration
            )
        }

        modelContext.delete(
            deck
        )

        try modelContext.save()
    }

    // MARK: - Review Configuration

    @discardableResult
    func ensureReviewConfigurationExists()
        throws -> PyokoConfiguration {

        if let configuration =
            try fetchReviewConfiguration() {

            return configuration
        }

        let deckDescriptor =
            FetchDescriptor<PyokoDeck>()

        let installedDecks =
            try modelContext.fetch(
                deckDescriptor
            )

        let configuration =
            PyokoConfiguration()

        /*
         First-time behaviour:
         all currently installed decks
         start enabled.
         */

        configuration.selectedDecks =
            installedDecks

        configuration.selectedTags =
            []

        modelContext.insert(
            configuration
        )

        try modelContext.save()

        return configuration
    }

    // MARK: - Enabled State

    func isEnabledForReview(
        _ deck: PyokoDeck,
        configuration:
            PyokoConfiguration?
    ) -> Bool {

        /*
         Before the first configuration
         has been created, the default
         behaviour is that installed decks
         are enabled.

         ensureReviewConfigurationExists()
         will persist that state.
         */

        guard
            let configuration
        else {
            return true
        }

        return (
            configuration
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
        configuration:
            PyokoConfiguration? = nil
    ) throws {

        let configuration =
            try configuration ??
            ensureReviewConfigurationExists()

        var selectedDecks =
            configuration
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

        configuration.selectedDecks =
            selectedDecks

        /*
         If disabling this deck makes
         previously selected tag filters
         impossible, remove those filters.
         */

        removeUnavailableSelectedTags(
            from:
                configuration
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
         configuration, the newly imported
         deck becomes enabled.

         If no configuration exists yet,
         do nothing. When the first
         configuration is later created,
         all installed decks are selected.
         */

        guard
            let configuration =
                try fetchReviewConfiguration()
        else {
            return
        }

        var selectedDecks =
            configuration
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

        configuration.selectedDecks =
            selectedDecks
    }

    // MARK: - Configuration Fetch

    private func fetchReviewConfiguration()
        throws -> PyokoConfiguration? {

        let descriptor =
            FetchDescriptor<
                PyokoConfiguration
            >()

        return try modelContext
            .fetch(
                descriptor
            )
            .first
    }

    // MARK: - Tag Cleanup

    private func removeUnavailableSelectedTags(
        from configuration:
            PyokoConfiguration
    ) {

        let selectedDecks =
            configuration
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

        configuration.selectedTags =
            (
                configuration
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
