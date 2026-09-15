import SwiftUI

/// Shared controls keep the two config pages in the same order and vocabulary.
struct CardConfigView: View {
    @Binding var recognition: Bool
    @Binding var recall: Bool
    @Binding var before: TargetDisplayMode
    @Binding var after: TargetDisplayMode
    @Binding var hiraganaOnly: Bool
    @Binding var hint: Bool
    var showsHint = true

    var body: some View {
        GroupBox("Direction") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Recognition", isOn: $recognition).accessibilityIdentifier("config.recognition")
                Toggle("Recall", isOn: $recall).accessibilityIdentifier("config.recall")
                Text(hiraganaOnly
                     ? "Recognition: Kanji → Hiragana. Recall: English → Japanese."
                     : "Recognition: Japanese → English. Recall: English → Japanese.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        GroupBox("Card Display") {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Before Answer", selection: $before) { modes }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("config.before")
                Picker("After Answer", selection: $after) { modes }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("config.after")
                Text("Choose how Japanese appears on the card. English stays the same.")
                    .font(.caption).foregroundStyle(.secondary)
                Divider()
                Toggle("Hiragana-only Recognition Answer", isOn: $hiraganaOnly)
                    .accessibilityIdentifier("config.hiraganaOnly")
                    .disabled(!recognition)
                Text("Practise Kanji → Hiragana, such as 食べる → たべる. Applies to recognition cards with Hiragana available; recall stays the same.")
                    .font(.caption).foregroundStyle(.secondary)
                if showsHint {
                    Toggle("Show Hiragana Hint", isOn: $hint)
                        .accessibilityIdentifier("config.hint")
                }
                if showsHint && hiraganaOnly && recognition {
                    Text("Hints are hidden when Hiragana is the answer.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var modes: some View {
        ForEach(TargetDisplayMode.allCases, id: \.rawValue) { mode in
            Text(mode.title).tag(mode)
        }
    }
}
