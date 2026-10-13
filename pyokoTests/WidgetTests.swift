import Foundation
import SwiftData
import Testing
@testable import pyoko

@MainActor
@Suite(.serialized)
struct WidgetTests {
    @Test func randomPairsAndMissingReadings() {
        let value = word("one")
        #expect(PyokoWidgetPair.kanjiEnglish.text(for: value).secondary == "eat")
        #expect(PyokoWidgetPair.hiraganaEnglish.text(for: value).primary == "たべる")
        #expect(PyokoWidgetPair.kanjiHiragana.text(for: value).secondary == "たべる")
        let missing = PyokoWidgetWord(id: "missing", source: "thanks", target: "ありがとう", reading: nil)
        #expect(PyokoWidgetPair.hiraganaEnglish.text(for: missing).primary == "ありがとう")
        #expect(PyokoWidgetPair.kanjiHiragana.text(for: missing).secondary == nil)
    }

    @Test func randomModeAdvancesWithoutRevealAndThrottlesRefresh() throws {
        try withDefaults { store, _ in
            var value = snapshot([word("one"), word("two")]); value.mode = .random
            #expect(store.saveSnapshot(value))
            let now = Date(timeIntervalSince1970: 10000)
            let first = store.currentWord(snapshot: value)?.id
            store.handleTap(at: now)
            let second = store.currentWord(snapshot: value)?.id
            #expect(first != second)
            #expect(!store.isWordRevealed)
            store.refreshRandomWordIfNeeded(at: now.addingTimeInterval(1))
            #expect(store.currentWord(snapshot: value)?.id == second)
            store.refreshRandomWordIfNeeded(at: now.addingTimeInterval(WidgetStore.randomRefreshInterval))
            #expect(store.currentWord(snapshot: value)?.id == first)
            value.expiresAt = now
            #expect(store.saveSnapshot(value))
            store.handleTap(at: now)
            #expect(store.currentWord(snapshot: value)?.id == first)
        }
    }

    @Test func randomModePreservesFiltersAndLegacyPreferences() throws {
        let s = try TestStore(), deck = s.deck(), hidden = s.deck("Hidden")
        let card = s.card(deck), excluded = s.card(hidden)
        let config = s.config([deck])
        var prefs = PyokoWidgetConfig()
        prefs.source = .decks; prefs.deckIDs = [deck.id]; prefs.theme = "rose"
        let legacy = PyokoWidgetConfig.decode(prefs.encoded)
        #expect(legacy.mode == nil && legacy.deckIDs == prefs.deckIDs && legacy.theme == "rose")
        prefs.mode = .random; prefs.pair = .hiraganaEnglish
        let decoded = PyokoWidgetConfig.decode(prefs.encoded)
        #expect(decoded == prefs)
        let result = WidgetSync.makeSnapshot(config: config, cards: [card, excluded], now: s.now, preferences: decoded)
        #expect(result.isRandom && result.pair == .hiraganaEnglish && result.words.count == 1)
        let lock = LockScreenWordContent(word: result.words.first, snapshot: result, date: s.now)
        #expect(lock.japanese == result.words.first?.displayReading)
        #expect(lock.meaning == result.words.first?.source)
    }

    @Test func randomEmptyAndSingleWordAreSafe() throws {
        try withDefaults { store, _ in
            var value = snapshot([]); value.mode = .random
            #expect(store.saveSnapshot(value)); store.handleTap()
            #expect(store.currentWord(snapshot: value) == nil)
            value = snapshot([word("only")]); value.mode = .random
            #expect(store.saveSnapshot(value)); store.handleTap()
            #expect(store.currentWord(snapshot: value)?.id == "only")
            value.mode = .review
            #expect(store.saveSnapshot(value)); store.handleTap()
            #expect(store.isWordRevealed)
        }
    }
    private func snapshot(_ words: [PyokoWidgetWord], recognition: Bool = true, recall: Bool = false) -> PyokoWidgetSnapshot {
        PyokoWidgetSnapshot(publishedAt: .now, words: words, includeRecognition: recognition,
                            includeRecall: recall, readingOnlyAnswer: false)
    }
    private func word(_ id: String) -> PyokoWidgetWord {
        PyokoWidgetWord(id: id, source: "eat", target: "食べる", reading: "たべる", deckName: "N5 Vocab")
    }
    private func withDefaults(_ run: (WidgetStore, UserDefaults) throws -> Void) throws {
        let name = "PyokoTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        try run(WidgetStore(defaults: defaults), defaults)
    }

