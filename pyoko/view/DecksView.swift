import SwiftUI
import SwiftData

struct DecksView: View {
    
    @Environment(\.modelContext)
    private var modelContext
    
    @Query(
        sort: \PyokoDeck.importedAt,
        order: .reverse
    )
    private var decks: [PyokoDeck]
    
    // MARK: - Download State
    
    @State
    private var downloadingDeckKeys:
        Set<String> = []
    
    // MARK: - Delete Confirmation
    
    @State
    private var deckPendingDeletion:
        PyokoDeck?
    
    @State
    private var showingDeleteConfirmation =
        false
    
    // MARK: - Error
    
    @State
    private var showingError =
        false
    
    @State
    private var errorMessage =
        ""
    
    // MARK: - Body
    
    var body: some View {
        
        List {
            
            importedDecksSection
            
            builtInDecksSection
        }
        .navigationTitle(
            "Decks"
        )
        .toolbar {
            
            ToolbarItem(
                placement: .primaryAction
            ) {
                
                NavigationLink {
                    
                    DataLoaderView()
                    
                } label: {
                    
                    Label(
                        "Import Deck",
                        systemImage: "plus"
                    )
                }
            }
        }
        .alert(
            "Delete Deck?",
            isPresented:
                $showingDeleteConfirmation
        ) {
            
            Button(
                "Cancel",
                role: .cancel
            ) {
                deckPendingDeletion = nil
            }
            
            Button(
                "Delete",
                role: .destructive
            ) {
                
                deletePendingDeck()
            }
            
        } message: {
            
            if let deck =
                deckPendingDeletion {
                
                Text(
                    """
                    "\(deck.name)" and its review cards will be deleted.
                    """
                )
            }
        }
        .alert(
            "Deck Error",
            isPresented:
                $showingError
        ) {
            
            Button("OK") {}
            
        } message: {
            
            Text(
                errorMessage
            )
        }
    }
    
    // MARK: - Imported Decks
    
    private var importedDecksSection:
        some View {
        
        Section {
            
            if importedDecks.isEmpty {
                
                ContentUnavailableView {
                    
                    Label(
                        "No Imported Decks",
                        systemImage:
                            "rectangle.stack"
                    )
                    
                } description: {
                    
                    Text(
                        "Import a CSV, URL, or Google Sheet to create a deck."
                    )
                    
                } actions: {
                    
                    NavigationLink {
                        
                        DataLoaderView()
                        
                    } label: {
                        
                        Label(
                            "Import Deck",
                            systemImage: "plus"
                        )
                    }
                    .buttonStyle(
                        .borderedProminent
                    )
                }
                
            } else {
                
                ForEach(
                    importedDecks
                ) { deck in
                    
                    installedDeckRow(
                        deck
                    )
                }
            }
            
        } header: {
            
            Text(
                "Imported Decks"
            )
        }
    }
    
    // MARK: - Built-in Decks
    
    private var builtInDecksSection:
        some View {
        
        Section {
            
            ForEach(
                DefaultDecks.all
            ) { defaultDeck in
                
                builtInDeckRow(
                    defaultDeck
                )
            }
            
        } header: {
            
            Text(
                "Built-in Decks"
            )
            
        } footer: {
            
            Text(
                "Built-in decks contain both Recognition and Recall cards."
            )
        }
    }
    
    // MARK: - Imported Deck Row
    
