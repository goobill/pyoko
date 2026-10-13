import SwiftUI

/// Lock-screen text always includes the meaning, regardless of review reveal state/direction.
struct LockScreenWordContent {
    let japanese: String
    let reading: String?
    let meaning: String
    let isEmpty: Bool

    init(word: PyokoWidgetWord?, snapshot: PyokoWidgetSnapshot, date: Date) {
        guard let word, !snapshot.isExpired(at: date) else {
            japanese = "Pyoko"
            reading = nil
            meaning = "Choose words in Widget Config"
            isEmpty = true
            return
        }
        if snapshot.isRandom {
            let text = (snapshot.pair ?? .kanjiEnglish).text(for: word)
            japanese = text.primary
            reading = nil
            meaning = text.secondary ?? ""
            isEmpty = false
            return
        }
        let mode = snapshot.before ?? .target
        japanese = mode == .reading ? word.displayReading : word.target
        reading = mode == .targetAndReading && word.displayReading != word.target
            ? word.displayReading : nil
        meaning = word.source
        isEmpty = false
    }

    var inlineText: String { "\(japanese) · \(meaning)" }
}

struct LockScreenWordView: View {
    let content: LockScreenWordContent
    var inline = false

    var body: some View {
        if inline {
            Text(content.inlineText)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                // The accessory slot is system-sized. Give the word priority within it;
                // standalone Hiragana deliberately uses this same primary style.
                Text(content.japanese)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                if let reading = content.reading {
                    Text(reading)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Text(content.meaning)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(content.reading == nil ? 2 : 1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
}