    @Test func decodesOldSnapshotsAndRoundTripsDeckName() throws {
        let data = Data(#"{"id":"old","source":"eat","target":"食べる","reading":null}"#.utf8)
        let old = try JSONDecoder().decode(PyokoWidgetWord.self, from: data)
        #expect(old.displayDeckName == "Vocabulary" && old.displayReading == "食べる")
        var value = word("new"); value.deckName = "  N5 Vocab  "
        let decoded = try JSONDecoder().decode(PyokoWidgetWord.self, from: JSONEncoder().encode(value))
        #expect(decoded.displayDeckName == "N5 Vocab")
        value.deckName = "  "; #expect(value.displayDeckName == "Vocabulary")
    }

    @Test func snapshotFiltersAndKeepsSameWordFromDifferentDecks() throws {
        let s = try TestStore(); let n5 = s.deck(), n4 = s.deck("N4")
        let a = s.card(n5), pair = s.card(n5, type: .recall), b = s.card(n4)
        let hidden = s.card(s.deck("Hidden"))
        let config = s.config([n5,n4]); try s.context.save()
        let result = WidgetSync.makeSnapshot(config: config, cards: [a,pair,b,hidden], now: s.now)
        #expect(result.words.count == 2)
        #expect(Set(result.words.compactMap(\.deckName)) == ["N5 Vocab","N4"])
        #expect(result.publishedAt == s.now)
        config.selectedDecks = []
        #expect(WidgetSync.makeSnapshot(config: config, cards: [a,b], now: s.now).words.isEmpty)
    }

    @Test func widgetFiltersAreIndependentAndRespectDisabledDecks() throws {
        let s = try TestStore()
        let enabled = s.deck(), disabled = s.deck("Disabled")
        let a = s.card(enabled), b = s.card(enabled, english: "water", kanji: "水")
        let hidden = s.card(disabled)
        let tag = PyokoTag(name: "Verb"); s.context.insert(tag); a.tags = [tag]
        let config = s.config([enabled]); config.selectedTags = [tag]
        try s.context.save()
        var prefs = PyokoWidgetConfig()
        let all = WidgetSync.makeSnapshot(config: config, cards: [a,b,hidden], now: s.now)
        #expect(all.words.count == 2) // Review tags do not filter the widget.
        prefs.source = .filtered; prefs.tagIDs = [tag.id]
        let filtered = WidgetSync.makeSnapshot(config: config, cards: [a,b,hidden], now: s.now, preferences: prefs)
        #expect(filtered.words.count == 1)
        prefs.chooseCards = true
        #expect(WidgetSync.makeSnapshot(config: config, cards: [a,b], now: s.now, preferences: prefs).words.isEmpty)
        prefs.wordIDs = Set(filtered.words.map(\.id))
        #expect(WidgetSync.makeSnapshot(config: config, cards: [a,b], now: s.now, preferences: prefs).words.count == 1)
        prefs.tagIDs = [UUID()]
        #expect(WidgetSync.makeSnapshot(config: config, cards: [a,b], now: s.now, preferences: prefs).words.isEmpty)
    }

    @Test func todayExcludesPendingYesterdayAndDisabledWordsAndExpires() throws {
        let s = try TestStore(); let deck = s.deck(); let config = s.config([deck])
        let a = s.card(deck), pair = s.card(deck, type: .recall)
        let old = s.card(deck, english: "water", kanji: "水")
        let hidden = s.card(s.deck("Disabled"))
        let reviews = [
            PyokoReviewCard(reviewDate: s.now, reviewed: true, card: pair),
            PyokoReviewCard(reviewDate: s.now, reviewed: false, card: old),
            PyokoReviewCard(reviewDate: s.now.addingTimeInterval(-86400), reviewed: true, card: old),
            PyokoReviewCard(reviewDate: s.now, reviewed: true, card: hidden)
        ]
        for review in reviews { s.context.insert(review) }
        try s.context.save()
        var prefs = PyokoWidgetConfig(); prefs.source = .today; prefs.theme = "ruby"
        let today = WidgetSync.makeSnapshot(config: config, cards: [a,pair,old,hidden], now: s.now, preferences: prefs, reviews: reviews)
        #expect(today.words.count == 1 && today.theme == "ruby")
        let all = WidgetSync.makeSnapshot(config: config, cards: [a,pair], now: s.now)
        #expect(today.words.first?.id == all.words.first?.id)
        let expiry = try #require(today.expiresAt)
        #expect(!today.isExpired(at: expiry.addingTimeInterval(-1)))
        #expect(today.isExpired(at: expiry))
        #expect(WidgetSync.makeSnapshot(config: config, cards: [a,pair], now: expiry, preferences: prefs, reviews: reviews).words.isEmpty)
    }

    @Test func preferencesRoundTripAndOldSnapshotStillDecodes() throws {
        var prefs = PyokoWidgetConfig(); prefs.source = .filtered
        prefs.wordIDs = ["word"]; prefs.tagIDs = [UUID()]; prefs.theme = "forest"
        #expect(PyokoWidgetConfig.decode(prefs.encoded) == prefs)
        #expect(PyokoWidgetConfig.decode(Data("broken".utf8)) == PyokoWidgetConfig())
        let data = Data(#"{"publishedAt":0,"words":[],"includeRecognition":true,"includeRecall":true,"readingOnlyAnswer":false}"#.utf8)
        let old = try JSONDecoder().decode(PyokoWidgetSnapshot.self, from: data)
        #expect(old.theme == nil && !old.isExpired(at: .now))
    }

    @Test func separateDeckAndTagSourcesRequireSelection() throws {
        let s = try TestStore(); let deck = s.deck(), other = s.deck("Other")
        let a = s.card(deck), b = s.card(other)
        let tag = PyokoTag(name: "Verb"); s.context.insert(tag); b.tags = [tag]
        let config = s.config([deck, other]); try s.context.save()
        var prefs = PyokoWidgetConfig(); prefs.source = .decks
        #expect(WidgetSync.makeSnapshot(config: config, cards: [a,b], now: s.now, preferences: prefs).words.isEmpty)
        prefs.deckIDs = [deck.id]
        #expect(WidgetSync.makeSnapshot(config: config, cards: [a,b], now: s.now, preferences: prefs).words.first?.deckName == deck.name)
        prefs.source = .tags
        #expect(WidgetSync.makeSnapshot(config: config, cards: [a,b], now: s.now, preferences: prefs).words.isEmpty)
        prefs.tagIDs = [tag.id]
        #expect(WidgetSync.makeSnapshot(config: config, cards: [a,b], now: s.now, preferences: prefs).words.first?.deckName == other.name)
        config.selectedDecks = [deck]
        #expect(WidgetSync.makeSnapshot(config: config, cards: [a,b], now: s.now, preferences: prefs).words.isEmpty)
    }

    @Test func widgetAndPreviewRespectJapaneseDisplayModes() {
        var data = snapshot([word("one")])
        data.before = .reading; data.after = .reading
        let recognition = WidgetWordView(word: word("one"), direction: .recognition, revealed: false, snapshot: data)
        #expect(recognition.questionText == "たべる")
        #expect(recognition.answerText == "eat")
        let recall = WidgetWordView(word: word("one"), direction: .recall, revealed: true, snapshot: data)
        #expect(recall.questionText == "eat" && recall.answerText == "たべる")
        let readingOnly = PyokoWidgetSnapshot(publishedAt: .now, words: [], includeRecognition: true,
            includeRecall: false, readingOnlyAnswer: true, before: .reading)
        let quiz = WidgetWordView(word: word("one"), direction: .recognition, revealed: true, snapshot: readingOnly)
        #expect(quiz.questionText == "食べる" && quiz.answerText == "たべる")
    }

    @Test func corruptCacheAndInvalidIndexRecover() throws {
        try withDefaults { store, defaults in
            defaults.set(Data("broken".utf8), forKey: PyokoWidgetConstants.snapshotKey)
            #expect(store.loadSnapshot().words.isEmpty)
            let data = snapshot([word("one")])
            defaults.set(-2, forKey: PyokoWidgetConstants.wordIndexKey)
            #expect(store.currentWordIndex(snapshot: data) == 0)
            defaults.set(999, forKey: PyokoWidgetConstants.wordIndexKey)
            #expect(store.currentWord(snapshot: data)?.id == "one")
            #expect(store.currentWord(snapshot: .empty) == nil)
        }
    }

    @Test func revealNextAndRefreshPreserveCurrentWord() throws {
        try withDefaults { store, defaults in
            let initial = snapshot([word("one"),word("two")])
            #expect(store.saveSnapshot(initial))
            let id = try #require(store.currentWord(snapshot: initial)?.id)
            store.handleTap(); #expect(store.isWordRevealed)
            let reordered = snapshot(Array(initial.words.reversed()))
            #expect(store.saveSnapshot(reordered))
            #expect(store.currentWord(snapshot: reordered)?.id == id)
            #expect(store.isWordRevealed)
            store.handleTap()
            #expect(store.currentWord(snapshot: reordered)?.id != id)
            #expect(!store.isWordRevealed)
            defaults.set("recall", forKey: PyokoWidgetConstants.wordDirectionKey)
            #expect(store.currentDirection(snapshot: reordered) == .recognition)
            #expect(store.saveSnapshot(snapshot([word("replacement")], recognition: false, recall: true)))
            #expect(!store.isWordRevealed)
            #expect(store.currentDirection(snapshot: store.loadSnapshot()) == .recall)
        }
    }

    @Test func changingDirectionResetsRevealedAnswer() throws {
        try withDefaults { store, _ in
            #expect(store.saveSnapshot(snapshot([word("one")])))
            store.revealWord()
            #expect(store.saveSnapshot(snapshot([word("one")], recognition: false, recall: true)))
            #expect(!store.isWordRevealed)
        }
    }

    @Test func oneWordAndEmptyNextDoNotLoop() throws {
        try withDefaults { store, _ in
            #expect(store.saveSnapshot(snapshot([word("one")])))
            store.revealWord(); store.nextWord()
            #expect(!store.isWordRevealed)
            #expect(store.currentWord(snapshot: store.loadSnapshot())?.id == "one")
            #expect(store.saveSnapshot(.empty))
            store.nextWord()
            #expect(store.currentWord(snapshot: .empty) == nil)
        }
    }
}
