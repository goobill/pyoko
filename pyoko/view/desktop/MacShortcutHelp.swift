import SwiftUI

#if os(macOS)
struct MacShortcutHelp: View {
    @State private var showingHelp = false

    var body: some View {
        Button {
            showingHelp.toggle()
        } label: {
Label("Shortcuts", systemImage: "info.circle")
                .padding(.vertical, 6)
        }
        .accessibilityIdentifier("shortcuts.help")
        .popover(isPresented: $showingHelp) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Keyboard shortcuts").font(.title2.bold())
                Text("Scheduled Review").font(.headline)
                shortcut("Space", "Reveal answer / continue an available batch")
                shortcut("1 / 2 / 3 / 4", "Again / Hard / Good / Easy")
                Divider()
                Text("Quick Review").font(.headline)
                shortcut("Space", "Reveal; press again to skip without scoring")
                shortcut("3 / 4", "Incorrect / Correct")
                Divider()
                Text("Writing mode").font(.headline)
                Text("Type normally, including spaces and numbers. Return or Check Answer reveals your attempt. Unsure reveals without typing. Rating keys work after reveal.")
                    .fixedSize(horizontal: false, vertical: true)
                Button("Done") { showingHelp = false }
                    .accessibilityIdentifier("shortcuts.done")
            }
            .padding(28)
            .frame(width: 420)
            .accessibilityIdentifier("shortcuts.content")
        }
    }

    private func shortcut(_ key: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 18) {
            Text(key).font(.system(.body, design: .monospaced)).frame(width: 110, alignment: .leading)
            Text(description).fixedSize(horizontal: false, vertical: true)
        }
    }
}
#endif
