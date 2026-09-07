# Pyoko

Pyoko is a native SwiftUI language-learning app for iPhone and macOS.

The app combines:

- FSRS-based daily spaced-repetition reviews
- persistent review configuration
- quick vocabulary practice that does not affect FSRS
- on-device sentence practice using Apple Foundation Models where available
- configurable Recognition / Recall directions
- reading-focused Japanese study
- deck and tag filtering
- local, URL, and public Google Sheets vocabulary imports

Pyoko started as a Japanese vocabulary app, but the vocabulary and review model is intentionally generic enough to support other language pairs later.

---

# 1. Technology Stack

## Core

- Swift
- SwiftUI
- SwiftData
- FSRS via `open-spaced-repetition/swift-fsrs`

## Platforms

Minimum deployment target:

- iOS 17+
- macOS 14+

Sentence generation uses Apple's Foundation Models framework only where available.

Foundation Models requires newer OS versions and Apple Intelligence-compatible hardware. The rest of Pyoko should continue to work normally when sentence generation is unavailable.

## Persistence

The current local model configuration explicitly disables CloudKit:

```swift
ModelConfiguration(
    "Pyoko",
    schema: schema,
    isStoredInMemoryOnly: false,
    cloudKitDatabase: .none
)
```

The schema should remain CloudKit-friendly so syncing can be added later.

---

# 2. Product Principles

Pyoko should remain:

- simple
- native-first
- focused on study rather than configuration overhead
- offline-friendly where practical
- readable and maintainable
- testable
- transparent about review behaviour
- protective of existing FSRS progress
- usable on both iPhone and native macOS

The app should feel like a lightweight study tool, not a complicated learning-management system.

---

# 3. Main Study Modes

Pyoko currently has three distinct study modes:

```text
Study
├── Review
│   └── Scheduled FSRS review
│
├── Quick Review
│   └── Temporary vocabulary practice
│       No FSRS changes
│
└── Practice Sentences
    └── Generated contextual practice
        No FSRS changes
```

These modes deliberately have separate configuration and session logic.

---

# 4. Current Project Structure

Conceptually:

```text
Pyoko
│
├── enum/
│   ├── TargetDisplayMode.swift
│   ├── QuickEnums.swift
│   └── SentenceEnums.swift
│
├── logic/
│   ├── CardRetrieval.swift
│   ├── CardManager.swift
│   ├── DeckManager.swift
│   ├── TodayReviewProvider.swift
│   │
│   ├── QuickSelector.swift
│   ├── QuickManager.swift
│   │
│   ├── SentenceSelector.swift
│   ├── SentenceManager.swift
│   └── SentenceGenerator.swift
│
├── model/
│   ├── PyokoCard.swift
│   ├── PyokoDeck.swift
│   ├── PyokoTag.swift
│   ├── PyokoReviewCard.swift
│   ├── PyokoConfig.swift
│   ├── PyokoQuickConfig.swift
│   ├── PyokoQuickCard.swift
│   ├── PyokoSentenceConfig.swift
│   └── PyokoSentence.swift
│
├── view/
│   ├── HomeView.swift
│   ├── ConfigView.swift
│   ├── ExampleCardView.swift
│   ├── DecksView.swift
│   ├── DeckOriginView.swift
│   │
│   ├── ReviewView.swift
│   ├── ReviewCardView.swift
│   ├── ReviewCompleteView.swift
│   │
│   ├── QuickConfigView.swift
│   ├── QuickCardView.swift
│   ├── QuickView.swift
│   │
│   ├── SentenceConfigView.swift
│   ├── SentenceCardView.swift
│   └── SentenceView.swift
│
└── Assets.xcassets/
    └── AppIcon
```

Exact folder layout may evolve, but responsibilities should remain separated.

---

# 5. Naming Conventions

Use **Deck** everywhere.

Do not reintroduce the older `DataSource` terminology.

Current configuration naming:

```text
PyokoConfig
PyokoQuickConfig
PyokoSentenceConfig

ConfigView
QuickConfigView
SentenceConfigView
```

Use `Config`, not `Configuration`, for current project naming where the refactor has already been completed.

---

# 6. Vocabulary Import Format

CSV import uses exactly four columns:

```csv
source,target,reading,tags
to eat,食べる,たべる,N5|Verbs
mother,母,はは,N5|Family
hello,bonjour,,Greetings
```

