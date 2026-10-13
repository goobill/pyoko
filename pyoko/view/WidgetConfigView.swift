import SwiftUI
import SwiftData

/// Saves widget preferences immediately; publishing never changes review scores.
struct WidgetConfigView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PyokoWidgetConfig.preferenceKey) private var stored = Data()
    @Query(sort: \PyokoConfig.createdAt) private var configs: [PyokoConfig]
    @Query private var cards: [PyokoCard]
    @Query private var reviews: [PyokoReviewCard]
    @Query(sort: \PyokoTag.name) private var tags: [PyokoTag]
    @Query(sort: \PyokoDeck.name) private var decks: [PyokoDeck]
    @State private var revealed = false
    @State private var direction: PyokoWidgetDirection = .recognition
    @State private var previewWordID: String?

    private var isRandom: Bool { preferences.mode == .random }

    private func previewWord(_ result: PyokoWidgetSnapshot) -> PyokoWidgetWord {
        result.words.first(where: { $0.id == previewWordID }) ?? result.words.first
            ?? PyokoWidgetWord(id: "preview", source: "to eat", target: "食べる", reading: "たべる", deckName: "Example")
    }

    private func advancePreview() {
        if isRandom {
            let result = snapshot(preferences)
            let current = previewWord(result).id
            previewWordID = result.words.filter { $0.id != current }.randomElement()?.id ?? current
        } else {
            revealed.toggle()
        }
    }

    private var preferences: PyokoWidgetConfig { .decode(stored) }
    private func binding<T>(_ key: WritableKeyPath<PyokoWidgetConfig, T>) -> Binding<T> {
        Binding(get: { preferences[keyPath: key] }, set: { value in
            var updated = preferences
            updated[keyPath: key] = value
            stored = updated.encoded
        })
    }
    private func snapshot(_ preferences: PyokoWidgetConfig) -> PyokoWidgetSnapshot {
        guard let config = configs.first else {
            return PyokoWidgetSnapshot(publishedAt: .now, words: [],
                includeRecognition: preferences.recognition, includeRecall: preferences.recall,
                readingOnlyAnswer: preferences.readingOnly, theme: preferences.theme,
                before: preferences.before, after: preferences.after,
                mode: preferences.mode, pair: preferences.pair)
        }
        return WidgetSync.makeSnapshot(config: config, cards: cards, now: .now,
                                       preferences: preferences, reviews: reviews)
    }
    private var availableTags: [PyokoTag] {
        let enabled = Set((configs.first?.selectedDecks ?? []).map(\.id))
        let ids = Set(cards.filter { $0.deck.map { enabled.contains($0.id) } ?? false }
            .flatMap { ($0.tags ?? []).map(\.id) })
        return tags.filter { ids.contains($0.id) }
    }

    private var activeDirection: PyokoWidgetDirection {
        preferences.recognition && preferences.recall ? direction : (preferences.recognition ? .recognition : .recall)
    }
    private var enabledDecks: [PyokoDeck] {
        let enabled = Set((configs.first?.selectedDecks ?? []).map(\.id))
        return decks.filter { enabled.contains($0.id) }
    }
    private func modeBinding(_ key: WritableKeyPath<PyokoWidgetConfig, TargetDisplayMode?>,
                             default fallback: TargetDisplayMode) -> Binding<TargetDisplayMode> {
        Binding(get: { preferences[keyPath: key] ?? fallback }, set: { binding(key).wrappedValue = $0 })
    }
    private func directionBinding(_ key: WritableKeyPath<PyokoWidgetConfig, Bool>,
                                  other: WritableKeyPath<PyokoWidgetConfig, Bool>) -> Binding<Bool> {
        Binding(get: { preferences[keyPath: key] }, set: { value in
            if value || preferences[keyPath: other] { binding(key).wrappedValue = value }
        })
    }

    var body: some View {
        ConfigWorkspace {
            GroupBox("Widget Mode") {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Mode", selection: Binding(get: { preferences.mode ?? .review },
                        set: { binding(\.mode).wrappedValue = $0 })) {
                        Text("Review").tag(PyokoWidgetMode.review)
                        Text("Random").tag(PyokoWidgetMode.random)
                    }.pickerStyle(.segmented)
                    .accessibilityIdentifier("widget.mode")
                    if isRandom {
                        Picker("Show", selection: Binding(get: { preferences.pair ?? .kanjiEnglish },
                            set: { binding(\.pair).wrappedValue = $0 })) {
                            ForEach(PyokoWidgetPair.allCases, id: \.self) { pair in
                                Text(pair.title).tag(pair)
                            }
                        }.accessibilityIdentifier("widget.pair")
                        Text("Shows both fields immediately. Rotates when the system refreshes the widget; tap the Home Screen widget for another word. A new word on every viewing cannot be guaranteed.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if !isRandom {
                CardConfigView(
                    recognition: directionBinding(\.recognition, other: \.recall),
                    recall: directionBinding(\.recall, other: \.recognition),
                    before: modeBinding(\.before, default: .target),
                    after: modeBinding(\.after, default: .targetAndReading),
                    hiraganaOnly: binding(\.readingOnly), hint: .constant(false), showsHint: false
                )
            }
        } preview: {
                GroupBox("Widget Preview") {
                    VStack(spacing: 12) {
                        if !isRandom && preferences.recognition && preferences.recall {
                            Picker("Preview Direction", selection: $direction) {
                                Text("Recognition").tag(PyokoWidgetDirection.recognition)
                                Text("Recall").tag(PyokoWidgetDirection.recall)
                            }.pickerStyle(.segmented)
                            .accessibilityIdentifier("widget.direction")
                        }
                        let result = snapshot(preferences)
                        let word = previewWord(result)
                        Button { advancePreview() } label: {
                            WidgetWordView(word: word, direction: activeDirection, revealed: revealed, snapshot: result)
                                .padding().frame(height: 190)
                                .background((PyokoTheme(rawValue: preferences.theme) ?? .classic).background(for: scheme),
                                            in: RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(.plain)
                        .accessibilityIdentifier("widget.preview")
                        .accessibilityLabel(isRandom ? "Next random word" : (revealed ? "Reset preview" : "Reveal preview answer"))
                        Button(isRandom ? "Next Word" : (revealed ? "Reset Preview" : "Show Answer")) { advancePreview() }
                            .accessibilityIdentifier("widget.action")
                            .buttonStyle(.bordered)
                        Text(result.words.isEmpty ? "Example only — no matching words selected." : "Example only — does not change your progress.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                GroupBox("Lock Screen Preview") {
                    let result = snapshot(preferences)
                    let word = previewWord(result)
                    VStack(alignment: .leading, spacing: 12) {
                        LockScreenWordView(content: LockScreenWordContent(word: word, snapshot: result, date: .now))
                            .frame(width: 170, height: 76)
                            .padding(12)
                            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityIdentifier("widget.lockPreview")
                            .modifier(LockPreviewAlignment())
                        Text("The lock-screen widget shows your selected pair in Random mode, or Japanese and English in Review mode. It uses the same vocabulary selection. Add Word Review when customising your iPhone Lock Screen.")
                            .font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityIdentifier("widget.lockPanel")
        } vocabulary: {
                GroupBox("Vocabulary") {
                    VStack(spacing: 6) {
                        ForEach(PyokoWidgetConfig.Source.allCases, id: \.self) { source in
                            Button {
                                binding(\.source).wrappedValue = source
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: preferences.source == source ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(preferences.source == source ? Color.accentColor : Color.secondary)
                                    Text(source.title).foregroundStyle(.primary)
                                    Spacer()
                                }.padding(.vertical, 5).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                            .accessibilityIdentifier("widget.source.\(source.rawValue)")
                            .accessibilityValue(preferences.source == source ? "Selected" : "Not selected")
                        }
                    }
                }
                if preferences.source == .decks {
                    GroupBox("Selected Decks") {
                        VStack(spacing: 12) {
                            HStack {
                                Button("Select All") { binding(\.deckIDs).wrappedValue = Set(enabledDecks.map(\.id)) }
                                    .accessibilityIdentifier("widget.decks.all")
                                Spacer()
                                Button("Deselect All") { binding(\.deckIDs).wrappedValue = [] }
                                    .accessibilityIdentifier("widget.decks.none")
                            }.buttonStyle(.borderless)
                            ForEach(enabledDecks) { deck in
                                Toggle(deck.name, isOn: Binding(get: { (preferences.deckIDs ?? []).contains(deck.id) }, set: { selected in
                                    var ids = preferences.deckIDs ?? []
                                    if selected { ids.insert(deck.id) } else { ids.remove(deck.id) }
                                    binding(\.deckIDs).wrappedValue = ids
                                }))
                                .accessibilityIdentifier("widget.deck.\(deck.catalogKey ?? deck.id.uuidString)")
                            }
                            if (preferences.deckIDs ?? []).isEmpty {
                                Text("Select at least one enabled deck.").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if preferences.source == .tags {
                    TagSelectionView(title: "Selected Tags", tags: availableTags,
                        selectedTags: Binding(get: { availableTags.filter { preferences.tagIDs.contains($0.id) } },
                                             set: { binding(\.tagIDs).wrappedValue = Set($0.map(\.id)) }),
                        emptySelectionMessage: "Select at least one tag. Words may match any selected tag.")
                }
        } footer: {
                GroupBox("Theme") {
                    Picker("Widget Theme", selection: binding(\.theme)) {
                        Text("Default (System)").tag("system")
                        ForEach(PyokoTheme.allCases) { theme in Text(theme.title).tag(theme.rawValue) }
                    }
                    .accessibilityIdentifier("widget.theme")
                }
                GroupBox {
                    VStack(spacing: 8) {
                        Text("\(snapshot(preferences).words.count) words available")
                            .accessibilityIdentifier("widget.count")
                        if preferences.source == .today {
                            Text("Only words actually reviewed today. Complete a review to add words here.")
                        }
                        Text("Only enabled decks are included. Saved automatically on this device for all Word Review widgets. Open Pyoko to refresh synced words.")
                    }.font(.caption).foregroundStyle(.secondary)
                }
        }
        .pyokoSurface()
        .navigationTitle("Widget Config")
        .onChange(of: stored) { _, _ in revealed = false; previewWordID = nil; WidgetSync.refresh(modelContext: context) }
        .onChange(of: direction) { _, _ in revealed = false }
        .task {
            // Migrate the previous combined filter UI to the matching source choice.
            if preferences.source == .filtered {
                var updated = preferences
                updated.source = updated.tagIDs.isEmpty ? .all : .tags
                updated.chooseCards = false
                updated.wordIDs = []
                stored = updated.encoded
            }
        }
    }
}

private struct LockPreviewAlignment: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        HStack {
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
        }
        #else
        content
        #endif
    }
}
