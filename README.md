# Pyoko

Pyoko is a native SwiftUI spaced-repetition language-learning app for iPhone and macOS.

The project started as a Japanese vocabulary app, but the core data model and review system are intentionally designed to support other language pairs in the future, such as English ↔ French.

Pyoko currently focuses on:

- importing vocabulary decks
- generating Recognition and Recall flashcards
- scheduling reviews using FSRS
- configurable review sessions
- reading hints
- configurable target/reading display
- deck and tag filtering
- built-in and imported decks
- a dark/light/system appearance setting
- future on-device AI sentence practice using Apple Foundation Models

The app should remain:

- native-first
- offline-friendly where practical
- simple to maintain
- testable
- CloudKit-ready without enabling CloudKit yet
- suitable for iOS and native macOS

---

# 1. Technology Stack

## Core

- Swift
- SwiftUI
- SwiftData
- FSRS via `open-spaced-repetition/swift-fsrs`

## Platforms

Minimum target:

- iOS 17+
- macOS 14+

## Future AI

Sentence Practice is planned to use Apple's on-device language model through the Foundation Models framework / Apple Intelligence where available.

The AI layer should be isolated behind project-owned services so it can be replaced later without restructuring the app.

---

# 2. High-Level Architecture

Pyoko is split conceptually into five main areas:

```text
Pyoko
│
├── Models
│   ├── PyokoCard
│   ├── PyokoDeck
│   ├── PyokoTag
│   ├── PyokoReviewCard
│   ├── PyokoConfiguration
│   └── sentence-practice models
│
├── Import / Deck Management
│   ├── DataLoader
│   ├── DeckManager
│   ├── GoogleSheetsCSVURL
│   └── built-in deck catalogue
│
├── Review
│   ├── CardRetrieval
│   ├── CardManager
│   ├── ReviewView
│   ├── ReviewCardView
│   └── ReviewIntervalFormatter
│
├── Configuration
│   ├── ConfigurationView
│   ├── TargetDisplayMode
│   ├── AppearancePreference
│   └── ExampleCardView
│
└── Sentence Practice
    ├── SentencePracticeConfiguration
    ├── SentenceWordSelector
    ├── SentencePromptBuilder
    ├── SentenceGenerator
    ├── SentenceAnswerMatcher
    ├── SentenceAnswerEvaluator
    ├── SentencePracticeManager
    └── sentence-practice views
```

Responsibilities should stay separated.

In particular:

- `CardRetrieval` decides **which cards are eligible**
- `CardManager` owns **review-session lifecycle and FSRS scheduling**
- views should not reproduce scheduling logic
- import code should not contain review UI logic
- sentence-generation code should not be mixed into flashcard scheduling code

---

# 3. Core Data Model

The SwiftData schema should remain CloudKit-friendly even while CloudKit is disabled.

## 3.1 `PyokoDeck`

Represents a vocabulary deck.

Expected fields:

```swift
@Model
final class PyokoDeck {
    var id: UUID = UUID()
    var catalogKey: String?
    var name: String = ""

    var origin: DeckOrigin = DeckOrigin.file
    var originName: String?
    var originURLString: String?
    var originIdentifier: String?

    var vocabularyCount: Int = 0
    var recognitionCount: Int = 0
    var recallCount: Int = 0
    var importedAt: Date = Date.now

    @Relationship(
        deleteRule: .cascade,
        inverse: \PyokoCard.deck
    )
    var cards: [PyokoCard]? = []

    var configurations: [PyokoConfiguration]? = []
}
```

### Purpose

A deck is the user-facing replacement for the older `DataSource` terminology.

Use **Deck** consistently in:

- code
- navigation
- UI copy
- documentation

Do not reintroduce `DataSource` terminology.

### `catalogKey`

Used for installed built-in decks.

Examples:

```text
jlpt-n5
jlpt-n4
```

It allows Pyoko to determine whether a built-in deck has already been installed.

---

## 3.2 `DeckOrigin`

Tracks where a deck came from.

Expected cases:

```swift
enum DeckOrigin: String, Codable, CaseIterable {
    case builtIn
    case file
    case url
    case googleSheets

    // Reserved for future direct integrations.
    case googleDrive
    case iCloudDrive
}
```

Current behaviour:

- Built-in deck → `.builtIn`
- Generic file import → `.file`
- Direct HTTP URL → `.url`
- Public/published Google Sheet → `.googleSheets`

### Important

Generic `.fileImporter` imports must remain `.file`.

The app must **not attempt to infer** that a generic file came from:

- iCloud Drive
- Google Drive
- Dropbox
- another File Provider

Provider identity is not reliable enough through the generic system file picker.

Native Google Drive or iCloud integrations may use the reserved enum cases later.

---

## 3.3 `PyokoTag`

Represents a reusable vocabulary tag.

Expected structure:

```swift
@Model
final class PyokoTag {
    var id: UUID = UUID()
    var name: String = ""
    var cards: [PyokoCard]? = []
    var configurations: [PyokoConfiguration]? = []
}
```

