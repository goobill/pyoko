//
//  ExampleCardView.swift
//  pyoko
//
//  Created by Bill on 05/09/2026.
//

import SwiftUI

struct ExampleCardView: View {
    
    let beforeAnswerDisplayMode: TargetDisplayMode
    let afterAnswerDisplayMode: TargetDisplayMode
    
    @State private var cardType: ExampleCardType = .recognition
    
    private let sourceText = "to eat"
    private let targetText = "食べる"
    private let targetReading = "たべる"
    
    var body: some View {
        
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            
            Picker(
                "Example Card Type",
                selection: $cardType
            ) {
                
                ForEach(
                    ExampleCardType.allCases
                ) { type in
                    
                    Text(type.title)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            previewStage(
                title: "Before Answer",
                primaryText: beforePrimaryText,
                secondaryText: nil
            )
            
            HStack {
                
                Spacer()
                
                Image(
                    systemName: "arrow.down"
                )
                .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            previewStage(
                title: "After Answer",
                primaryText: afterPrimaryText,
                secondaryText: afterSecondaryText
            )
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Before
    
    private var beforePrimaryText: String {
        
        switch cardType {
            
        case .recognition:
            
            return displayedTarget(
                mode: beforeAnswerDisplayMode
            )
            
        case .recall:
            
            return sourceText
        }
    }
    
    // MARK: - After
    
    private var afterPrimaryText: String {
        
        switch cardType {
            
        case .recognition:
            
            return displayedTarget(
                mode: afterAnswerDisplayMode
            )
            
        case .recall:
            
            return sourceText
        }
    }
    
    private var afterSecondaryText: String? {
        
        switch cardType {
            
        case .recognition:
            
            return sourceText
            
        case .recall:
            
            return displayedTarget(
                mode: afterAnswerDisplayMode
            )
        }
    }
    
    // MARK: - Target Display
    
    private func displayedTarget(
        mode: TargetDisplayMode
    ) -> String {
        
        switch mode {
            
        case .target:
            
            return targetText
            
        case .reading:
            
            return targetReading
            
        case .targetAndReading:
            
            return """
            \(targetText)
            \(targetReading)
            """
        }
    }
    
    // MARK: - Preview Stage
    
    private func previewStage(
        title: String,
        primaryText: String,
        secondaryText: String?
    ) -> some View {
        
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(
                spacing: 12
            ) {
                
                Text(primaryText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                if let secondaryText {
                    
                    Divider()
                    
                    Text(secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .frame(
                minHeight: 110
            )
            .background(
                Color.secondary.opacity(0.08)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12
                )
            )
        }
    }
}

private enum ExampleCardType:
    String,
    CaseIterable,
    Identifiable {
    
    case recognition
    case recall
    
    var id: Self {
        self
    }
    
    var title: String {
        
        switch self {
            
        case .recognition:
            return "Recognition"
            
        case .recall:
            return "Recall"
        }
    }
}
