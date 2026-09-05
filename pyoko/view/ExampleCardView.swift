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
    
    @State private var cardType:
        ExampleCardType = .recognition
    
    // MARK: - Example Data
    
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
            
            HStack(
                alignment: .top,
                spacing: 12
            ) {
                
                previewStage(
                    title: "Before Answer",
                    content: beforeContent,
                    secondaryContent: nil
                )
                
                Image(
                    systemName: "arrow.right"
                )
                .foregroundStyle(.secondary)
                .padding(.top, 50)
                
                previewStage(
                    title: "After Answer",
                    content: afterPrimaryContent,
                    secondaryContent: afterSecondaryContent
                )
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Before
    
    private var beforeContent: String {
        
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
    
    private var afterPrimaryContent: String {
        
        switch cardType {
            
        case .recognition:
            
            return displayedTarget(
                mode: afterAnswerDisplayMode
            )
            
        case .recall:
            
            return sourceText
        }
    }
    
    private var afterSecondaryContent: String? {
        
        switch cardType {
            
        case .recognition:
            
            return sourceText
            
        case .recall:
            
            return displayedTarget(
                mode: afterAnswerDisplayMode
            )
        }
    }
    
    // MARK: - Display
    
    private func displayedTarget(
        mode: TargetDisplayMode
    ) -> String {
        
        switch mode {
            
        case .target:
            return targetText
            
        case .reading:
            return targetReading
        }
    }
    
    // MARK: - Stage
    
    private func previewStage(
        title: String,
        content: String,
        secondaryContent: String?
    ) -> some View {
        
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(
                spacing: 10
            ) {
                
                Spacer()
                
                Text(content)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                if let secondaryContent {
                    
                    Divider()
                    
                    Text(secondaryContent)
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .frame(
                maxWidth: .infinity,
                minHeight: 140
            )
            .padding()
            .background(
                .secondary.opacity(0.08)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12
                )
            )
        }
        .frame(
            maxWidth: .infinity
        )
    }
}

// MARK: - Example Card Type

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