Tags should survive deck deletion.

Deleting a deck should delete its cards, but not delete globally reusable tags.

---

## 3.4 `PyokoCard`

Represents an actual schedulable Recognition or Recall card.

Conceptual structure:

```swift
@Model
final class PyokoCard {
    var id: UUID = UUID()

    var type: CardType = .recognition

    var sourceText: String = ""
    var targetText: String = ""
    var targetReading: String?

    var deck: PyokoDeck?

    @Relationship(
        deleteRule: .cascade,
        inverse: \PyokoReviewCard.card
    )
    var reviewCards: [PyokoReviewCard]? = []

    @Relationship(
        deleteRule: .nullify,
        inverse: \PyokoTag.cards
    )
    var tags: [PyokoTag]? = []

    // FSRS state
    var due: Date = .now
    var stability: Double = 0
    var difficulty: Double = 0
    var elapsedDays: Double = 0
    var scheduledDays: Double = 0
    var learningSteps: Int = 0
    var reps: Int = 0
    var lapses: Int = 0
    var state: CardState = .new
    var lastReview: Date?
}
```

### Card types

```swift
enum CardType: String, Codable {
    case recognition = "RECOGNITION"
    case recall = "RECALL"
}
```

Meaning:

```text
Recognition = Target → Source
Recall      = Source → Target
```

Example:

```text
sourceText      = "to eat"
targetText      = "食べる"
targetReading   = "たべる"
```

Recognition:

```text
食べる
↓
to eat
```

Recall:

```text
to eat
↓
食べる / たべる
```

---

## 3.5 `PyokoReviewCard`

Represents a card placed into the current daily review queue.

Expected structure:

```swift
@Model
final class PyokoReviewCard {
    var id: UUID = UUID()
    var reviewDate: Date = .now
    var reviewed: Bool = false
    var card: PyokoCard?
}
```

### Important relationship rule

Deleting a `PyokoReviewCard` must **not** delete the underlying vocabulary card.

The cascade relationship is owned by:

```text
PyokoCard → PyokoReviewCard
```

not the other way around.

---

## 3.6 `PyokoConfiguration`

Stores the persisted flashcard-review configuration.

Current expected fields:

```swift
@Model
final class PyokoConfiguration {
    var id: UUID = UUID()

    var dailyCardLimit: Int = 20
    var minimumNewCards: Int = 0

    var beforeAnswerDisplayMode: TargetDisplayMode = TargetDisplayMode.target
    var afterAnswerDisplayMode: TargetDisplayMode = TargetDisplayMode.reading

    var showRecognitionCards: Bool = true
    var showRecallCards: Bool = true

    var readingHintEnabled: Bool = true

    var selectedDecks: [PyokoDeck]? = []
    var selectedTags: [PyokoTag]? = []
}
```

The configuration should auto-save.

The app should normally have one review configuration.

---

# 4. CloudKit / SwiftData Requirements

CloudKit is not enabled yet, but the schema should remain compatible.

## Rules

Avoid:

- `@Attribute(.unique)`
- required relationships
- `.deny` delete rules

Prefer:

- UUID identifiers
- optional relationships
- explicit inverse relationships
- `.cascade` and `.nullify`

Current storage configuration should explicitly disable CloudKit:

```swift
ModelConfiguration(
    "Pyoko",
    schema: schema,
    isStoredInMemoryOnly: false,
    cloudKitDatabase: .none
)
```

When CloudKit is eventually enabled:

- use a private iCloud database
- add iCloud capability
- add Background Modes / Remote Notifications as required
- introduce a proper migration plan before release

---

# 5. Database Migration Policy

The schema is still evolving.

During development:

- incompatible SwiftData schema changes may require resetting the local development database
- deleting DerivedData does **not** reset SwiftData
- on Simulator, deleting the app normally resets the store
- on macOS, the sandbox/container data may need deleting manually

Before production release:

- add `VersionedSchema`
- add `SchemaMigrationPlan`
- stop relying on destructive resets

---

# 6. Vocabulary Import Format

CSV import format is fixed to exactly four columns:

```csv
source,target,reading,tags
to eat,食べる,たべる,N5|Verbs
mother,母,はは,N5|Family
hello,bonjour,,Greetings
```

## Rules

The first row:

- is always treated as the header
- is ignored
- header names are not validated

Every subsequent row must contain exactly four columns.

### Column rules

#### `source`

Required.

#### `target`

Required.

#### `reading`

Optional.

Empty value should become:

```swift
nil
```

#### `tags`

Optional.

Pipe-separated:

```text
N5|Family
```

If empty, assign:

```text
No Tag
```

This row is valid:

```csv
data,data,,
```

---

# 7. Import Sources

Current import UI should offer:

```text
File
URL
Google Sheets
```

## 7.1 File

Uses the system file picker.

It may expose:

- local files
- iCloud Drive
- Google Drive
- Dropbox
- other installed File Providers

No provider-specific credentials are required.

Security-scoped access must be respected:

```swift
let accessing = url.startAccessingSecurityScopedResource()

defer {
    if accessing {
        url.stopAccessingSecurityScopedResource()
    }
}
```

Do not persist the selected URL as permanent file access unless proper security-scoped bookmarks are later implemented.

---

## 7.2 URL

Supports HTTP/HTTPS CSV URLs.

Provenance:

```text
origin = .url
```

---

## 7.3 Google Sheets

Current support is for:

- publicly readable sheets
- published sheets

The sheet is converted to a CSV export URL and then passed through the same CSV import path.

Private sheets are not supported yet.

Future private-sheet support would require:

- Google Cloud project
- Google OAuth
- Google Sign-In
- Google Sheets API and/or Drive export
- appropriate scopes

---

# 8. Import Behaviour

All import paths should converge on one shared CSV import implementation.

The shared importer should:

1. validate deck name
2. validate Recognition/Recall selection
3. parse UTF-8 CSV
4. reject invalid row shapes
5. prevent duplicate deck installation
6. create/reuse tags
7. create the deck
8. create Recognition cards if enabled
9. create Recall cards if enabled
10. update deck metadata counts
11. automatically select the newly imported deck in the existing review configuration
12. save the SwiftData context

---

# 9. Automatically Selecting Newly Imported Decks

A newly imported or installed deck should automatically become selected in the user's current review configuration.

Reason:

An empty `selectedDecks` array intentionally means:

```text
Review no decks
```

Without auto-selection, importing cards into an already-created empty configuration can result in zero eligible review cards.

Expected behaviour:

- append only the newly imported deck
- keep previously manually deselected decks deselected
- if no configuration exists yet, do nothing
- initial configuration creation already selects all installed decks

Built-in deck installation should also receive this behaviour by going through `DataLoader`.

---

# 10. Built-In Decks

Current planned built-ins:

- JLPT N5
- JLPT N4
- Idioms

N3 must not be included in the new default catalogue.

An already installed N3 deck should not be deleted automatically.

Built-in decks should install both:

- Recognition cards
- Recall cards

Built-in installation should use stable catalogue keys.

Example:

```swift
DefaultDeck(
    key: "jlpt-n5",
    name: "JLPT N5",
    description: "Beginner Japanese vocabulary for JLPT N5.",
    urlString: "..."
)
```

---

# 11. Deck Management UI

The user-facing page is called:

```text
Decks
```

not Sources or Data Sources.

Desired behaviour:

## Imported decks

Show:

- deck name
- vocabulary count
- origin
- delete action

When there are no imported decks:

```text
No Imported Decks

Import a CSV, URL, or Google Sheet
using the + button above.
```

Do **not** show a duplicate plus/import button inside the empty state.

The top-right toolbar import button is enough.

## Built-in decks

Each row should support:

- Download when not installed
- Installed indicator when installed
- Delete after installation
- re-download after deletion

---

# 12. Deck Provenance

Decks should retain useful origin metadata.

Examples:

## Built-in

```text
origin             builtIn
originName         JLPT N5
originIdentifier   jlpt-n5
originURLString    source URL
```

## File

```text
origin             file
originName         vocabulary.csv
originURLString    nil
originIdentifier   nil
```

## Google Sheet

```text
origin             googleSheets
originName         Google Sheet
originURLString    original sheet URL
originIdentifier   spreadsheetID:gid
```

UI can render provenance using `DeckOriginView`.

---

# 13. Review Selection Logic

`CardRetrieval` owns card eligibility and selection.

It should handle:

- due-date filtering
- selected decks
- selected tags
- Recognition enabled/disabled
- Recall enabled/disabled
- daily card limit
- minimum-new-card reservation
- due-date ordering

Do not move these decisions into `ReviewView`.

---

# 14. Daily Card Limit

Default:

```text
20
```

The daily session may contain no more than this number of cards.

---

# 15. Minimum New Cards

Setting:

```text
Minimum New Cards
```

Default:

```text
0
```

Meaning:

Reserve at least this many places for new cards when enough eligible new cards are available.

It is a **minimum reservation**, not a maximum.

Examples:

```text
daily 20, min new 0
100 reviews + 100 new
→ 20 reviews

daily 20, min new 5
100 reviews + 100 new
→ 15 reviews + 5 new

daily 20, min new 5
100 reviews + 2 new
→ 18 reviews + 2 new

daily 20, min new 5
4 reviews + 100 new
→ 4 reviews + 16 new

daily 20, min new 20
enough new
→ 20 new
```

New card definition:

```swift
card.state == CardState.new
```

If daily limit decreases, clamp minimum new cards so:

```text
minimumNewCards <= dailyCardLimit
```

---

# 16. Review Session Lifecycle

`CardManager` owns the daily session.

Expected behaviour:

