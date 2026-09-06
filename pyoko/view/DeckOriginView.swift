import SwiftUI

struct DeckOriginView: View {
    
    let deck: PyokoDeck
    
    var body: some View {
        
        HStack(
            spacing: 5
        ) {
            
            Image(
                systemName:
                    deck.origin
                        .systemImage
            )
            
            Text(
                deck.origin.title
            )
            
            if let detail =
                deck.originDetail {
                
                Text("•")
                
                Text(
                    detail
                )
                .lineLimit(1)
            }
        }
        .font(
            .caption
        )
        .foregroundStyle(
            .secondary
        )
    }
}
