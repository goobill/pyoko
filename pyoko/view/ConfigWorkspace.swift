import SwiftUI

/// Screens supply their existing bindings and controls. Layout is platform-owned.
struct ConfigWorkspace<Controls: View, Preview: View, Vocabulary: View, Footer: View>: View {
    let controls: Controls
    let preview: Preview
    let vocabulary: Vocabulary
    let footer: Footer

    init(@ViewBuilder controls: () -> Controls, @ViewBuilder preview: () -> Preview,
         @ViewBuilder vocabulary: () -> Vocabulary, @ViewBuilder footer: () -> Footer) {
        self.controls = controls(); self.preview = preview()
        self.vocabulary = vocabulary(); self.footer = footer()
    }

    var body: some View {
        #if os(macOS)
        MacConfigWorkspace(controls: controls, preview: preview, vocabulary: vocabulary, footer: footer)
        #else
        ScrollView {
            VStack(spacing: 18) {
                controls
                preview
                vocabulary
                footer
            }
            .pyokoPageContent()
        }.accessibilityIdentifier("config.scroll")
        #endif
    }
}