- if no review queue exists → generate one
- if queue belongs to a previous day → regenerate
- if today's queue is unfinished → keep it
- if today's non-empty queue is complete → keep it complete
- configuration changes normally affect the next generated session, not an already-created same-day queue

The Home screen should call:

```swift
CardManager.startReviewIfNeeded()
```

before entering the review page so remaining-card count is available.

`ReviewView` should consume the existing queue rather than regenerating it.

---

# 17. FSRS Scheduling

Pyoko uses FSRS through `swift-fsrs`.

`CardManager` is responsible for:

- converting `PyokoCard` → FSRS `Card`
- calling the scheduler
- copying the resulting FSRS state back into `PyokoCard`
- marking the corresponding `PyokoReviewCard` reviewed
- saving SwiftData

Current review API conceptually:

```swift
manager.reviewCard(
    id: currentCard.id,
    rating: rating
)
```

Ratings:

```text
Again
Hard
Good
Easy
```

---

# 18. FSRS Rating Preview

Before the user selects a review rating, Pyoko previews the next interval for all four FSRS outcomes.

Example:

```text
1m
5m
10m
16d
```

These must come from the actual FSRS scheduler.

Do not hardcode them.

Preview calculation should:

- create the FSRS card
- use the same timestamp for all four outcomes
- call `scheduler.next(...)` for each rating
- read `result.card.due`
- **not** update SwiftData
- **not** mutate the actual card

A helper such as `ReviewIntervalFormatter` converts dates into compact strings:

```text
<1m
1m
5m
1h
6h
1d
14d
2mo
1y
```

---

# 19. Review Screen UX

The current intended review UI is deliberately minimal.

## Top bar

Do not show a large:

```text
Review
```

title.

Instead:

```text
[Back]   [Progress Bar]   15/20
```

This saves vertical space and makes the card the primary focus.

---

## Card

The card should:

- have a fixed size during the question and answer states
- not resize when the answer is revealed
- support tapping anywhere on the card to reveal
- display a clear Recognition/Recall label
- show Hint in the top-right when available
- make the primary vocabulary larger
- scale down gracefully for long text

Example question state:

```text
┌──────────────────────────────────┐
│ 👁 Recognition          💡 Hint │
│                                  │
│                                  │
│             食べる               │
│                                  │
│                                  │
│       Tap card to reveal         │
└──────────────────────────────────┘
```

Example answer state:

```text
┌──────────────────────────────────┐
│ 👁 Recognition                  │
│                                  │
│             食べる               │
│                                  │
│ ──────────────────────────────── │
│                                  │
│             たべる               │
│             to eat               │
└──────────────────────────────────┘
```

---

# 20. Show Answer Interaction

Before reveal, the area below the card should show only floating text:

```text
Show Answer
```

The text should use the app accent colour.

Example in the current default theme:

```text
blue
```

There should be:

- no pill
- no button background
- no border

The entire reserved area below the card should still be tappable.

The user may reveal by:

1. tapping the card
2. tapping anywhere in the Show Answer area

The action area should have fixed height so revealing the answer does not move the card.

---

# 21. Review Rating Controls

After reveal, the Show Answer area is replaced by the four FSRS interval choices.

The card itself must not resize or move.

Desired UI:

```text
How difficult was this card?

Harder                         Easier

  1m        5m        10m        16d
```

Each interval is a tappable rounded control.

Do not display:

```text
Again
Hard
Good
Easy
```

inside the visual buttons.

Internally the mapping remains:

```text
leftmost   → Again
second     → Hard
third      → Good
rightmost  → Easy
```

Accessibility should still expose these names.

Example VoiceOver labels:

```text
Again, next review 1 minute
Hard, next review 5 minutes
Good, next review 10 minutes
Easy, next review 16 days
```

---

# 22. Review Button Gradient

The four interval controls should use one accent colour with a subtle difficulty gradient.

Concept:

```text
Harder → Easier
dark   → light
```

The interface must not rely on colour alone.

The following also communicate difficulty:

- left-to-right ordering
- `Harder`
- `Easier`

The gradient should be subtle and adapt appropriately to light/dark mode.

---

# 23. Reading Hint

Reading hint is configurable.

Default:

```text
enabled
```

It is only shown when a reading actually exists.

## Placement

Top-right inside the card:

```text
💡 Hint
```

Use a lightbulb icon.

Do not use `textformat.abc`, which visually renders "Abc".

## Behaviour

When pressed:

- do not reveal the full answer
- reveal the reading as a clue inside the card
- allow toggling the hint if desired

Hide Hint when:

- answer is already revealed
- no reading exists
- reading hints are disabled
- Recognition front already displays reading

For Recall cards, Hint may be deliberately used as a clue.

---

# 24. Target Display Modes

The user can independently choose how target content appears:

- before answer
- after answer

Expected enum:

```swift
enum TargetDisplayMode: String, Codable, CaseIterable {
    case target
    case reading
    case targetAndReading
}
```

Supporting properties:

