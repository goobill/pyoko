import SwiftUI

#if os(iOS)
import UIKit

/// Uses a preferred enabled keyboard without changing the device's keyboard settings.
struct PhoneWritingField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String
    let language: WritingKeyboardLanguage
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> LanguageTextField {
        let field = LanguageTextField()
        field.borderStyle = .roundedRect
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.returnKeyType = .done
        field.accessibilityIdentifier = "quick.answer"
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return field
    }

    func updateUIView(_ field: LanguageTextField, context: Context) {
        context.coordinator.parent = self
        field.placeholder = placeholder
        if field.language != language {
            field.language = language
            if field.isFirstResponder { field.reloadInputViews() }
        }
        // Never replace an in-progress Japanese composition during a SwiftUI update.
        if field.markedTextRange == nil && field.text != text { field.text = text }
        field.wantsFocus = isFocused
    }

    static func dismantleUIView(_ field: LanguageTextField, coordinator: Coordinator) {
        coordinator.active = false
        field.wantsFocus = false
        field.delegate = nil
        field.resignFirstResponder()
    }

    @MainActor final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PhoneWritingField
        var active = true
        init(_ parent: PhoneWritingField) { self.parent = parent }

        @objc func changed(_ field: UITextField) { parent.text = field.text ?? "" }

        func textFieldShouldReturn(_ field: UITextField) -> Bool {
            guard field.markedTextRange == nil else { return false }
            parent.text = field.text ?? ""
            parent.onSubmit()
            return false
        }

        func textFieldDidBeginEditing(_ field: UITextField) { updateFocus(field, focused: true) }
        func textFieldDidEndEditing(_ field: UITextField) { updateFocus(field, focused: false) }

        private func updateFocus(_ field: UITextField, focused: Bool) {
            DispatchQueue.main.async { [weak self, weak field] in
                guard let self, self.active, let field, field.isFirstResponder == focused else { return }
                self.parent.isFocused = focused
            }
        }
    }
}

class LanguageTextField: UITextField {
    var language: WritingKeyboardLanguage = .english
    var wantsFocus = false {
        didSet { scheduleFocusUpdate() }
    }
    private var focusUpdateScheduled = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // updateUIView can request focus before UIKit attaches the field. Retry
        // on attachment instead of dropping the request until the user taps.
        scheduleFocusUpdate()
    }

    private func scheduleFocusUpdate() {
        guard !focusUpdateScheduled else { return }
        focusUpdateScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.focusUpdateScheduled = false
            guard self.window != nil else { return }
            if self.wantsFocus && !self.isFirstResponder {
                self.becomeFirstResponder()
            } else if !self.wantsFocus && self.isFirstResponder {
                self.resignFirstResponder()
            }
        }
    }

    override var textInputMode: UITextInputMode? {
        let modes = UITextInputMode.activeInputModes
        guard let index = language.preferredIndex(in: modes.map(\.primaryLanguage)) else {
            return super.textInputMode
        }
        return modes[index]
    }
}
#endif
