import SwiftUI

/// Renders the same simple card in the widget and Widget Config preview.
struct WidgetWordView: View {
    let word: PyokoWidgetWord
    let direction: PyokoWidgetDirection
    let revealed: Bool
    let snapshot: PyokoWidgetSnapshot

    private var beforeMode: TargetDisplayMode {
        snapshot.before ?? .target
    }

    private var afterMode: TargetDisplayMode {
        snapshot.after ?? .targetAndReading
    }

    private var hasSeparateReading: Bool {
        word.displayReading != word.target
    }

    private var usesHiraganaOnlyAnswer: Bool {
        direction == .recognition
            && snapshot.readingOnlyAnswer
            && hasSeparateReading
    }

    /// Kept internal so the display rules can be covered by unit tests.
    var questionText: String {
        switch direction {
        case .recall:
            return word.source

        case .recognition:
            if usesHiraganaOnlyAnswer {
                return word.target
            }

            switch beforeMode {
            case .target:
                return word.target
            case .reading:
                return word.displayReading
            case .targetAndReading:
                return hasSeparateReading
                    ? "\(word.target)\n\(word.displayReading)"
                    : word.target
            }
        }
    }

    /// Kept internal so the display rules can be covered by unit tests.
    var answerText: String {
        if usesHiraganaOnlyAnswer {
            return word.displayReading
        }

        switch direction {
        case .recognition:
            return word.source
        case .recall:
            return japaneseText(for: afterMode)
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            header

            Spacer(minLength: 4)

            if revealed {
                revealedContent
            } else {
                questionContent
            }

            Spacer(minLength: 4)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .contentTransition(.identity)
        .animation(nil, value: revealed)
        .transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "hand.tap")
                .accessibilityHidden(true)

            Spacer()

            Text(word.displayDeckName)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var questionContent: some View {
        switch direction {
        case .recall:
            primaryText(word.source)

        case .recognition:
            if usesHiraganaOnlyAnswer {
                primaryText(word.target)
            } else {
                japaneseContent(mode: beforeMode, primary: true)
            }
        }
    }

    @ViewBuilder
    private var revealedContent: some View {
        VStack(spacing: 8) {
            switch direction {
            case .recall:
                // English → Kanji → Hiragana.
                primaryText(word.source)
                japaneseContent(mode: afterMode, primary: false)

            case .recognition:
                if usesHiraganaOnlyAnswer {
                    // Hiragana is the answer, so English stays hidden.
                    primaryText(word.target)
                    japanesePrimaryText(word.displayReading, primary: false)
                } else {
                    // Kanji → Hiragana → English.
                    japaneseContent(mode: afterMode, primary: true)
                    answerTextView(word.source)
                }
            }
        }
    }

    @ViewBuilder
    private func japaneseContent(
        mode: TargetDisplayMode,
        primary: Bool
    ) -> some View {
        switch mode {
        case .target:
            japanesePrimaryText(word.target, primary: primary)

        case .reading:
            japanesePrimaryText(word.displayReading, primary: primary)

        case .targetAndReading:
            japanesePrimaryText(word.target, primary: primary)

            if hasSeparateReading {
                readingText(word.displayReading)
            }
        }
    }

    private func primaryText(_ text: String) -> some View {
        Text(text)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .lineLimit(3)
            .minimumScaleFactor(0.5)
    }

    private func japanesePrimaryText(
        _ text: String,
        primary: Bool
    ) -> some View {
        Text(text)
            .font(primary ? .title2 : .title3)
            .fontWeight(primary ? .semibold : .medium)
            .foregroundStyle(.primary)
            .lineLimit(2)
            .minimumScaleFactor(0.5)
    }

    private func readingText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .minimumScaleFactor(0.5)
    }

    private func answerTextView(_ text: String) -> some View {
        Text(text)
            .font(.title3)
            .fontWeight(.medium)
            .lineLimit(3)
            .minimumScaleFactor(0.5)
    }

    private func japaneseText(for mode: TargetDisplayMode) -> String {
        switch mode {
        case .target:
            return word.target
        case .reading:
            return word.displayReading
        case .targetAndReading:
            return hasSeparateReading
                ? "\(word.target)\n\(word.displayReading)"
                : word.target
        }
    }
}