Rules:

- the first row is always treated as a header and ignored
- header names are not inspected
- every later row must contain exactly four columns
- `source` is required
- `target` is required
- empty `reading` becomes `nil`
- empty `tags` becomes `No Tag`
- tags are pipe-separated
- malformed rows should be rejected

This is valid:

```csv
data,data,,
```

---

# 7. Card Directions

Pyoko uses two standard vocabulary directions.

## Recognition

```text
Target → Source
```

Example:

```text
食べる
↓
to eat
```

## Recall

```text
Source → Target
```

Example:

```text
to eat
↓
食べる
```

Recognition and Recall may both be enabled.

At least one direction must remain enabled.

---

# 8. Reading Behaviour

A vocabulary card may contain:

```text
sourceText
targetText
targetReading
```

Example:

```text
sourceText      = "to eat"
targetText      = "食べる"
targetReading   = "たべる"
```

If `targetReading == nil`:

```text
reading display = targetText
```

Pyoko does not use furigana.

---

# 9. Target Display Modes

`TargetDisplayMode` supports:

```swift
enum TargetDisplayMode: String, Codable, CaseIterable {
    case target
    case reading
    case targetAndReading
}
```

Meaning:

## Target

```text
食べる
```

## Reading

```text
たべる
```

## Target + Reading

Prefer stacked presentation:

```text
食べる
たべる
```

The user can independently configure target presentation before and after reveal.

---

# 10. Reading-Only Recognition

Daily Review and Quick Review support an additional Recognition mode intended for reading practice.

Normal Recognition:

```text
食べる
↓
to eat
```

Reading-only Recognition:

```text
食べる
↓
たべる
```

This is useful for practising:

```text
Kanji → Hiragana
```

The persisted property names currently differ between the two configs:

```text
Daily Review:  PyokoConfig.readingOnlyAnswer
Quick Review:  PyokoQuickConfig.recognitionReadingOnlyEnabled
```

This naming difference is historical and does not change the user-facing behaviour.

Behaviour:

- applies only to Recognition cards
- the question shows `targetText`
- the answer shows `targetReading`
- if reading is missing, fall back to `targetText`
- Reading Hint must be hidden in this mode because it would reveal the answer
- Recall behaviour remains unchanged

The setting exists independently in:

```text
PyokoConfig
PyokoQuickConfig
```

---

# 11. Core SwiftData Models

The persistent schema currently includes the main vocabulary, review, and configuration models.

Conceptually:

```text
PyokoDeck
PyokoTag
PyokoCard
PyokoReviewCard
PyokoConfig
PyokoQuickConfig
PyokoSentenceConfig
```

Generated sentence items and Quick Review session cards should remain in memory rather than becoming persisted study-history models.

---

# 12. PyokoDeck

A deck groups imported vocabulary and stores provenance.

Important fields include:

```text
id
catalogKey
name
origin
originName
originURLString
originIdentifier
vocabularyCount
recognitionCount
recallCount
importedAt
cards
configs
quickConfigs
sentenceConfigs
```

`originDetail` is a computed presentation property used by `DeckOriginView`.

Deleting a deck should delete its cards.

Tags should not be deleted simply because a deck is removed.

---

# 13. Deck Origins

Current supported origins:

```text
builtIn
file
url
googleSheets
```

Reserved/future origins may include:

```text
googleDrive
iCloudDrive
```

Generic `.fileImporter` imports remain `.file`.

Do not infer the provider from a generic File Provider URL.

---

# 14. Import Sources

Current import UI:

```text
File
URL
Google Sheets
```

## File

Uses the system file picker.

This may expose:

- local files
- iCloud Drive
- Google Drive
- Dropbox
- other File Providers

## URL

Supports direct HTTP/HTTPS CSV URLs.

## Google Sheets

Supports public or published Google Sheets converted into CSV export URLs.

Private Google Sheets are not currently supported.

---

# 15. Deck Selection

The normal review configuration's:

```swift
selectedDecks
```

is the source of truth for whether a deck participates in future daily reviews.

Do not add a separate `isEnabled` flag to `PyokoDeck`.

An empty selected-deck collection means:

```text
review no decks
```

not:

```text
review all decks
```

Newly imported decks should automatically be added to the existing review selection while preserving decks the user deliberately disabled.

