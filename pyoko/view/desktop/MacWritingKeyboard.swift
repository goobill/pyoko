#if os(macOS)
import SwiftUI
import AppKit
import Carbon

/// Chooses an enabled input source once when this writing field gains focus.
/// Text changes don't reapply it, so manual keyboard switching and IME composition survive.
struct MacWritingKeyboard: ViewModifier {
    let focused: Bool
    let language: WritingKeyboardLanguage
    @Environment(\.scenePhase) private var scenePhase

    private struct Request: Hashable {
        let focused: Bool
        let language: WritingKeyboardLanguage
        let active: Bool
    }

    func body(content: Content) -> some View {
        content.task(id: Request(focused: focused, language: language, active: scenePhase == .active)) {
            guard focused, scenePhase == .active else { return }
            // SwiftUI establishes the native field editor after updating FocusState.
            await Task.yield()
            guard !Task.isCancelled, NSApp.isActive,
                  let editor = NSApp.keyWindow?.firstResponder as? NSTextView,
                  editor.isFieldEditor, !editor.hasMarkedText(),
                  let context = editor.inputContext else { return }
            let available = context.keyboardInputSources ?? []
            let sources = enabledSources().filter { available.contains($0.id) }
            if let id = WritingInputSource.preferredID(for: language, sources: sources,
                                                       current: context.selectedKeyboardInputSource) {
                context.selectedKeyboardInputSource = id
            }
        }
    }

    @MainActor private func enabledSources() -> [WritingInputSource] {
        let filter = [kTISPropertyInputSourceIsEnabled as String: true,
                      kTISPropertyInputSourceIsSelectCapable as String: true] as CFDictionary
        guard let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }
        return list.compactMap { source in
            guard let id: String = property(source, kTISPropertyInputSourceID) else { return nil }
            return WritingInputSource(id: id,
                languages: property(source, kTISPropertyInputSourceLanguages) ?? [],
                asciiCapable: property(source, kTISPropertyInputSourceIsASCIICapable) ?? false)
        }
    }

    private func property<T>(_ source: TISInputSource, _ key: CFString) -> T? {
        guard let pointer = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(pointer).takeUnretainedValue() as? T
    }
}
#endif
