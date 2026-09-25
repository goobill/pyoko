import SwiftUI

#if os(macOS)
/// A horizontal workspace at desktop widths; compact windows retain readable panel widths.
struct MacConfigWorkspace<Controls: View, Preview: View, Vocabulary: View, Footer: View>: View {
    let controls: Controls
    let preview: Preview
    let vocabulary: Vocabulary
    let footer: Footer

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("Configure your practice").font(.title2.weight(.semibold))
                        Spacer()
                        MacShortcutHelp()
                    }
                    if geometry.size.width >= 860 {
                        HStack(alignment: .top, spacing: 24) {
                            controlsColumn.frame(maxWidth: .infinity)
                            previewColumn.frame(maxWidth: .infinity)
                        }
                        .accessibilityIdentifier("config.columns")
                    } else {
                        controlsColumn
                        previewColumn
                    }
                    vocabulary
                    footer
                }
                .frame(maxWidth: 1240)
                .padding(32)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("config.scroll")
        }
        .font(.system(size: 15))
        .controlSize(.large)
        .groupBoxStyle(MacPanelStyle())
        .buttonStyle(.bordered)
    }

    private var controlsColumn: some View {
        VStack(alignment: .leading, spacing: 20) { controls }
            .accessibilityIdentifier("config.controls")
    }

    private var previewColumn: some View {
        VStack(spacing: 20) { preview }
            .accessibilityIdentifier("config.previews")
    }
}

struct MacPanelStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            configuration.label.font(.headline)
            configuration.content.frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.primary.opacity(0.08)))
    }
}

struct MacCountControl: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var body: some View {
        HStack(spacing: 16) {
            Text(title)
            Spacer(minLength: 20)
            Text("\(value)").monospacedDigit().font(.title3.weight(.semibold)).frame(minWidth: 36)
            Stepper(title, value: $value, in: range).labelsHidden().fixedSize()
        }
        .padding(.vertical, 6)
    }
}
#endif
