import SwiftUI
import SwiftData

struct HomeView: View {
    
    @Environment(\.modelContext)
    private var modelContext
    
    @Query(
        sort: \PyokoDataSource.name
    )
    private var sources: [PyokoDataSource]
    
    @Query
    private var reviewCards: [PyokoReviewCard]
    
    var body: some View {
        
        NavigationStack {
            
            List {
                
                studySection
                
                dataSection
                
                settingsSection
            }
            .navigationTitle("Pyoko")
            .onAppear {
                prepareReviewQueue()
            }
        }
    }
    
    // MARK: - Study
    
    private var studySection: some View {
        
        Section("Study") {
            
            NavigationLink {
                
                ReviewView()
                
            } label: {
                
                Label {
                    
                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {
                        
                        Text("Start Review")
                        
                        Text(reviewSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                } icon: {
                    
                    Image(
                        systemName: "rectangle.stack"
                    )
                }
            }
        }
    }
    
    // MARK: - Data
    
    private var dataSection: some View {
        
        Section("Data") {
            
            NavigationLink {
                
                SourceDataView()
                
            } label: {
                
                Label {
                    
                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {
                        
                        Text("Source Data")
                        
                        Text(sourceSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                } icon: {
                    
                    Image(
                        systemName: "tray.full"
                    )
                }
            }
        }
    }
    
    // MARK: - Settings
    
    private var settingsSection: some View {
        
        Section("Settings") {
            
            NavigationLink {
                
                ConfigurationView()
                
            } label: {
                
                Label(
                    "Configuration",
                    systemImage: "slider.horizontal.3"
                )
            }
        }
    }
    
    // MARK: - Prepare Review
    
    private func prepareReviewQueue() {
        
        let manager = CardManager(
            modelContext: modelContext
        )
        
        manager.startReviewIfNeeded()
    }
    
    // MARK: - Review Summary
    
    private var remainingReviewCount: Int {
        
        reviewCards.filter {
            !$0.reviewed &&
            $0.card != nil
        }
        .count
    }
    
    private var totalReviewCount: Int {
        
        reviewCards.filter {
            $0.card != nil
        }
        .count
    }
    
    private var reviewSummary: String {
        
        if totalReviewCount == 0 {
            return "No cards due"
        }
        
        if remainingReviewCount == 0 {
            return "Today's review is complete"
        }
        
        if remainingReviewCount == 1 {
            return "1 card remaining"
        }
        
        return "\(remainingReviewCount) cards remaining"
    }
    
    // MARK: - Source Summary
    
    private var sourceSummary: String {
        
        let sourceCount = sources.count
        
        let vocabularyCount = sources.reduce(0) {
            $0 + $1.vocabularyCount
        }
        
        switch sourceCount {
            
        case 0:
            return "No data sources installed"
            
        case 1:
            return "1 source • \(vocabularyCount.formatted()) vocabulary"
            
        default:
            return "\(sourceCount) sources • \(vocabularyCount.formatted()) vocabulary"
        }
    }
}