---

# 16. Tags

Tag selection is persisted independently in each study configuration.

All tag-selection config UIs should provide:

```text
X of Y selected
Select All
Deselect All
```

## Daily Review

The main `ConfigView` only displays tags that are available from the currently enabled decks.

`Select All` selects every tag currently available from those enabled decks.

`Deselect All` clears the currently available selected tags.

For the main Daily Review config:

```text
selectedTags.isEmpty
```

means:

```text
no tag filter
```

not:

```text
no cards
```

Therefore, pressing **Deselect All** in the Daily Review config means that cards from every tag in the enabled decks remain eligible.

If enabled decks change, tags that are no longer available should be removed from `selectedTags`.

## Quick Review

When Quick Review uses:

```text
Selected Tags
```

the tag selector supports Select All / Deselect All.

For this explicit source mode, an empty tag selection is invalid:

```text
selectedTags.isEmpty
→ disable Start Quick Review
```

## Sentence Practice

When Sentence Practice uses:

```text
Selected Tags
```

the tag selector also supports Select All / Deselect All and displays the selected count.

An empty tag selection is invalid:

```text
selectedTags.isEmpty
→ disable Start Practice
```

Tag selections in Daily Review, Quick Review, and Sentence Practice must remain independent from one another.

---

# 17. Main Review Config

`PyokoConfig` persists settings for scheduled FSRS Review.

Important settings include:

```text
dailyCardLimit
minimumNewCards
showRecognitionCards
showRecallCards
readingOnlyAnswer
beforeAnswerDisplayMode
afterAnswerDisplayMode
readingHintEnabled
selectedDecks
selectedTags
```

The Config screen also contains the local appearance preference.

Settings auto-save.

---

# 18. Daily Card Limit

Default:

```text
20
```

The initial daily queue may contain no more than the configured limit.

---

# 19. Minimum New Cards

Default:

```text
0
```

This is a minimum reservation, not a maximum.

Example:

```text
daily limit = 20
minimum new = 5
100 review cards due
100 new cards available

→ 15 review cards
→ 5 new cards
```

If fewer reserved new cards exist, reviews may fill the remaining space.

`minimumNewCards` must never exceed `dailyCardLimit`.

A new card means:

```swift
card.state == .new
```

---

# 20. Review Selection Architecture

Responsibilities must stay separated:

```text
CardRetrieval
    ↓
eligibility / filtering / selection

CardManager
    ↓
session lifecycle / FSRS scheduling
```

`CardRetrieval` handles:

- due-date filtering
- selected decks
- selected tags
- Recognition / Recall settings
- daily card limit
- minimum-new reservation
- due ordering

`ReviewView` should not reproduce card-selection logic.

---

# 21. Daily Review Session Lifecycle

`CardManager` owns the scheduled review queue.

Expected start behaviour:

```text
No queue
    ↓
Generate today's queue

Previous-day queue
    ↓
Generate new queue

Unfinished queue from today
    ↓
Keep it unchanged

Completed queue from today
    ↓
Keep it complete
```

Configuration changes normally affect the next generated queue rather than silently rebuilding an existing same-day session.

---

# 22. Extending a Completed Daily Review

When the learner completes the current daily queue, Pyoko checks whether more eligible cards are already due.

If more cards are due now:

```text
Review Complete

53 more cards are due now.

[ Review 20 More Cards ]
[ Back to Home ]
```

The extension:

- appends another batch to the existing queue
- does not delete completed queue records
- uses up to the current daily card limit
- may be repeated until there are no more cards due now

Example:

```text
Initial:
20 / 20

Extend:
20 / 40

Extend:
40 / 60
```

If a card reviewed earlier becomes due again according to FSRS, it may legitimately re-enter a later extension.

Cards scheduled later today are **not** pulled forward early.

If nothing is due now but cards are scheduled later today, the completion state may show:

```text
Caught Up for Now

No more cards are due right now.
3 cards are scheduled later today.

[ Check Again ]
[ Back to Home ]
```

---

# 23. FSRS Scheduling

Only scheduled Daily Review changes FSRS state.

`CardManager.reviewCard(...)`:

1. retrieves the real `PyokoCard`
2. converts it to an FSRS `Card`
3. calls the scheduler
4. copies the returned FSRS state back
5. marks the queue item reviewed
6. saves SwiftData

