import AppIntents
import WidgetKit

struct TapWidgetWordIntent:
    AppIntent {

    static var title:
        LocalizedStringResource =
            "Tap Word"

    static var description =
        IntentDescription(
            "Reveal the current word or move to the next word."
        )

    static var openAppWhenRun =
        false

    func perform()
        async throws
        -> some IntentResult {

        PyokoWidgetStore
            .handleTap()

        WidgetCenter.shared
            .reloadTimelines(
                ofKind:
                    PyokoWidgetConstants
                        .wordWidgetKind
            )

        return .result()
    }
}
