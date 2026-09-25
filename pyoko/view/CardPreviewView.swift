import SwiftUI

/// Uses the real card views, with sample data that is never inserted into a store.
struct CardPreviewView: View {
    let quick: Bool
    let recognition: Bool
    let recall: Bool
    let before: TargetDisplayMode
    let after: TargetDisplayMode
    let hiraganaOnly: Bool
    let hint: Bool
    var writing: Bool = false

    @State private var direction: CardType = .recognition
    @State private var revealed = false
    @State private var hintRevealed = false
    @State private var answer = ""

    private var activeDirection: CardType {
        recognition && recall ? direction : (recognition ? .recognition : .recall)
    }

    // Reset the preview when any relevant config or preview direction changes.
    private var signature: String {
        "\(quick)|\(recognition)|\(recall)|\(before.rawValue)|\(after.rawValue)|\(hiraganaOnly)|\(hint)|\(writing)|\(direction.rawValue)"
    }

    var body: some View {
        GroupBox("Card Preview") {
            VStack(spacing: 12) {
                if recognition && recall {
                    Picker("Preview Direction", selection: $direction) {
                        Text("Recognition").tag(CardType.recognition)
                        Text("Recall").tag(CardType.recall)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("preview.direction")
                }
                if quick {
                    QuickCardView(
                        card: PyokoQuickCard(type: activeDirection, sourceText: "to eat", targetText: "食べる", targetReading: "たべる"),
                        beforeAnswerDisplayMode: before, afterAnswerDisplayMode: after,
                        readingHintEnabled: hint, recognitionReadingOnlyEnabled: hiraganaOnly,
                        writingEnabled: writing, submittedAnswer: answer,
                        answerRevealed: revealed, hintRevealed: $hintRevealed,
                        onReveal: { revealed = true }
                    )
                } else {
                    ReviewCardView(
                        card: PyokoCard(type: activeDirection, sourceText: "to eat", targetText: "食べる", targetReading: "たべる", deck: nil),
                        beforeAnswerDisplayMode: before, afterAnswerDisplayMode: after,
                        readingHintEnabled: hint, readingOnlyAnswer: hiraganaOnly,
                        answerRevealed: revealed, hintRevealed: $hintRevealed,
                        onReveal: { revealed = true }
                    )
                }
                if quick && writing && !revealed {
                    TextField("Try writing your answer", text: $answer)
                        .accessibilityIdentifier("preview.answer")
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { revealed = true }
                }
                Button(revealed ? "Reset Preview" : (quick && writing ? "Check Answer" : "Show Answer")) {
                    if revealed { reset() } else { revealed = true }
                }
                .accessibilityIdentifier("preview.action")
                .buttonStyle(.bordered)
                if quick && writing && !revealed {
                    Button("Unsure — Show Answer") {
                        hintRevealed = false
                        revealed = true
                    }
                    .accessibilityIdentifier("preview.unsure")
                    .buttonStyle(.bordered)
                }
                Text("Example only — does not change your progress.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .onChange(of: signature) { _, _ in reset() }
    }

    private func reset() {
        revealed = false
        hintRevealed = false
        answer = ""
    }
}