```swift
includesReading
includesTarget
```

Modes:

## Target

```text
食べる
```

## Reading

```text
たべる
```

## Target + Reading

Prefer stacked:

```text
食べる
たべる
```

rather than concatenating into one string.

If reading is nil:

```text
reading display falls back to target
```

This allows the same model to support languages without readings.

---

# 25. Configuration Screen

The main review Configuration page should include:

1. Daily Review
   - Daily Card Limit
   - Minimum New Cards

2. Card Types
   - Recognition
   - Recall

3. Target Display
   - Before Answer
   - After Answer

4. Reading Hint

5. Card Preview

6. Appearance

7. Deck selection

8. Tag selection

9. App version footer

Settings auto-save.

---

# 26. Recognition / Recall Configuration

Both default to enabled.

The user should not be allowed to disable both.

At least one card type must remain active.

---

# 27. Card Preview

Configuration includes a self-contained `ExampleCardView`.

Purpose:

- preview Recognition/Recall
- preview target/reading mode
- preview reading hint behaviour
- visually match the real review-card experience where practical

Example data:

```text
source  = to eat
target  = 食べる
reading = たべる
```

The preview should not instantiate real SwiftData cards.

Keep it independent from unknown model initializers.

---

# 28. Appearance

Appearance is a local UI preference, not SwiftData.

Store with:

```swift
@AppStorage("appearancePreference")
```

Choices:

```text
System
Light
Dark
```

Expected enum:

```swift
enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
}
```

The app root should apply:

```swift
.preferredColorScheme(...)
```

Use semantic SwiftUI colours/materials throughout.

Avoid hard-coded white/black backgrounds where possible.

---

# 29. App Version

Configuration / Settings should display version and build number at the bottom.

Read from the bundle:

```text
CFBundleShortVersionString
CFBundleVersion
```

Example:

```text
Version 1.2 (14)
```

Do not hardcode version numbers.

---

# 30. macOS Layout Requirements

A previous native macOS Configuration screen triggered AppKit constraint errors when using `Form`.

Current preferred approach:

```text
ScrollView
  → VStack
  → GroupBox sections
```

Use a finite content width such as:

```swift
.frame(maxWidth: 700)
```

Avoid:

```swift
.windowResizability(.contentSize)
```

unless a future implementation has been thoroughly tested.

---

# 31. Sentence Practice — Product Requirements

Sentence Practice is a planned major feature.

The user selects:

```text
Practice Sentences
```

from the app, then enters a configuration screen before starting.

The configuration must persist so returning later shows the same choices as last time.

Do not mix sentence-practice configuration into `PyokoConfiguration`.

Create a separate persistent model.

---

# 32. Sentence Practice Configuration

Planned options:

## Vocabulary source

```text
Random Vocabulary
Selected Decks
Selected Tags
Today's Review
```

Suggested enum:

```swift
enum SentenceVocabularyMode: String, Codable, CaseIterable {
    case random
    case decks
    case tags
    case todaysReview
}
```

---

## Vocabulary density

The user chooses how many target vocabulary items should be included per generated sentence.

Recommended user-facing options:

```text
Focused       1 word
Normal        2–3 words
Challenging   4–5 words
```

Suggested enum:

```swift
enum VocabularyDensity: String, Codable, CaseIterable {
    case focused
    case normal
    case challenging
}
```

Suggested ranges:

```text
focused       1...1
normal        2...3
challenging   4...5
```

Avoid forcing very large arbitrary numbers of unrelated words into one sentence.

---

## Sentence complexity

Suggested levels:

```text
Simple
Beginner
Intermediate
Advanced
```

The UI should expose learner-friendly terminology rather than raw LLM controls such as temperature.

---

## Sentence types

Multiple sentence styles may be enabled at once.

Current planned types:

```text
Present
Past
Future
Connecting
Longer sentences
```

The generator can randomly choose among enabled types during a session.

---

## Japanese display

Options:

```text
Kanji
Hiragana
Kanji + Hiragana
```

Suggested enum:

```swift
enum JapaneseDisplayMode: String, Codable, CaseIterable {
    case kanji
    case hiragana
    case kanjiAndHiragana
}
```

Recommended default:

```text
Kanji + Hiragana
```

When both are selected, show them stacked.

Example:

```text
昨日、友達と寿司を食べました。
きのう、ともだちとすしをたべました。
```

This is intentionally simpler than implementing furigana.

---

## Direction

Sentence Practice supports:

```text
Recognition
Recall
```

Recognition:

```text
Japanese → English
```

Recall:

```text
English → Japanese
```

Both may be enabled and randomly mixed.

At least one should remain enabled.

---

## Session count

User chooses number of sentences to practice.

Default can initially be:

```text
10
```

---

# 33. Sentence Practice Persistence

Only the configuration needs persistence in v1.

Suggested model:

