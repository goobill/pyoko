# Pyoko

## 1. Introduction

Pyoko is a language-learning app built around spaced repetition and contextual sentence practice.

The app helps learners:

- import or install vocabulary decks
- review vocabulary using spaced repetition
- study in both Recognition and Recall directions
- filter study sessions by deck and tag
- control how target-language text and readings are displayed
- receive reading hints while reviewing
- practise vocabulary inside generated sentences
- retain their preferred study settings between sessions

Pyoko began as a Japanese-learning app, but the core product should remain generic enough to support other language pairs in the future.

The current reference implementation is native Apple, but this document describes the product and system at a high level so the app could be recreated using another platform or technology stack if needed.

---

# 2. Product Goals

Pyoko should be:

- simple to use
- focused on daily study rather than configuration overhead
- flexible enough for different vocabulary sources
- useful for both recognition and recall
- transparent about review scheduling
- able to grow from flashcards into contextual sentence practice
- usable offline where practical
- designed so user data and review progress can later sync across devices

The product should avoid becoming a complicated study-management tool.

The main experience is:

```text
Import vocabulary
        ↓
Choose what to study
        ↓
Review due cards
        ↓
Schedule next review
        ↓
Practise vocabulary in context
```

---

# 3. Main User Types

## Learner

The primary user.

A learner can:

- install built-in vocabulary decks
- import their own vocabulary
- configure review preferences
- complete daily flashcard reviews
- use reading hints
- practise generated sentences
- control how Japanese text is displayed
- resume later with the same saved settings

## Maintainer / Content Manager

A maintainer can:

- add or update built-in decks
- manage supported import formats
- add new sentence-generation features
- improve review logic
- introduce new language support
- add syncing and migrations
- maintain test coverage

---

# 4. Use Case Overview

```text
                         ┌────────────────────┐
                         │      Learner       │
                         └─────────┬──────────┘
                                   │
          ┌────────────────────────┼─────────────────────────┐
          │                        │                         │
          ▼                        ▼                         ▼
 ┌─────────────────┐      ┌──────────────────┐      ┌──────────────────┐
 │ Manage Decks    │      │ Review Vocabulary│      │ Practice Sentences│
 └────────┬────────┘      └─────────┬────────┘      └─────────┬────────┘
          │                         │                         │
  ┌───────┼────────┐        ┌───────┼────────┐        ┌───────┼──────────┐
  │       │        │        │       │        │        │       │          │
  ▼       ▼        ▼        ▼       ▼        ▼        ▼       ▼          ▼
Install Import   Delete   Hint   Reveal   Rate     Select  Configure   Review
built-   custom   deck    reading answer  recall   vocab   sentence    generated
in deck  deck                              quality  source  style       sentences
```

---

# 5. Core Features and Requirements

## 5.1 Deck Management

The user must be able to:

- view installed decks
- install built-in decks
- import custom decks
- delete decks
- reinstall built-in decks after deletion
- see where a deck came from
- see high-level deck statistics

Supported deck origins currently include:

- built-in
- local/system file
- direct URL
- Google Sheets

Future origins may include:

- native Google Drive integration
- native iCloud integration

The user-facing term is always **Deck**.

---

## 5.2 Vocabulary Import

Pyoko accepts a simple four-column vocabulary structure:

```text
source
target
reading
tags
```

Requirements:

- source is required
- target is required
- reading is optional
- tags are optional
- multiple tags may be attached to one vocabulary item
- missing tags fall back to a default tag
- the same vocabulary may produce both Recognition and Recall cards

The first row of imported tabular data is treated as a header.

The importer should reject malformed rows rather than silently importing corrupted data.

---

## 5.3 Recognition and Recall

Every vocabulary item may generate two study directions.

### Recognition

The learner sees the target language and recalls the source meaning.

Example:

```text
食べる
↓
to eat
```

### Recall

The learner sees the source meaning and recalls the target language.

Example:

```text
to eat
↓
食べる
```

The user may enable:

- Recognition only
- Recall only
- both

At least one direction must remain enabled.

---

## 5.4 Daily Review

The app creates a daily review session from eligible cards.

Eligibility is based on:

- due date
- selected decks
- selected tags
- Recognition / Recall settings
- daily card limit
- minimum-new-card setting

The daily session should remain stable once created.

Changing settings during the day should normally affect the next generated session, rather than silently changing the current one.

---

## 5.5 Daily Card Limit

The learner can configure the maximum number of cards in a daily session.

The system must never exceed this limit.

---

## 5.6 Minimum New Cards

The learner can reserve a minimum number of places in each daily session for new cards.

Requirements:

- default is zero
- zero means no new cards are guaranteed
- it is a minimum, not a maximum
- reviews can fill unused capacity
- new cards can fill unused review capacity
- the daily card limit is never exceeded