The four learner ratings are:

```text
Again
Hard
Good
Easy
```

The FSRS package also exposes `.manual`; Pyoko does not expose Manual as a normal learner rating.

---

# 24. FSRS Interval Preview

Before the learner rates a Daily Review card, Pyoko previews the next due interval for:

```text
Again
Hard
Good
Easy
```

The preview:

- must come from the real FSRS scheduler
- must use the same `now` value for each rating
- must not mutate the stored card
- must not persist any state

Example visual values:

```text
1m
5m
10m
16d
```

The visual controls may show only intervals while accessibility labels retain the rating names.

---

# 25. Daily Review UI

The Daily Review screen should remain card-focused.

Top bar:

```text
[Back]   [Progress Bar]   15/20
```

Avoid a large redundant `Review` title.

Question card:

```text
┌──────────────────────────────────┐
│ Recognition             💡 Hint │
│                                  │
│             食べる               │
│                                  │
│       Tap card to reveal         │
└──────────────────────────────────┘
```

After reveal, the card remains the same size.

The action area below the card also keeps a fixed height so the card does not jump vertically.

---

# 26. Reading Hint

Reading Hint:

- is configurable
- only appears when reading exists
- is hidden after reveal
- is hidden when the front already exposes the reading
- is hidden for reading-only Recognition
- may be used as a clue on Recall cards

The hint should remain visually small and secondary.

---

# 27. Quick Review

Quick Review is a temporary vocabulary practice mode.

It never calls the FSRS scheduling path.

Quick Review:

- has its own persisted config
- chooses vocabulary independently
- may practise Recognition, Recall, or both
- may use Writing mode
- tracks Correct / Incorrect during the current session
- may retry incorrect cards
- may reset the session
- does not change normal review scheduling

---

# 28. Quick Review Vocabulary Sources

`QuickSource` supports:

```text
Random Vocabulary
Selected Decks
Selected Tags
Today's Review
```

## Random Vocabulary

Uses vocabulary from decks enabled in the normal `PyokoConfig`.

## Selected Decks

Uses Quick Review's own `selectedDecks`.

## Selected Tags

Uses Quick Review's own `selectedTags`.

## Today's Review

Uses vocabulary that actually appeared in today's completed scheduled-review history.

Quick Review's deck/tag choices must never modify the normal review config.

---

# 29. Today's Review Provider

Shared logic lives in:

```text
TodayReviewProvider
```

It is used by both:

```text
Quick Review
Sentence Practice
```

Responsibilities:

- find reviewed `PyokoReviewCard` records from the current day
- map them back to vocabulary
- deduplicate Recognition / Recall duplicates
- expose vocabulary count
- expose whether today's review vocabulary is available

Example duplicate pair:

```text
Recognition
食べる → to eat

Recall
to eat → 食べる
```

becomes one vocabulary item:

```text
source:  to eat
target:  食べる
reading: たべる
```

---

# 30. Today's Review Availability

Both Quick Review and Sentence Practice are intended to validate the `Today's Review` source before starting.

When no vocabulary has been reviewed today:

- the option should remain visible
- the option should be disabled
- the UI should explain why
- Start should also be disabled if a persisted config still points to `Today's Review`

Example:

```text
○ Today's Review
  No reviewed vocabulary available today.
```

## Current implementation note

Quick Review has the availability-check architecture through `TodayReviewProvider`.

The current `SentenceConfigView` still treats `.todaysReview` as startable once the model, direction, and sentence-type checks pass. The Sentence Config therefore still needs the same `TodayReviewProvider` availability guard before this requirement is fully complete.

---

# 31. Quick Review Config

`PyokoQuickConfig` persists Quick Review preferences.

Current settings include:

```text
cardCount
source
writingEnabled
includeRecognition
includeRecall
recognitionReadingOnlyEnabled
beforeAnswerDisplayMode
afterAnswerDisplayMode
readingHintEnabled
selectedDecks
selectedTags
```

At least one of Recognition / Recall must remain enabled.

When the source is `Selected Tags`, Quick Review exposes bulk tag actions:

```text
Select All
Deselect All
```

and the session cannot start with zero selected tags.

---

# 32. Quick Review Without Writing

Flow:

```text
Question
   ↓
Reveal Answer
   ↓
Correct / Incorrect
   ↓
Next Card
```