```swift
@Model
final class SentencePracticeConfiguration {
    var id: UUID = UUID()

    var sentenceCount: Int = 10

    var vocabularyMode: SentenceVocabularyMode = .random
    var vocabularyDensity: VocabularyDensity = .normal

    var selectedDecks: [PyokoDeck]? = []
    var selectedTags: [PyokoTag]? = []

    var complexity: SentenceComplexity = .beginner

    var includePresent: Bool = true
    var includePast: Bool = true
    var includeFuture: Bool = false
    var includeConnecting: Bool = false
    var includeLong: Bool = false

    var japaneseDisplayMode: JapaneseDisplayMode = .kanjiAndHiragana

    var includeRecognition: Bool = true
    var includeRecall: Bool = true
}
```

Generated sentence sessions should initially remain in memory.

Do not persist generated sentence history until there is a clear product requirement for:

- history
- statistics
- favourites
- revisiting previous sessions

---

# 34. Sentence Vocabulary Selection

Create a dedicated:

```text
SentenceWordSelector
```

Its only responsibility is selecting vocabulary based on the saved configuration.

Possible input modes:

```text
random
decks
tags
todaysReview
```

The raw card database contains both Recognition and Recall versions of the same vocabulary.

Do not send duplicates to the LLM.

Create an intermediate type:

```swift
struct SentenceVocabulary {
    let sourceText: String
    let targetText: String
    let targetReading: String?
}
```

Deduplicate before generation.

---

# 35. Sentence Vocabulary Grouping

Do not send huge vocabulary lists and ask the model to force them all into sentences.

Instead:

1. select eligible vocabulary
2. split vocabulary into per-sentence groups
3. use the configured density
4. generate each sentence from a small target set

Example:

```text
Sentence 1:
食べる
昨日
寿司

Sentence 2:
電車
行く

Sentence 3:
母
電話
```

This should produce more natural language and make failures easier to isolate.

---

# 36. Apple On-Device LLM

The sentence feature should use Apple's built-in language model where supported.

Create a service such as:

```text
SentenceGenerator
```

This should be the only layer that directly knows about Apple's Foundation Models APIs.

Responsibilities:

- check model availability
- create language-model sessions
- send structured prompts
- generate typed responses
- expose useful errors to the UI

The UI must gracefully handle devices where Apple Intelligence / the model is unavailable.

Example message:

```text
Sentence Practice Unavailable

Sentence generation requires Apple Intelligence
to be available on this device.
```

---

# 37. Structured Sentence Generation

Do not parse free-form LLM text.

Use structured/guided generation.

A generated sentence should contain:

```swift
struct GeneratedSentence {
    var english: String
    var japanese: String
    var hiragana: String
    var alternativeAnswers: [GeneratedAlternativeAnswer]
    var usedVocabulary: [String]
}
```

Alternative:

```swift
struct GeneratedAlternativeAnswer {
    var japanese: String
    var hiragana: String
}
```

Always generate both:

- Japanese text
- Hiragana representation

regardless of the user's current display setting.

This means changing display mode does not require regenerating the sentence.

---

# 38. Multiple Valid Sentence Answers

Sentence translation is not one-to-one.

Generated practice items should include:

- one primary answer
- multiple acceptable/natural alternatives

Example English:

```text
I ate sushi with my friend yesterday.
```

Possible Japanese answers:

```text
昨日、友達と寿司を食べました。
昨日は友達と寿司を食べました。
友達と昨日寿司を食べました。
```

Alternative answers are primarily useful for answer evaluation.

They do not all need to be displayed by default.

---

# 39. Sentence Answer Evaluation

Do not use exact string matching as the only grading method.

Recommended grading pipeline:

```text
Student answer
      ↓
SentenceAnswerMatcher
      ↓
obvious local match?
  yes → correct
  no
      ↓
SentenceAnswerEvaluator
      ↓
Apple Foundation Model
```

## Local matcher

Can normalize:

- whitespace
- punctuation
- obvious equivalent formatting

If exact or clearly equivalent, avoid an unnecessary LLM evaluation.

## AI evaluator

Use the model to assess:

- meaning
- grammar
- required vocabulary usage

Do not require identical wording.

Suggested assessment levels:

```text
Correct
Mostly Correct
Incorrect
```

Suggested structured output:

```swift
struct SentenceAssessment {
    var assessment: AnswerAssessment
    var correctedAnswer: String?
    var explanation: String
    var vocabularyCorrect: Bool
    var grammarCorrect: Bool
}
```

AI feedback should be presented as:

```text
AI feedback
```

rather than authoritative exam grading.

Allow future support for:

```text
Mark as correct
```

when the model rejects a legitimate answer.

---

# 40. Japanese Script and Grading

`JapaneseDisplayMode` controls presentation only.

It must not determine whether an answer is correct.

For example, when display mode is Kanji, this could still be accepted:

```text
きのうともだちとすしをたべました
```

Likewise mixed kana/kanji may be correct:

```text
昨日ともだちと寿司を食べました
```

Evaluation should judge language correctness and meaning, not exact script choice.