---

## 5.7 Spaced Repetition Scheduling

Pyoko uses an FSRS-style spaced-repetition scheduler.

Each reviewed card stores scheduling state such as:

- next due date
- difficulty
- stability
- review count
- lapse count
- previous review time

When the learner rates a card, the scheduler determines when that card should next be shown.

The user chooses between four outcomes:

- Again
- Hard
- Good
- Easy

The current review UI presents the resulting next-review interval rather than relying only on the labels.

Example:

```text
Harder                         Easier

  1m        5m        10m        16d
```

The visual mapping still corresponds internally to:

```text
Again → Hard → Good → Easy
```

---

## 5.8 Review Interval Preview

Before the learner selects a rating, the app previews when the card would next be due for each option.

Requirements:

- previews use the real scheduler
- previews must not alter the card
- previews must be based on the same current time
- intervals should be shown in compact human-readable form

Examples:

```text
1m
15m
4h
2d
3mo
1y
```

---

## 5.9 Review Screen

The review screen should be minimal and focused.

### Top area

Contains:

- back button
- progress bar
- current progress count

A large redundant page title is not required.

Example:

```text
[Back]   [──────── progress ────────]   14/20
```

### Review card

The card should:

- stay the same size before and after reveal
- support tapping the whole card to reveal
- show whether it is Recognition or Recall
- place Hint in the top-right
- make the primary vocabulary visually prominent
- scale long text to fit

### Show Answer

Before reveal:

- show only floating `Show Answer` text
- use the app accent colour
- do not use a pill or button background
- make the entire area below the card tappable

### After reveal

The same reserved area becomes the review-rating area.

The card must not jump or resize when this happens.

---

## 5.10 Reading Hint

If a vocabulary item includes a reading, the learner can request a hint.

Requirements:

- configurable on/off
- only shown when a reading exists
- shown in the top-right of the card
- uses a lightbulb icon
- does not reveal the full answer
- displays the reading as a clue
- hidden after the full answer is revealed
- hidden when the current front already shows the reading

For Recall cards, the reading hint acts as a deliberate clue.

---

## 5.11 Target Display Modes

The learner can choose how target-language content appears.

Supported modes:

- Target
- Reading
- Target + Reading

The learner chooses this independently for:

- before the answer is revealed
- after the answer is revealed

If no reading exists, Reading falls back to Target.

For Japanese, Target + Reading should normally be displayed as two stacked lines.

---

## 5.12 Deck Filtering

The learner can choose which decks contribute cards to review sessions.

Important rule:

```text
No selected decks = review no decks
```

Newly imported decks should automatically become selected in the current review configuration.

Previously deselected decks should remain deselected.

---

## 5.13 Tag Filtering

The learner can filter review cards by tag.

Important rule:

```text
No selected tags = no tag filter
```

This is different from deck selection.

---

## 5.14 Appearance

The app supports:

- System
- Light
- Dark

The visual design should use semantic colours and adapt naturally to the selected appearance.

The app version and build number should be visible at the bottom of Settings.

---

# 6. Data Model

The data model is designed around vocabulary, scheduling, and saved user preferences.

```text
┌─────────────────────┐
│        Deck         │
│─────────────────────│
│ identity            │
│ name                │
│ origin              │
│ import metadata     │
│ counts              │
└──────────┬──────────┘
           │ 1
           │
           │ many
           ▼
┌─────────────────────┐
│        Card         │
│─────────────────────│
│ identity            │
│ Recognition/Recall  │
│ source text         │
│ target text         │
│ reading             │
│ FSRS state          │
└───────┬─────┬───────┘
        │     │
        │     │ many-to-many
        │     ▼
        │ ┌───────────────────┐
        │ │       Tag         │
        │ │───────────────────│
        │ │ identity          │
        │ │ name              │
        │ └───────────────────┘
        │
        │ one-to-many
        ▼
┌─────────────────────┐
│   Review Queue Item │
│─────────────────────│
│ review date         │
│ reviewed flag       │
│ card reference      │
└─────────────────────┘
```

---

# 7. Configuration Data

Review preferences are stored separately from vocabulary.

```text
┌────────────────────────────┐
│    Review Configuration    │
│────────────────────────────│
│ daily card limit           │
│ minimum new cards          │
│ Recognition enabled        │
│ Recall enabled             │
│ reading hint enabled       │
│ before-answer display      │
│ after-answer display       │
│ selected decks             │
│ selected tags              │
└────────────────────────────┘
```

These preferences persist between app launches.

Appearance is also persistent, but is conceptually a device/UI preference rather than study data.

---

# 8. Data Lineage / DAG

The main vocabulary and review lineage is:

