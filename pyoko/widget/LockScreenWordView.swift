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
                Text(content.japanese).font(.headline).lineLimit(1).minimumScaleFactor(0.7)
                if let reading = content.reading {
                    Text(reading).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
                Text(content.meaning).font(.caption).lineLimit(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
}
