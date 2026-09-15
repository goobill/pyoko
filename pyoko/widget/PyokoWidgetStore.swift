import Foundation

/// Stores widget state in an injected preferences suite. App and tests use identical logic.
struct WidgetStore {
    private let defaults: UserDefaults?

    init(defaults: UserDefaults?) {
        self.defaults = defaults
    }

    // MARK: - Snapshot

    func loadSnapshot()
        -> PyokoWidgetSnapshot {

        guard
            let data =
                defaults?
                    .data(
                        forKey:
                            PyokoWidgetConstants
                                .snapshotKey
                    ),
            let snapshot =
                try? JSONDecoder()
                    .decode(
                        PyokoWidgetSnapshot.self,
                        from:
                            data
                    )
        else {

            return .empty
        }

        return snapshot
    }

    @discardableResult
    func saveSnapshot(
        _ snapshot:
            PyokoWidgetSnapshot
    ) -> Bool {

        guard
            let defaults,
            let encoded =
                try? JSONEncoder()
                    .encode(
                        snapshot
                    )
        else {

            return false
        }

        let previousSnapshot =
            loadSnapshot()

        let previousWordID =
            currentWord(
                snapshot:
                    previousSnapshot
            )?
            .id

        let previousDirection =
            currentDirection(
                snapshot:
                    previousSnapshot
            )

        let wasRevealed =
            isWordRevealed

        defaults.set(
            encoded,
            forKey:
                PyokoWidgetConstants
                    .snapshotKey
        )

        let newIndex:
            Int

        if let previousWordID,
           let matchingIndex =
            snapshot.words
                .firstIndex(
                    where: {
                        $0.id ==
                            previousWordID
                    }
                ) {

            newIndex =
                matchingIndex

        } else if snapshot.words.isEmpty {

            newIndex =
                0

        } else {

            newIndex =
                Int.random(
                    in:
                        0..<snapshot
                            .words
                            .count
                )
        }

        defaults.set(
            newIndex,
            forKey:
                PyokoWidgetConstants
                    .wordIndexKey
        )

        let newWordID:
            String?

        if snapshot.words
            .indices
            .contains(
                newIndex
            ) {

            newWordID =
                snapshot.words[
                    newIndex
                ].id

        } else {

            newWordID =
                nil
        }

        let keptSameWord =
            previousWordID != nil
            && previousWordID ==
                newWordID

        defaults.set(
            keptSameWord
            && previousSnapshot.readingOnlyAnswer == snapshot.readingOnlyAnswer
            && snapshot.allows(previousDirection)
            ? wasRevealed
            : false,
            forKey:
                PyokoWidgetConstants
                    .wordRevealedKey
        )

        let direction =
            normalizedDirection(
                previousDirection,
                snapshot:
                    snapshot
            )

        defaults.set(
            direction.rawValue,
            forKey:
                PyokoWidgetConstants
                    .wordDirectionKey
        )

        return true
    }

    // MARK: - Reveal

    var isWordRevealed:
        Bool {

        defaults?
            .bool(
                forKey:
                    PyokoWidgetConstants
                        .wordRevealedKey
            )
        ?? false
    }

    func revealWord() {

        defaults?
            .set(
                true,
                forKey:
                    PyokoWidgetConstants
                        .wordRevealedKey
            )
    }

    // MARK: - Word

    func currentWord(
        snapshot:
            PyokoWidgetSnapshot
    ) -> PyokoWidgetWord? {

        guard
            !snapshot.words.isEmpty
        else {

            return nil
        }

        let index =
            currentWordIndex(
                snapshot:
                    snapshot
            )

        return snapshot.words[
            index
        ]
    }

    func currentWordIndex(
        snapshot:
            PyokoWidgetSnapshot
    ) -> Int {

        guard
            !snapshot.words.isEmpty
        else {

            return 0
        }

        let storedIndex =
            defaults?
                .integer(
                    forKey:
                        PyokoWidgetConstants
                            .wordIndexKey
                )
            ?? 0

        guard
            storedIndex >= 0,
            storedIndex <
                snapshot.words.count
        else {

            return 0
        }

        return storedIndex
    }