```text
External Vocabulary Source
        │
        │
        ├── Built-in deck
        ├── File
        ├── URL
        └── Google Sheet
        │
        ▼
Import / Validation
        │
        ▼
Deck
        │
        ▼
Vocabulary Records
        │
        ├───────────────┐
        │               │
        ▼               ▼
Recognition Card    Recall Card
        │               │
        └───────┬───────┘
                │
                ▼
          Tags + Deck
             Filters
                │
                ▼
         Eligible Due Cards
                │
                ▼
        Daily Review Queue
                │
                ▼
           User Rating
                │
                ▼
           FSRS Scheduler
                │
                ▼
        Updated Card State
                │
                └──────────────► future due review
```

---

# 9. Import Data Lineage

```text
Vocabulary Source
      │
      ▼
Raw CSV-like Data
      │
      ▼
Row Validation
      │
      ▼
Normalised Vocabulary
      │
      ├── Source
      ├── Target
      ├── Reading
      └── Tags
      │
      ▼
Deck Creation
      │
      ├── Recognition cards
      └── Recall cards
      │
      ▼
Persisted Study Data
```

Import source metadata should remain attached to the deck so the user can understand where their data came from.

---

# 10. Review Data Flow

```text
Saved Review Configuration
          │
          ▼
Eligible Card Selection
          │
          ├── due date
          ├── deck filter
          ├── tag filter
          ├── Recognition/Recall filter
          └── new-card reservation
          │
          ▼
Daily Review Queue
          │
          ▼
Review Card
          │
          ├── optional Hint
          ├── reveal Answer
          └── choose Difficulty
          │
          ▼
FSRS Scheduling
          │
          ▼
Updated Due Date + Scheduling State
```

---

# 11. Sentence Practice

Sentence Practice is the next major product area.

The purpose is to move from isolated vocabulary recall into contextual language use.

The learner opens Sentence Practice, configures the session, then practises generated bilingual sentences.

The chosen configuration should be saved and restored automatically the next time the learner opens the feature.

---

# 12. Sentence Practice Use Cases

The learner can choose:

## Vocabulary source

- Random Vocabulary
- Selected Decks
- Selected Tags
- Today's Review

## Vocabulary per sentence

- Focused — 1 word
- Normal — 2–3 words
- Challenging — 4–5 words

## Complexity

- Simple
- Beginner
- Intermediate
- Advanced

## Sentence types

The learner can enable multiple types:

- Present
- Past
- Future
- Connecting
- Longer Sentences

## Japanese display

- Kanji
- Hiragana
- Kanji + Hiragana

## Practice direction

- Recognition
- Recall
- both

## Session size

The learner selects how many sentences to practise.

---

# 13. Sentence Practice Flow

```text
Saved Sentence Configuration
           │
           ▼
Choose Vocabulary Source
           │
           ▼
Select Eligible Vocabulary
           │
           ▼
Remove Recognition/Recall Duplicates
           │
           ▼
Group 1–5 Vocabulary Items
           │
           ▼
Generate Sentence
           │
           ├── English
           ├── Japanese
           ├── Hiragana
           └── alternative valid answers
           │
           ▼
Recognition / Recall Practice
           │
           ▼
Learner Answer
           │
           ▼
Local Answer Matching
           │
       clear match?
        │      │
       yes     no
        │      │
        │      ▼
        │   AI Evaluation
        │      │
        └──────┤
               ▼
          Learner Feedback
```

---

# 14. Sentence Generation Requirements

The generator should:

- use a small selected vocabulary set for each sentence
- create natural sentences rather than forcing too many words together
- respect the requested difficulty
- respect enabled sentence styles
- return both Japanese and Hiragana
- return an English equivalent
- return multiple acceptable answers where useful
- avoid exposing raw model controls to the learner

The generation layer should be replaceable.

The current intended implementation uses the device's built-in language model where available.

---

# 15. Sentence Answer Evaluation

Sentence translation is not one-to-one.

The system must not assume only one exact string is valid.

Evaluation should therefore use two stages:

## Local matching

Handle obvious equivalence such as:

- whitespace differences
- punctuation differences
- exact matches to known alternative answers

## AI evaluation

If a local match is not conclusive, the model can assess:

- meaning
- grammar
- vocabulary usage

Suggested feedback outcomes:

- Correct
- Mostly Correct
- Incorrect

AI grading should be presented as helpful feedback, not as an infallible exam result.

---

# 16. Japanese Display and Grading

Japanese Display controls presentation only.

For example, if the learner chooses Kanji, the system may still accept a correct Hiragana or mixed Kanji/Kana answer.

The learner should be judged on:

- meaning
- grammar
- appropriate vocabulary

not on matching one exact script representation.

---

# 17. Persistence Requirements

The app should persist:

- decks
- vocabulary cards
- tags
- FSRS scheduling state
- daily review queue state
- review configuration
- sentence-practice configuration
- appearance preference

Generated sentence sessions do not need to be stored initially.

They may become persistent later if features such as history, statistics, or favourites are added.

---

# 18. Data Integrity Requirements

The system should preserve these rules:

- deck deletion removes its cards
- deck deletion does not remove shared tags
- deleting a review-queue item does not delete the vocabulary card
- new imports do not reset unrelated user preferences
- newly imported decks are selected automatically
- a stable same-day review queue is not silently regenerated
- scheduler previews never mutate card state
- user review progress should be preserved whenever possible

---

# 19. Non-Functional Requirements

## Reliability

Study progress and scheduling data must be treated as important user data.

## Maintainability

Major responsibilities should remain separated:

```text
Import
Review Selection
Review Scheduling
UI
Sentence Generation
Sentence Evaluation
Persistence
```

## Offline behaviour

Flashcard review should not depend on an internet connection.

Sentence generation should preferably run on-device where supported.

## Accessibility

The interface should not rely only on:

- colour
- iconography
- visual position

Interactive controls should remain understandable to accessibility tools.

## Cross-platform architecture

The product model should not depend on one UI framework.

A future web, Android, or cross-platform implementation should be able to reproduce the same:

- data model
- review rules
- scheduling flow
- sentence-practice behaviour

---

# 20. Current Product Scope

The existing / near-complete product includes:

- deck management
- CSV-style vocabulary import
- file import
- URL import
- public Google Sheets import
- built-in deck support
- deck provenance
- Recognition and Recall cards
- tags
- deck and tag filters
- daily review limit
- minimum-new-card setting
- persistent review configuration
- reading hints
- configurable Target / Reading display
- stable daily review queue
- FSRS scheduling
- FSRS next-review previews
- redesigned card-focused review UI
- dark/light/system appearance
- app version display

---

# 21. Future Development

## Priority 1 — Stabilise the Existing Review Experience

- finish review-screen visual polish
- verify behaviour on different screen sizes
- improve accessibility
- verify dark/light appearance
- add automated tests for card selection and scheduling

## Priority 2 — Built-In Content

- complete JLPT N5 dataset
- complete JLPT N4 dataset
- add idioms deck
- create a reliable content-release/update process

## Priority 3 — Safe Deck Updates

Create a proper update/upsert system that can:

- identify existing vocabulary
- detect changed rows
- add new vocabulary
- handle removed vocabulary
- preserve review progress for unchanged cards

Avoid delete-and-reimport where it would erase scheduling history.

## Priority 4 — Sentence Practice

Implement:

- persistent sentence configuration
- vocabulary selection
- vocabulary density
- sentence generation
- Recognition and Recall sentence practice
- Kanji / Hiragana / Both display
- multiple valid answers
- local answer matching
- AI feedback

## Priority 5 — Testing

Add:

- unit tests for review-card retrieval
- unit tests for scheduling
- importer validation tests
- configuration tests
- sentence-generation tests
- sentence-evaluation tests
- end-to-end UI tests

## Priority 6 — Sync and Migration

Before production-scale syncing:

- introduce explicit database schema versions
- create migration plans
- test data upgrades
- enable cloud sync only after local data stability is proven

## Priority 7 — Additional Integrations

Possible later additions:

- private Google Sheets
- native Google Drive browsing
- direct cloud-source updates
- multi-device sync
- sentence history
- study statistics
- weak-vocabulary / weak-grammar targeting

---

# 22. Product Principles for Future Development

When adding features, preserve the following principles:

1. Keep daily study simple.
2. Avoid exposing technical complexity to learners.
3. Protect review progress.
4. Prefer stable, understandable behaviour over hidden automation.
5. Keep vocabulary storage independent from presentation.
6. Keep review scheduling independent from UI.
7. Keep sentence generation replaceable.
8. Let the learner control what they study.
9. Reuse imported vocabulary rather than duplicating it.
10. Build features that can work beyond Japanese when practical.

---

# 23. Handoff Summary

A new maintainer should think of Pyoko as three connected systems:

```text
1. Vocabulary Library
   Decks + Vocabulary + Tags

2. Spaced Repetition
   Configuration + Daily Queue + FSRS Scheduling

3. Contextual Practice
   Vocabulary Selection + Sentence Generation + Answer Evaluation
```

These systems share data but should remain architecturally separate.

The product should be reproducible from this document even if the implementation technology changes.

The essential behaviour to preserve is:

```text
Vocabulary enters the system
        ↓
is organised into decks and tags
        ↓
becomes Recognition and Recall cards
        ↓
is selected into daily review sessions
        ↓
is scheduled by spaced repetition
        ↓
is reused in contextual sentence practice
```

That is the core of Pyoko.
