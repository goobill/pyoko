import SwiftUI
import SwiftData

struct HomeView: View {
    
    @Environment(\.modelContext)
    private var modelContext
    
    @State
    private var reviewProgress =
        ReviewProgress(
            completed: 0,
            total: 0
        )
    
    var body: some View {
        
        NavigationStack {
            
            ScrollView {
                
                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {
                    
                    header
                    
                    reviewSection
                    
                    navigationSection
                }
                .padding()
                .frame(
                    maxWidth: 760
                )
                .frame(
                    maxWidth: .infinity
                )
            }
            .navigationTitle(
                "Pyoko"
            )
            .onAppear {
                prepareReviewSession()
            }
        }
    }
    
    // MARK: - Header
    
    private var header:
        some View {
        
        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            
            Text(
                "Ready to study?"
            )
            .font(
                .title2
                    .weight(
                        .semibold
                    )
            )
            
            Text(
                "Keep your daily review moving."
            )
            .foregroundStyle(
                .secondary
            )
        }
    }
    
    // MARK: - Review
    
    private var reviewSection:
        some View {
        
        GroupBox {
            
            VStack(
                alignment: .leading,
                spacing: 18
            ) {
                
                HStack {
                    
                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {
                        
                        Text(
                            "Today"
                        )
                        .font(
                            .headline
                        )
                        
                        Text(
                            reviewStatusText
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                    
                    Spacer()
                    
                    Text(
                        reviewProgress
                            .remaining
                            .formatted()
                    )
                    .font(
                        .largeTitle
                            .weight(
                                .semibold
                            )
                    )
                }
                
                NavigationLink {
                    
                    ReviewView()
                    
                } label: {
                    
                    Label(
                        reviewProgress
                            .remaining > 0
                        ? "Start Review"
                        : "Review Complete",
                        systemImage:
                            reviewProgress
                                .remaining > 0
                            ? "play.fill"
                            : "checkmark"
                    )
                    .frame(
                        maxWidth:
                            .infinity
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )
                .disabled(
                    reviewProgress
                        .remaining == 0
                )
            }
            .padding(
                .vertical,
                4
            )
            
        } label: {
            
            Label(
                "Daily Review",
                systemImage:
                    "rectangle.stack"
            )
        }
    }
    
    private var reviewStatusText:
        String {
        
        if reviewProgress.total == 0 {
            return "No cards due"
        }
        
        if reviewProgress.remaining == 0 {
            return "All cards completed"
        }
        
        return "\(reviewProgress.remaining) cards remaining"
    }
    
    // MARK: - Navigation
    
    private var navigationSection:
        some View {
        
        VStack(
            spacing: 12
        ) {
            
            NavigationLink {
                
                DecksView()
                
            } label: {
                
                navigationRow(
                    title: "Decks",
                    subtitle:
                        "Import and manage vocabulary",
                    systemImage:
                        "rectangle.stack.fill"
                )
            }
            .buttonStyle(
                .plain
            )
            
            NavigationLink {
                
                ConfigurationView()
                
            } label: {
                
                navigationRow(
                    title:
                        "Configuration",
                    subtitle:
                        "Review, display and appearance",
                    systemImage:
                        "gearshape.fill"
                )
            }
            .buttonStyle(
                .plain
            )
        }
    }
    
    private func navigationRow(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        
        HStack(
            spacing: 14
        ) {
            
            Image(
                systemName:
                    systemImage
            )
            .font(
                .title2
            )
            .frame(
                width: 36
            )
            
            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                
                Text(title)
                    .fontWeight(
                        .semibold
                    )
                    .foregroundStyle(
                        .primary
                    )
                
                Text(subtitle)
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )
            }
            
            Spacer()
            
            Image(
                systemName:
                    "chevron.right"
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
        }
        .padding()
        .background(
            .regularMaterial,
            in:
                RoundedRectangle(
                    cornerRadius: 16,
                    style:
                        .continuous
                )
        )
        .contentShape(
            Rectangle()
        )
    }
    
    // MARK: - Review Setup
    
    private func prepareReviewSession() {
        
        let manager =
            CardManager(
                modelContext:
                    modelContext
            )
        
        manager
            .startReviewIfNeeded()
        
        reviewProgress =
            manager.getProgress()
    }
}