---

# 41. Sentence Practice Architecture

Recommended structure:

```text
SentencePractice/
│
├── Models/
│   ├── SentencePracticeConfiguration.swift
│   ├── SentenceVocabularyMode.swift
│   ├── VocabularyDensity.swift
│   ├── SentenceComplexity.swift
│   ├── SentenceStyle.swift
│   ├── JapaneseDisplayMode.swift
│   ├── GeneratedSentence.swift
│   ├── SentencePracticeItem.swift
│   └── SentenceAssessment.swift
│
├── Generation/
│   ├── SentenceWordSelector.swift
│   ├── SentencePromptBuilder.swift
│   └── SentenceGenerator.swift
│
├── Evaluation/
│   ├── SentenceAnswerMatcher.swift
│   └── SentenceAnswerEvaluator.swift
│
├── Management/
│   └── SentencePracticeManager.swift
│
└── Views/
    ├── SentencePracticeConfigurationView.swift
    ├── SentencePracticeView.swift
    └── SentencePracticeCardView.swift
```

---

# 42. Sentence Practice Session Model

Initial generated sessions can be plain in-memory Swift structs.

Example:

```swift
struct SentencePracticeSession {
    let id = UUID()
    var items: [SentencePracticeItem]
    var currentIndex: Int
}
```

```swift
struct SentencePracticeItem: Identifiable {
    let id = UUID()
    let sentence: GeneratedSentence
    let direction: SentencePracticeDirection

    var userAnswer: String?
    var assessment: SentenceAssessment?
}
```

---

# 43. Sentence Prompt Design

Keep prompt construction isolated in:

```text
SentencePromptBuilder
```

Prompts should specify:

- learner level
- required vocabulary
- sentence style
- sentence length/complexity
- language pair
- natural language requirement
- no unnecessarily difficult grammar
- exact structured output contract

Avoid embedding large prompt strings directly inside views.

---

# 44. Sentence Practice Future Extensions

Potential future features:

- practice-history storage
- grammar weakness tracking
- vocabulary weakness tracking
- session statistics
- favourites
- sentence bookmarks
- bias future generation toward weak grammar
- sentence reading hint
- retry/regenerate sentence
- private Google Sheet vocabulary sources

Do not implement these until the core v1 experience is stable.

---

# 45. Current UI / UX Principles

Pyoko's current design direction is:

- minimal
- focused
- semantic SwiftUI styling
- dark-mode friendly
- avoid unnecessary labels
- avoid duplicate actions
- large tap targets
- preserve stable layout during interactions
- prefer card-focused review screens
- use accent colour for primary actions
- avoid large coloured panels unless they add meaning

Examples:

- remove redundant `Review` title
- one import button rather than duplicate empty-state button
- Show Answer as floating accent-coloured text rather than a large pill
- rating controls stay in a reserved fixed-height region
- Hint stays small and secondary

---

# 46. Cross-Platform Requirements

The app should build on:

- iOS
- native macOS

Wrap iOS-only modifiers.

Example:

```swift
#if os(iOS)
.textInputAutocapitalization(.never)
.keyboardType(.URL)
#endif
```

Use:

- `NavigationStack`
- semantic SwiftUI views
- `URLSession`
- `.fileImporter`
- SwiftData

Avoid platform-specific behaviour leaking throughout the app.

Prefer small helper extensions for differences.

---

# 47. Testing Requirements

Testing is a significant remaining task.

## Unit tests

Priorities:

### Card retrieval

Test:

- due-date eligibility
- deck selection
- tag filtering
- Recognition enabled/disabled
- Recall enabled/disabled
- daily limit
- minimum-new-card reservation
- due ordering

### Scheduling

Test:

- FSRS state updates
- Again/Hard/Good/Easy
- preview calculations do not mutate stored card
- interval formatting

### Import

Test:

- correct CSV
- empty reading
- empty tags
- default `No Tag`
- malformed row
- duplicate deck
- Recognition only
- Recall only
- both card types
- provenance
- auto-selection of newly imported deck

### Configuration

Test:

- defaults
- minimum-new-card clamping
- at least one card type enabled
- newly imported deck auto-selection

### Sentence practice

When implemented:

- vocabulary deduplication
- deck/tag/current-review selection
- vocabulary grouping
- structured generation decoding
- local answer normalization
- evaluator fallback

---

## UI tests

Important flows:

- import deck
- download built-in deck
- delete deck
- change configuration
- start review
- reveal by tapping card
- reveal through Show Answer area
- reading hint
- submit Again/Hard/Good/Easy
- finish session
- Recognition
- Recall
- light mode
- dark mode
- sentence-practice configuration persistence
- sentence generation availability state

---

# 48. Current Development Status

## Implemented / mostly implemented

