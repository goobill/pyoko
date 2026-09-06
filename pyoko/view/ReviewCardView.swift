//
//  ReviewCardView.swift
//  pyoko
//
//  Created by Bill on 06/09/2026.
//

import SwiftUI

struct ReviewCardView: View {
    
    let card:
        PyokoCard
    
    let isAnswerVisible:
        Bool
    
    let beforeAnswerDisplayMode:
        TargetDisplayMode
    
    let afterAnswerDisplayMode:
        TargetDisplayMode
    
    let readingHintEnabled:
        Bool
    
    let isReadingHintVisible:
        Bool
    
    let onReveal:
        () -> Void
    
    let onShowReadingHint:
        () -> Void
    
    var body: some View {
        
        VStack(
            spacing: 14
        ) {
            
            cardSurface
            
            if shouldShowHintButton {
                
                Button {
                    onShowReadingHint()
                } label: {
                    
                    Label(
                        "Show Reading",
                        systemImage:
                            "lightbulb"
                    )
                }
                .buttonStyle(
                    .bordered
                )
            }
        }
    }
    
    // MARK: - Surface
    
    private var cardSurface:
        some View {
        
        VStack(
            spacing: 24
        ) {
            
            cardTypeHeader
            
            Spacer(
                minLength: 10
            )
            
            cardContent
            
            Spacer(
                minLength: 10
            )
            
            if !isAnswerVisible {
                
                Label(
                    "Tap anywhere to reveal",
                    systemImage:
                        "hand.tap"
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .padding(28)
        .frame(
            maxWidth: .infinity,
            minHeight: 330
        )
        .contentShape(
            Rectangle()
        )
        .background(
            .regularMaterial,
            in:
                RoundedRectangle(
                    cornerRadius: 24,
                    style:
                        .continuous
                )
        )
        .overlay {
            
            RoundedRectangle(
                cornerRadius: 24,
                style:
                    .continuous
            )
            .stroke(
                Color.primary
                    .opacity(0.08),
                lineWidth: 1
            )
        }
        .onTapGesture {
            
            guard
                !isAnswerVisible
            else {
                return
            }
            
            onReveal()
        }
    }
    
    // MARK: - Header
    
    private var cardTypeHeader:
        some View {
        
        HStack {
            
            Label(
                card.type ==
                    .recognition
                    ? "Recognition"
                    : "Recall",
                systemImage:
                    card.type ==
                    .recognition
                    ? "eye"
                    : "arrow.uturn.forward"
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
            
            Spacer()
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var cardContent:
        some View {
        
        switch card.type {
            
        case .recognition:
            
            recognitionContent
            
        case .recall:
            
            recallContent
        }
    }
    
    // MARK: - Recognition
    
    @ViewBuilder
    private var recognitionContent:
        some View {
        
        if isAnswerVisible {
            
            targetContent(
                mode:
                    afterAnswerDisplayMode
            )
            
            Divider()
            
            Text(
                card.sourceText
            )
            .font(
                .title2
                    .weight(
                        .semibold
                    )
            )
            .multilineTextAlignment(
                .center
            )
            
        } else {
            
            targetContent(
                mode:
                    beforeAnswerDisplayMode
            )
            
            visibleReadingHint
        }
    }
    
    // MARK: - Recall
    
    @ViewBuilder
    private var recallContent:
        some View {
        
        if isAnswerVisible {
            
            Text(
                card.sourceText
            )
            .font(.title3)
            .foregroundStyle(
                .secondary
            )
            .multilineTextAlignment(
                .center
            )
            
            Divider()
            
            targetContent(
                mode:
                    afterAnswerDisplayMode
            )
            
        } else {
            
            Text(
                card.sourceText
            )
            .font(
                .largeTitle
                    .weight(
                        .semibold
                    )
            )
            .multilineTextAlignment(
                .center
            )
            
            visibleReadingHint
        }
    }
    
    // MARK: - Target
    
    @ViewBuilder
    private func targetContent(
        mode:
            TargetDisplayMode
    ) -> some View {
        
        switch mode {
            
        case .target:
            
            targetText
            
        case .reading:
            
            Text(
                usableReading ??
                card.targetText
            )
            .font(
                .largeTitle
                    .weight(
                        .semibold
                    )
            )
            .multilineTextAlignment(
                .center
            )
            
        case .targetAndReading:
            
            targetText
            
            if let reading =
                usableReading {
                
                Text(reading)
                    .font(.title3)
                    .foregroundStyle(
                        .secondary
                    )
                    .multilineTextAlignment(
                        .center
                    )
            }
        }
    }
    
    private var targetText:
        some View {
        
        Text(
            card.targetText
        )
        .font(
            .largeTitle
                .weight(
                    .semibold
                )
        )
        .multilineTextAlignment(
            .center
        )
    }
    
    // MARK: - Reading Hint
    
    @ViewBuilder
    private var visibleReadingHint:
        some View {
        
        if isReadingHintVisible,
           let reading =
            usableReading {
            
            Text(reading)
                .font(.title3)
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
                )
                .transition(
                    .opacity
                )
        }
    }
    
    private var shouldShowHintButton:
        Bool {
        
        guard
            readingHintEnabled,
            !isAnswerVisible,
            !isReadingHintVisible,
            usableReading != nil
        else {
            return false
        }
        
        if card.type ==
            .recognition,
           beforeAnswerDisplayMode
            .includesReading {
            
            return false
        }
        
        return true
    }
    
    private var usableReading:
        String? {
        
        guard
            let reading =
                card.targetReading?
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    ),
            !reading.isEmpty
        else {
            return nil
        }
        
        return reading
    }
}
