import Foundation
import SwiftUI
import SwiftData

@main
struct pyokoApp: App {

    @AppStorage(
        "appearancePreference"
    )
    private var appearancePreference =
        "system"

    private let modelContainer:
        ModelContainer

    init() {

        let schema =
            Schema(
                [
                    PyokoDeck.self,
                    PyokoTag.self,
                    PyokoCard.self,
                    PyokoReviewCard.self,
                    PyokoConfig.self,
                    PyokoQuickConfig.self
                ]
            )

        let configuration =
            ModelConfiguration(
                "Pyoko",
                schema:
                    schema,
                isStoredInMemoryOnly:
                    false,
                cloudKitDatabase:
                    .private(PyokoCloud.containerIdentifier)
            )

        do {

            modelContainer =
                try ModelContainer(
                    for:
                        schema,
                    configurations: [
                        configuration
                    ]
                )

        } catch {

            fatalError(
                """
                Failed to create Pyoko model container: \(error)
                """
            )
        }
    }

    var body: some Scene {

        WindowGroup {

            HomeView()
                .pyokoTheme()
                .preferredColorScheme(
                    preferredColorScheme
                )
                .pyokoWidgetSync()
        }
        .modelContainer(modelContainer)
        #if os(macOS)
        .defaultSize(width: 1000, height: 760)
        #endif
        #if os(macOS)
        Settings {
            SettingsView().pyokoTheme().preferredColorScheme(preferredColorScheme)
        }
        #endif
    }

    private var preferredColorScheme:
        ColorScheme? {

        switch appearancePreference {

        case "light":
            return .light

        case "dark":
            return .dark

        default:
            return nil
        }
    }
}
