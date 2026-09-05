import SwiftUI
import SwiftData

@main
struct PyokoApp: App {
    
    private let modelContainer:
        ModelContainer
    
    init() {
        
        let schema = Schema([
            PyokoCard.self,
            PyokoDataSource.self,
            PyokoTag.self,
            PyokoReviewCard.self,
            PyokoConfiguration.self
        ])
        
        // CloudKit is deliberately disabled
        // for now.
        //
        // When the model and app are ready for
        // syncing, this can later become:
        //
        // .private("iCloud.com.yourcompany.Pyoko")
        
        let configuration =
            ModelConfiguration(
                cloudKitDatabase: .none
            )
        
        do {
            
            modelContainer =
                try ModelContainer(
                    for: schema,
                    configurations:
                        configuration
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
    
    var body: some Scene {
        
        WindowGroup {
            HomeView()
        }
        .modelContainer(
            modelContainer
        )
    }
}