There are no FSRS difficulty choices.

The learner self-assesses only:

```text
Incorrect
Correct
```

---

# 33. Quick Review Writing Mode

Writing is an interaction option, not a direction.

The learner may enable:

```text
Writing + Recognition
Writing + Recall
Writing + Recognition + Recall
```

## Writing + Recognition

Normal Recognition:

```text
食べる
↓
type "to eat"
```

Reading-only Recognition:

```text
食べる
↓
type "たべる"
```

## Writing + Recall

```text
to eat
↓
type "食べる"
```

After the learner submits:

```text
Correct answer
Your answer
```

are both displayed.

Pyoko does not automatically grade the typed answer.

The learner then chooses:

```text
Incorrect
Correct
```

This result exists only for the current Quick Review session.

---

# 34. Quick Review Result Tracking

Quick Review always displays:

```text
Correct: X
Incorrect: Y
```

Results are tracked by original Quick Review card.

At completion:

```text
Quick Review Complete

17 Correct
3 Incorrect

[ Review 3 Incorrect Cards ]
[ Reset Review ]
[ Back to Quick Review ]
```

## Review Incorrect

Only currently incorrect cards are placed into the retry round.

If an incorrect card is later marked Correct, its original result is updated.

Example:

```text
17 Correct / 3 Incorrect
        ↓
Review Incorrect
        ↓
19 Correct / 1 Incorrect
```

When all cards become correct:

```text
20 Correct / 0 Incorrect
```

`Review Incorrect` disappears.

## Reset Review

Restarts the original Quick Review set and clears temporary Correct / Incorrect results.

No Quick Review result should mutate FSRS.

---

# 35. Sentence Practice

Sentence Practice is separate from both scheduled Review and Quick Review.

The current flow is:

```text
Persistent Sentence Config
        ↓
Select vocabulary
        ↓
Generate sentence exercise
        ↓
Learner reveals answer
        ↓
Self-evaluate / continue
```

Sentence practice does not change FSRS.

---

# 36. Sentence Practice Config

`PyokoSentenceConfig` is persisted independently.

Current configuration concepts include:

## Vocabulary source

```text
Random Vocabulary
Selected Decks
Selected Tags
Today's Review
```

Random Vocabulary respects decks enabled in the main `PyokoConfig`.

Selected Decks and Selected Tags use sentence-specific selections.

Today's Review uses `TodayReviewProvider`.

## Vocabulary density

```text
Focused       1
Normal        2–3
Challenging   4–5
```

## Complexity

```text
Simple
Beginner
Intermediate
Advanced
```

## Sentence types

Multiple may be enabled:

```text
Present
Past
Future
Connecting
Longer sentences
```

## Direction

```text
Recognition
Recall
Both
```

At least one remains enabled.

## Japanese display

```text
Kanji
Hiragana
Kanji + Hiragana
```

Default:

```text
Kanji + Hiragana
```

## Tag bulk selection

When the vocabulary source is `Selected Tags`, `SentenceConfigView` shows:

```text
X of Y selected
Select All
Deselect All
```

`Select All` assigns all currently available `PyokoTag` records to the sentence config.

`Deselect All` clears `selectedTags`.

Because `.tags` is an explicit vocabulary source, Start Practice remains disabled until at least one tag is selected.

---

# 37. Sentence Generation

Sentence generation uses Apple's Foundation Models where available.

Keep Foundation Models isolated in:

```text
SentenceGenerator
```

The rest of the sentence-practice architecture should not depend directly on Apple's APIs.

Use:

```swift
#if canImport(FoundationModels)
```

and availability guards for newer OS versions.

The feature must fail gracefully when:

- the OS is too old
- the device is not Apple Intelligence-capable
- Apple Intelligence is disabled
- model assets are not ready
- the model is otherwise unavailable

---

# 38. Structured Sentence Output

Do not parse arbitrary free-form model text.

Generate structured data containing at least:

```text
English
Japanese
Hiragana
used vocabulary
primary answer
alternative answers
```

Always generate both:

```text
Japanese
Hiragana
```

regardless of current display mode.

Changing presentation should not require regenerating the sentence.

---

# 39. Sentence Answer Handling

Current product direction:

