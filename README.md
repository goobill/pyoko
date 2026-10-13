# Pyoko

Pyoko is an app for learning Japanese on iPhone, iPad and Mac. Practise vocabulary with English meanings, Kanji and Hiragana through scheduled reviews, quick practice and widgets.

## Spaced repetition

Review uses **FSRS**, a spaced-repetition scheduler, to decide when to show each card again. Reveal the answer, then choose **Again**, **Hard**, **Good** or **Easy** based on how well you remembered it. Difficult cards return sooner; words you remember confidently are spaced further apart.

**Recognition** practises Japanese → English. **Recall** practises English → Japanese. Each direction has its own review progress. Review Config lets you choose daily limits, decks, tags, hints and how Kanji and Hiragana appear.

**Quick Review** is extra practice without changing your spaced-repetition schedule. Choose vocabulary, practise with flashcards or written answers, and retry mistakes. You can also practise random words you have reviewed before.

## Decks

Two decks are included and can be installed without downloading anything:

- **JLPT N5:** beginner vocabulary—a good place to start.
- **JLPT N4:** elementary vocabulary to build on N5 study.

Open **Manage → Decks** to install them. Enable the decks you want to study, then use Review or Quick Review. Tags help you focus on a smaller set of words. Disabling a deck preserves its cards and progress; deleting it removes them.

Use **Get more decks** to visit [pyoko.goobill.com](https://pyoko.goobill.com). Import a downloaded CSV, a direct CSV link, or a publicly readable Google Sheet through **Import Deck**.

Custom CSVs use these four columns. English and Japanese spelling are required; Hiragana and tags are optional. Separate multiple tags with `|`.

```csv
source,target,reading,tags
to eat,食べる,たべる,Food|Verb
library,図書館,としょかん,Places
```

## Widgets

Open **Widget → Config** to choose enabled decks, tags, all enabled vocabulary, or words you reviewed today. Widget settings are separate from your study sessions and include a preview and theme options.

- **Home Screen and Mac—Review mode:** tap to reveal the answer, then tap again for another word. Choose recognition or recall and your Kanji/Hiragana display preferences.
- **Home Screen and Mac—Random mode:** show a word pair immediately: Kanji + English, Hiragana + English, or Kanji + Hiragana. Tap for another word.
- **iPhone Lock Screen:** rectangular and inline widgets show Japanese and English in Review mode, or your selected pair in Random mode, without needing to reveal an answer.

Random widgets rotate when the system refreshes them. Apple controls refresh timing, so a new word on every viewing is not guaranteed. Widget interactions do not change your review schedule.

Add **Pyoko → Word Review** from your device's widget picker. Open the app first to make your selected vocabulary available.

## Sync and appearance

Decks, cards, review progress and study configuration sync through your iCloud account. You can study offline; changes sync when a connection is available. Themes, widget preferences and the current Quick Review session stay on each device. Settings includes light/dark appearance, colour themes and tint choices.

## Building

Open `pyoko.xcodeproj` in Xcode and configure your developer team, iCloud container and App Group for the app and widget targets. Run on your iPhone or Mac. Unit and UI tests are included; run them in Xcode before releasing changes. UI tests require `PYOKO_ALLOW_UI_TESTS=1` in the test runner and a disposable device/account because they modify real app data.
