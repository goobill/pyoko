import SwiftUI
import SwiftData

@main
struct pyokoApp: App {

    @AppStorage(
        "appearancePreference"
    )
    private var appearanceRawValue =
        AppearancePreference
            .system
            .rawValue

    private let modelContainer:
        ModelContainer

    init() {

        let schema =
            Schema(
                [
                    PyokoCard.self,
                    PyokoConfiguration.self,
                    PyokoDeck.self,
                    PyokoReviewCard.self,
                    PyokoTag.self,
                    PyokoSentenceConfiguration.self
                ]
            )

        let modelConfiguration =
            ModelConfiguration(
                "Pyoko",
                schema:
                    schema,
                isStoredInMemoryOnly:
                    false,
                cloudKitDatabase:
                    .none
            )

        do {

            modelContainer =
                try ModelContainer(
                    for:
                        schema,
                    configurations:
                        [
                            modelConfiguration
                        ]
                )

        } catch {

            fatalError(
                """
                Failed to create Pyoko ModelContainer:

                \(error)
                """
            )
        }
    }

    var body: some Scene {

        WindowGroup {

            HomeView()
                .preferredColorScheme(
                    preferredColorScheme
                )
        }
        .modelContainer(
            modelContainer
        )
    }

    private var preferredColorScheme:
        ColorScheme? {

        let preference =
            AppearancePreference(
                rawValue:
                    appearanceRawValue
            )
            ?? AppearancePreference
                .system

        switch preference {

        case .system:
            return nil

        case .light:
            return .light

        case .dark:
            return .dark
        }
    }
}
