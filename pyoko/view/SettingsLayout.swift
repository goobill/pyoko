import SwiftUI

struct SettingsLayout<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        #if os(macOS)
        MacPanelPage {
            Text("Settings").font(.largeTitle.bold())
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 360), spacing: 24)], alignment: .leading, spacing: 24) {
                content
            }
        }
        #else
        Form { content }.formStyle(.grouped)
        #endif
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.content = content()
    }
    var body: some View {
        #if os(macOS)
        GroupBox(title) { VStack(alignment: .leading, spacing: 16) { content } }
        #else
        Section(title) { content }
        #endif
    }
}