    private func installedDeckRow(
        _ deck: PyokoDeck
    ) -> some View {
        
        HStack(
            alignment: .center,
            spacing: 14
        ) {
            
            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                
                Text(
                    deck.name
                )
                .fontWeight(
                    .medium
                )
                
                HStack(
                    spacing: 4
                ) {
                    
                    Text(
                        deck.vocabularyCount
                            .formatted()
                    )
                    
                    Text(
                        "vocabulary"
                    )
                }
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
                
                DeckOriginView(
                    deck: deck
                )
            }
            
            Spacer()
            
            Button(
                role: .destructive
            ) {
                
                requestDelete(
                    deck
                )
                
            } label: {
                
                Image(
                    systemName:
                        "trash"
                )
            }
            .buttonStyle(
                .borderless
            )
            .help(
                "Delete Deck"
            )
        }
        .padding(
            .vertical,
            4
        )
    }
    
    // MARK: - Built-in Deck Row
    
    private func builtInDeckRow(
        _ defaultDeck:
            DefaultDeck
    ) -> some View {
        
        let installed =
            installedBuiltInDeck(
                key:
                    defaultDeck.key
            )
        
        let downloading =
            downloadingDeckKeys
                .contains(
                    defaultDeck.key
                )
        
        return HStack(
            alignment: .center,
            spacing: 14
        ) {
            
            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                
                Text(
                    defaultDeck.name
                )
                .fontWeight(
                    .medium
                )
                
                Text(
                    defaultDeck.description
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
                
                if let installed {
                    
                    HStack(
                        spacing: 5
                    ) {
                        
                        Image(
                            systemName:
                                DeckOrigin
                                    .builtIn
                                    .systemImage
                        )
                        
                        Text(
                            "Built-in"
                        )
                        
                        Text("•")
                        
                        Text(
                            "\(installed.vocabularyCount.formatted()) vocabulary"
                        )
                    }
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
            
            Spacer()
            
            if let installed {
                
                installedBuiltInActions(
                    deck:
                        installed
                )
                
            } else if downloading {
                
                ProgressView()
                    .controlSize(
                        .small
                    )
                
            } else {
                
                Button {
                    
                    download(
                        defaultDeck
                    )
                    
                } label: {
                    
                    Label(
                        "Download",
                        systemImage:
                            "arrow.down.circle"
                    )
                }
                .buttonStyle(
                    .bordered
                )
            }
        }
        .padding(
            .vertical,
            4
        )
    }
    
    // MARK: - Built-in Actions
    
    private func installedBuiltInActions(
        deck: PyokoDeck
    ) -> some View {
        
        HStack(
            spacing: 10
        ) {
            
            Label(
                "Installed",
                systemImage:
                    "checkmark.circle.fill"
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
            
            Button(
                role: .destructive
            ) {
                
                requestDelete(
                    deck
                )
                
            } label: {
                
                Image(
                    systemName:
                        "trash"
                )
            }
            .buttonStyle(
                .borderless
            )
            .help(
                "Delete Deck"
            )
        }
    }
    
    // MARK: - Deck Groups
    
    private var importedDecks:
        [PyokoDeck] {
        
        decks.filter {
            
            $0.origin !=
                DeckOrigin.builtIn
        }
    }
    
    // MARK: - Installed Built-in
    
    private func installedBuiltInDeck(
        key: String
    ) -> PyokoDeck? {
        
        decks.first {
            
            $0.catalogKey ==
                key
        }
    }
    
    // MARK: - Download
    
    private func download(
        _ defaultDeck:
            DefaultDeck
    ) {
        
        guard
            !downloadingDeckKeys
                .contains(
                    defaultDeck.key
                )
        else {
            return
        }
        
        downloadingDeckKeys
            .insert(
                defaultDeck.key
            )
        
        Task {
            
            defer {
                
                downloadingDeckKeys
                    .remove(
                        defaultDeck.key
                    )
            }
            
            let manager =
                DeckManager(
                    modelContext:
                        modelContext
                )
            
            do {
                
                try await manager
                    .install(
                        defaultDeck
                    )
                
            } catch {
                
                showError(
                    error
                )
            }
        }
    }
    
    // MARK: - Delete
    
    private func requestDelete(
        _ deck: PyokoDeck
    ) {
        
        deckPendingDeletion =
            deck
        
        showingDeleteConfirmation =
            true
    }
    
    private func deletePendingDeck() {
        
        guard
            let deck =
                deckPendingDeletion
        else {
            return
        }
        
        let manager =
            DeckManager(
                modelContext:
                    modelContext
            )
        
        do {
            
            try manager.delete(
                deck
            )
            
            deckPendingDeletion =
                nil
            
        } catch {
            
            showError(
                error
            )
        }
    }
    
    // MARK: - Error
    
    private func showError(
        _ error: Error
    ) {
        
        errorMessage =
            error.localizedDescription
        
        showingError =
            true
    }
}
