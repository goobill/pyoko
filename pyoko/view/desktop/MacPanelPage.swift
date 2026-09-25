import SwiftUI

#if os(macOS)
/// Shared desktop margins, readable controls and panel appearance.
struct MacPanelPage<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) { content }
                .frame(maxWidth: 1240)
                .padding(32)
                .frame(maxWidth: .infinity)
        }
        .font(.system(size: 15))
        .controlSize(.large)
        .groupBoxStyle(MacPanelStyle())
    }
}
#endif