- Foundation Models generates the exercise
- Pyoko does not rely on AI evaluation for learner grading
- the learner reveals the primary answer
- alternative valid answers may also be shown
- the learner self-evaluates
- sentence practice does not mutate FSRS

Generated sentence session objects remain in memory for now.

Do not persist sentence history until there is a clear product requirement.

---

# 40. Appearance

Appearance is a local UI preference stored with:

```swift
@AppStorage("appearancePreference")
```

Choices:

```text
System
Light
Dark
```

The app root applies the matching:

```swift
.preferredColorScheme(...)
```

Use semantic SwiftUI colours and avoid hard-coded white/black UI backgrounds where possible.

---

# 41. Config Screen Layout

The main `ConfigView` should use:

```text
ScrollView
  → finite-width VStack
  → GroupBox sections
```

This avoids the native macOS layout problems previously seen with `Form`.

A practical maximum content width is approximately:

```swift
.frame(maxWidth: 700)
```

Current review config concepts include:

1. Daily Review
2. Card Types
3. Recognition Answer / Reading Only
4. Target Display
5. Reading Hint
6. Card Preview
7. Appearance
8. Decks
9. Tags, including Select All / Deselect All
10. Version footer

The Daily Review tag list is limited to tags available in enabled decks.

Settings auto-save.

---

# 42. App Version

The Config screen should display version and build number from the bundle:

```text
CFBundleShortVersionString
CFBundleVersion
```

Do not hardcode them.

Example:

```text
Version 1.2 (14)
```

---

# 43. App Icon

The app icon asset lives in:

```text
Assets.xcassets
└── AppIcon
```

Current visual direction:

- very minimalist
- black and white
- hand-drawn / slightly wobbly
- top-down lily-pad outline
- simple asymmetrical notch
- no unnecessary illustration detail

The source icon should be a square 1024×1024 image for the main iOS AppIcon slot.

Do not manually round the image corners; the platform applies the icon mask.

---

# 44. Home Screen

Study navigation currently conceptually contains:

```text
Review
Quick Review
Practice Sentences
```

Manage contains:

```text
Decks
Config
```

Home should call:

```swift
CardManager.startReviewIfNeeded()
```

before displaying daily review progress.

If today's queue is complete but more cards are already due, Home should indicate the additional due count rather than incorrectly saying the day is complete.

---

# 45. SwiftData / CloudKit Rules

Until CloudKit is enabled, preserve a sync-friendly schema.

Avoid:

- unique attributes
- required relationships where avoidable
- `.deny` delete rules

Prefer:

- UUID identifiers
- optional relationships
- explicit inverse relationships
- `.cascade` where a true owned child should disappear
- `.nullify` where shared data should survive

---

# 46. Schema Changes During Development

The SwiftData schema is still evolving.

Changes such as adding persisted config fields may require resetting the local development store.

Important:

- deleting DerivedData does not reset SwiftData
- deleting the app from Simulator/device generally resets its local store
- macOS sandbox data may require manual removal

Before production use:

```text
VersionedSchema
SchemaMigrationPlan
```

Do not rely on destructive resets after release.

---

# 47. Cross-Platform Requirements

Pyoko should continue building for:

- iOS
- native macOS

Wrap iOS-only modifiers:

```swift
#if os(iOS)
// iOS-only SwiftUI modifier
#endif
```

Avoid scattering platform checks throughout unrelated code.

Keep platform-specific behaviour small and isolated.

---

# 48. UI / UX Direction

Current interface principles:

- minimal
- card-focused
- stable layout during reveal
- large tap targets
- semantic SwiftUI styling
- dark-mode friendly
- small secondary Hint action
- avoid redundant titles
- avoid duplicate actions
- use accent colour for primary actions
- do not rely on colour alone for meaning

Daily Review, Quick Review, and Sentence Practice should feel visually related even though their behaviour differs.

---

# 49. Testing Priorities

## Card Retrieval

Test:

- due-date eligibility
- selected deck filtering
- tag filtering
- Recognition / Recall
- daily limit
- minimum-new reservation
- due ordering

## Scheduling

Test:

- FSRS state updates
- Again / Hard / Good / Easy
- `.manual` is not exposed as a normal learner control
- interval previews do not mutate stored cards
- extension queue behaviour
- repeated cards only re-enter once genuinely due

## Reading-Only Recognition

Test both Daily and Quick Review:

```text
target → reading
```

including:

- reading exists
- reading is nil and falls back to target
- reading hint is hidden
- Recall remains unaffected

## Quick Review

Test:

- configuration persistence
- Random respects enabled main-review decks
- Selected Decks
- Selected Tags
- Select All tags
- Deselect All tags
- selected-tag count
- `.tags` source cannot start with zero selected tags
- Today's Review
- Today's Review unavailable state
- Recognition only
- Recall only
- both
- Writing Recognition
- Writing Recall
- Writing reading-only Recognition
- Correct / Incorrect counts
- Review Incorrect
- resetting clears temporary results
- no FSRS mutation

## Sentence Practice

Test:

- configuration persistence
- sentence deck/tag selection remains isolated from normal review
- Select All tags
- Deselect All tags
- selected-tag count
- `.tags` source cannot start with zero selected tags
- Random respects enabled main-review decks
- Today's Review validation
- Recognition / Recall deduplication
- density
- Foundation Models availability
- structured generation
- Japanese display modes
- primary + alternative answer reveal
- no FSRS mutation

## Import

Test:

- valid four-column CSV
- missing reading
- missing tags
- default `No Tag`
- malformed row
- duplicate deck
- Recognition only
- Recall only
- both directions
- provenance
- auto-selection of newly imported decks

## UI

Important flows:

- import deck
- download built-in deck
- delete deck
- enable / disable deck
- change Config
- Daily Review tag Select All / Deselect All
- Quick Review tag Select All / Deselect All
- Sentence Practice tag Select All / Deselect All
- Daily Review
- extend completed Daily Review
- Reading Hint
- reading-only Recognition
- Quick Review
- Quick Writing
- retry incorrect cards
- Sentence Practice unavailable/available states
- light mode
- dark mode
- iOS
- macOS

---

# 50. Current Development Status

## Implemented / actively integrated

- SwiftData vocabulary model
- FSRS scheduling
- Recognition / Recall cards
- deck terminology
- CSV import
- URL import
- public Google Sheets import
- generic File Provider import
- deck provenance
- built-in deck architecture
- tag relationships
- deck enable / disable through `PyokoConfig.selectedDecks`
- daily card limit
- Minimum New Cards
- persistent `PyokoConfig`
- target / reading / target+reading display
- reading hints
- reading-only Recognition
- review card preview
- dark / light / system appearance
- stable daily review queue
- FSRS interval preview
- extend completed review session
- Quick Review architecture
- persistent `PyokoQuickConfig`
- Quick Review source selection
- Quick Writing
- Correct / Incorrect tracking
- retry incorrect Quick cards
- persistent `PyokoSentenceConfig`
- sentence vocabulary selection architecture
- Foundation Models sentence generation architecture
- shared `TodayReviewProvider`
- Select All / Deselect All tag controls across config pages
- selected-tag counts in tag selectors
- minimal lily-pad app-icon direction

## Still needing significant work / polish

- production N5 deck data
- production N4 deck data
- idioms deck
- robust deck update/upsert
- comprehensive unit tests
- UI tests
- final accessibility audit
- final dark-mode polish
- production SwiftData migration plan
- CloudKit sync
- private Google Sheets
- optional native Google Drive integration
- Sentence Config `Today's Review` availability guard
- broad sentence-generation reliability testing across supported Apple Intelligence devices

---

# 51. Future Deck Update / Upsert

Imported decks will eventually need safe updates.

Desired behaviour:

- stable source/deck identifier
- content hashing
- detect changed vocabulary
- update changed rows
- insert new rows
- handle removed rows
- preserve FSRS state for logically unchanged vocabulary

Do not implement naive delete-and-reimport if review progress must survive.

---

# 52. Future Native Google Drive Integration

Current Google Drive access is already possible through the system File Provider picker.

A native Drive browser should only be added if Pyoko needs:

- browsing Drive inside the app
- automatically refreshing a known Drive file
- stable provider-specific file identity
- authenticated/private Drive access

That would require a Google Cloud project, OAuth, appropriate Drive scopes, and provider-specific integration code.

---

# 53. Important Invariants

Preserve these unless the product requirement explicitly changes.

## Deck selection

```text
selectedDecks.isEmpty
```

means:

```text
no decks selected
```

## Tags

Tag-empty semantics depend on the configuration.