    // MARK: - Direction

    func currentDirection(
        snapshot:
            PyokoWidgetSnapshot
    ) -> PyokoWidgetDirection {

        let rawValue =
            defaults?
                .string(
                    forKey:
                        PyokoWidgetConstants
                            .wordDirectionKey
                )

        let storedDirection =
            rawValue.flatMap {

                PyokoWidgetDirection(
                    rawValue:
                        $0
                )
            }

        return normalizedDirection(
            storedDirection,
            snapshot:
                snapshot
        )
    }

    // MARK: - Next

    func nextWord() {

        let snapshot =
            loadSnapshot()

        guard
            !snapshot.words.isEmpty
        else {

            defaults?
                .set(
                    false,
                    forKey:
                        PyokoWidgetConstants
                            .wordRevealedKey
                )

            return
        }

        let currentIndex =
            currentWordIndex(
                snapshot:
                    snapshot
            )

        let nextIndex:
            Int

        if snapshot.words.count == 1 {

            nextIndex =
                0

        } else {

            var candidate =
                currentIndex

            while candidate ==
                    currentIndex {

                candidate =
                    Int.random(
                        in:
                            0..<snapshot
                                .words
                                .count
                    )
            }

            nextIndex =
                candidate
        }

        defaults?
            .set(
                nextIndex,
                forKey:
                    PyokoWidgetConstants
                        .wordIndexKey
            )

        defaults?
            .set(
                chooseDirection(
                    snapshot:
                        snapshot
                )
                .rawValue,
                forKey:
                    PyokoWidgetConstants
                        .wordDirectionKey
            )

        defaults?
            .set(
                false,
                forKey:
                    PyokoWidgetConstants
                        .wordRevealedKey
            )
    }

    // MARK: - Tap

    func handleTap() {

        if isWordRevealed {

            nextWord()

        } else {

            revealWord()
        }
    }

    // MARK: - Helpers

    private func normalizedDirection(
        _ direction:
            PyokoWidgetDirection?,
        snapshot:
            PyokoWidgetSnapshot
    ) -> PyokoWidgetDirection {

        if let direction,
           snapshot.allows(
                direction
           ) {

            return direction
        }

        return chooseDirection(
            snapshot:
                snapshot
        )
    }

    private func chooseDirection(
        snapshot:
            PyokoWidgetSnapshot
    ) -> PyokoWidgetDirection {

        switch (
            snapshot.includeRecognition,
            snapshot.includeRecall
        ) {

        case (
            true,
            true
        ):

            return Bool.random()
            ? .recognition
            : .recall

        case (
            true,
            false
        ):

            return .recognition

        case (
            false,
            true
        ):

            return .recall

        case (
            false,
            false
        ):

            return .recognition
        }
    }
}

/// The app and extension always share the same App Group preferences.
enum PyokoWidgetStore {
    private static var store: WidgetStore {
        WidgetStore(defaults: UserDefaults(suiteName: PyokoWidgetConstants.appGroupIdentifier))
    }

    static func loadSnapshot() -> PyokoWidgetSnapshot { store.loadSnapshot() }
    @discardableResult
    static func saveSnapshot(_ snapshot: PyokoWidgetSnapshot) -> Bool { store.saveSnapshot(snapshot) }
    static var isWordRevealed: Bool { store.isWordRevealed }
    static func revealWord() { store.revealWord() }
    static func currentWord(snapshot: PyokoWidgetSnapshot) -> PyokoWidgetWord? { store.currentWord(snapshot: snapshot) }
    static func currentWordIndex(snapshot: PyokoWidgetSnapshot) -> Int { store.currentWordIndex(snapshot: snapshot) }
    static func currentDirection(snapshot: PyokoWidgetSnapshot) -> PyokoWidgetDirection { store.currentDirection(snapshot: snapshot) }
    static func nextWord() { store.nextWord() }
    static func handleTap() { store.handleTap() }
}
