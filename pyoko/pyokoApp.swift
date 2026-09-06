import SwiftUI
import SwiftData

@main
struct PyokoApp: App {
    
    @AppStorage("appearancePreference")
    private var appearancePreferenceRawValue =
        AppearancePreference.system.rawValue
    
    private let modelContainer: ModelContainer
    
    init() {
        
        let schema = Schema([
            PyokoCard.self,
            PyokoDeck.self,
            PyokoTag.self,
            PyokoReviewCard.self,
            PyokoConfiguration.self
        ])
        
        let configuration = ModelConfiguration(
            "Pyoko",
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: configuration
            )
        } catch {
            fatalError(
                """
                Failed to create Pyoko model container:
                \(error)
                """
            )
        }
    }
    
    private var appearancePreference:
        AppearancePreference {
        
        AppearancePreference(
            rawValue:
                appearancePreferenceRawValue
        ) ?? AppearancePreference.system
    }
    
    var body: some Scene {
        
        WindowGroup {
            
            HomeView()
                .preferredColorScheme(
                    appearancePreference.colorScheme
                )
        }
        .modelContainer(
            modelContainer
        )
    }
}