### Daily Review

```text
selectedTags.isEmpty
```

means:

```text
no tag filter
```

Therefore Daily Review `Deselect All` does not mean "review no cards".

### Quick Review / Sentence Practice

When the explicit vocabulary source is:

```text
Selected Tags
```

an empty `selectedTags` collection means the configuration is incomplete and Start must be disabled.

Bulk tag selection must not change tag selections in any of the other study configs.

## Direction

```text
Recognition = Target → Source
Recall      = Source → Target
```

except when reading-only Recognition is enabled:

```text
Recognition = Target → Reading
```

## Reading fallback

```text
targetReading == nil
```

means:

```text
use targetText
```

for reading presentation.

## Minimum New Cards

It is a minimum reservation, not a maximum.

## Same-day queue

Do not silently regenerate an existing same-day Daily Review queue.

## Review extensions

Do not pull future cards forward merely because the current batch ended.

## FSRS

Only scheduled Daily Review should mutate FSRS.

Quick Review and Sentence Practice must not.

## Quick Review scores

Correct / Incorrect results exist only inside the current in-memory Quick Review session.

## Today's Review

Quick Review and Sentence Practice must not start with `Today's Review` when today's reviewed vocabulary set is empty.

## Sentence generation

Generation and display are separate.

Changing Japanese display mode should not require regenerating a sentence.

---

# 54. Code Style / Maintenance Expectations

Prefer:

- small focused types
- clear names
- direct Swift
- readable formatting
- minimal indirection
- full replacement files for major changes during active development
- production code separate from previews/tests
- comments that explain architectural intent
- current compiler-visible source as the final authority

Avoid:

- duplicated filtering logic
- scheduling logic inside views
- direct database manipulation scattered across UI
- giant views where a focused child type is clearer
- speculative abstractions without a real use case
- broad renames that are not confirmed by the compiler-visible project

---

# 55. Handoff Notes

The project changes quickly during active development.

If this README conflicts with current compiler-visible Swift source:

1. trust the current source
2. preserve existing public APIs where practical
3. adapt new functionality rather than causing unrelated churn
4. verify both sides of SwiftData inverse relationships after model renames
5. remember that schema changes may require a development-store reset

Current terminology:

```text
Deck
Config
Quick Review
Sentence Practice
```

Do not regress to older names such as:

```text
DataSource
PyokoConfiguration
ConfigurationView
```

when the refactor has already been completed.

---

# 56. Recommended Next Work

A sensible current order is:

1. finish compiling and stabilising reading-only Recognition
2. test Daily Review extension behaviour
3. test Quick Review Correct / Incorrect retry flow
4. apply Today's Review availability validation to Sentence Config
5. improve unit coverage for `CardRetrieval` and `CardManager`
6. add Quick Review unit tests
7. add Sentence Practice selection/generation tests
8. validate Foundation Models failures on supported and unsupported devices
9. finalise N5 / N4 / Idioms data
10. implement safe deck update/upsert
11. perform accessibility and dark-mode audit
12. add VersionedSchema / SchemaMigrationPlan before production
13. consider CloudKit only after local schema stabilises

---

# 57.1 Recent Config UI Update

The tag-selection UI now supports bulk selection across the three configuration surfaces:

```text
Daily Review Config
Quick Review Config
Sentence Practice Config
```

Each tag selector should show a selected count and provide:

```text
Select All
Deselect All
```

The actions persist immediately using the existing SwiftData relationships.

No new SwiftData model or schema field is required for this UI change.

Daily Review keeps its special empty-selection behaviour (`no tag filter`), while Quick Review and Sentence Practice require at least one selected tag when `Selected Tags` is the active vocabulary source.

---

# 57. Product Summary

Pyoko now consists of three complementary study loops:

```text
Scheduled Review
    ↓
FSRS decides when vocabulary returns

Quick Review
    ↓
Learner practises any chosen vocabulary
without changing scheduling

Sentence Practice
    ↓
Learner practises vocabulary in generated context
without changing scheduling
```

The product should remain simple on the surface while keeping these behaviours clearly separated internally.

The highest priorities remain:

- reliable FSRS scheduling
- understandable review behaviour
- readable Japanese
- flexible vocabulary selection
- persistent but simple configuration
- safe review progress
- useful offline/on-device study
- maintainable architecture