- SwiftData vocabulary model
- FSRS scheduling
- Recognition cards
- Recall cards
- Deck terminology
- deck import
- URL import
- public Google Sheets import
- generic File Provider import
- deck provenance
- built-in deck architecture
- tag relationships
- configurable deck filtering
- configurable tag filtering
- daily card limit
- Minimum New Cards
- Recognition/Recall toggles
- Target / Reading / Target + Reading display
- configurable reading hint
- auto-save review configuration
- card preview
- dark/light/system appearance
- review progress
- stable daily review queue
- FSRS interval previews
- redesigned minimal review screen
- larger card content
- floating Show Answer interaction
- app version/build footer
- automatic selection of newly imported decks

## Planned / incomplete

- production N5 deck data
- production N4 deck data
- idioms deck
- robust deck update/upsert
- sentence practice
- Foundation Models integration
- AI sentence evaluation
- private Google Sheets
- native Google Drive integration
- comprehensive unit tests
- UI tests
- final accessibility audit
- full dark-mode polish
- SwiftData production migration plan
- CloudKit sync

---

# 49. Deck Update / Upsert — Future Requirement

Imported decks will eventually need safe updates.

Desired behaviour:

- stable deck/source identifier
- hash imported data
- detect changes
- update existing vocabulary
- insert new vocabulary
- handle removed vocabulary
- preserve FSRS review progress whenever a logical card still represents the same vocabulary

This requires careful identity design.

Do not implement naive delete-and-reimport if review history must be preserved.

---

# 50. Future Google Drive Integration

Current Google Drive support is through the system File Provider picker.

A native in-app Drive browser is optional future work.

It would require:

- Google Cloud project
- Drive API
- OAuth consent screen
- OAuth client IDs
- Google Sign-In
- Drive scopes
- stable Drive file identifiers

Only add this if Pyoko requires:

- browsing Drive inside the app
- automatically refreshing the same Drive file
- stable provider-specific provenance

---

# 51. Code Style / Maintenance Expectations

Prefer:

- small focused types
- clear names
- direct Swift
- readable formatting
- minimal indirection
- production code separated from Preview/test code
- full file replacements for major changes during active development
- comments explaining architectural intent rather than obvious syntax

Avoid:

- giant views
- duplicated filtering logic
- hardcoded review scheduling
- direct database manipulation scattered through UI
- platform checks everywhere
- speculative abstractions before a real use case exists

---

# 52. Important Invariants

A new maintainer should preserve the following behaviour unless product requirements explicitly change.

### Deck selection

```text
selectedDecks.isEmpty
```

means:

```text
review no decks
```

not "all decks".

### Tags

No selected tags means:

```text
no tag filter
```

not "no cards".

### Card direction

```text
Recognition = target → source
Recall      = source → target
```

### Reading fallback

If `targetReading == nil`:

```text
reading display = targetText
```

### Minimum New Cards

It is a minimum reservation, not a maximum.

### Review queue

Today's existing queue remains stable.

### FSRS preview

Must not mutate the card.

### Sentence Japanese display

Controls presentation, not correctness.

---

# 53. Recommended Development Order

Suggested next work:

1. Stabilize and visually polish current Review screen
2. Add unit tests for CardRetrieval and CardManager
3. Add import/provenance tests
4. Add UI tests for core review flow
5. Finalise N5/N4/Idioms built-in datasets
6. Design and implement safe deck update/upsert
7. Implement persistent Sentence Practice configuration
8. Implement SentenceWordSelector
9. Implement Foundation Models generation
10. Implement sentence Recall/Recognition UI
11. Add multiple valid answers
12. Add local matching and AI evaluation
13. Accessibility and dark-mode audit
14. Introduce SwiftData migrations before release
15. Consider CloudKit sync
16. Consider private Google / native Drive integrations only if needed

---

# 54. Handoff Notes

The project has changed quickly during active development.

If an implementation detail in this README conflicts with the current compiler-visible code:

1. preserve the current public API where practical
2. verify the exact current model/service implementation before renaming methods
3. prefer adapting the new functionality to the existing API rather than causing broad unrelated churn

Historically, some older saved code used:

```text
DataSource / PyokoDataSource
```

The project has since been renamed to:

```text
Deck / PyokoDeck
```

Do not regress to the old terminology.

Likewise, older `CardManager` versions contained filtering logic directly. The intended current architecture is:

```text
CardRetrieval → eligibility / selection
CardManager   → session / scheduling
```

Keep that separation.

---

# 55. Product Summary

Pyoko should feel like a lightweight, native language-learning app rather than a complicated study-management tool.

The core interaction is:

```text
Import / install vocabulary
        ↓
Choose what to study
        ↓
Review due cards
        ↓
Use FSRS to schedule the next review
        ↓
Optionally practise vocabulary in generated sentences
```

The product should stay simple on the surface even when the implementation underneath becomes more sophisticated.

The highest priorities are:

- reliable scheduling
- clear review interactions
- readable Japanese
- flexible deck/tag filtering
- easy imports
- saved user preferences
- high-quality offline/on-device sentence practice
- maintainable architecture
