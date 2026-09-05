//
//  DefaultDataSources.swift
//  pyoko
//
//  Created by Bill on 05/09/2026.
//

import Foundation

struct DefaultDataSource: Identifiable {
    
    let key: String
    let name: String
    let description: String
    let urlString: String
    
    var id: String {
        key
    }
}

enum DefaultDataSources {
    
    static let all: [DefaultDataSource] = [
        
        DefaultDataSource(
            key: "jlpt-n5",
            name: "JLPT N5 Vocabulary",
            description: "Starter vocabulary for JLPT N5.",
            urlString: "https://example.com/pyoko/jlpt-n5.csv"
        ),
        
        DefaultDataSource(
            key: "jlpt-n4",
            name: "JLPT N4 Vocabulary",
            description: "Vocabulary for JLPT N4.",
            urlString: "https://example.com/pyoko/jlpt-n4.csv"
        ),
        
        DefaultDataSource(
            key: "jlpt-n3",
            name: "JLPT N3 Vocabulary",
            description: "Vocabulary for JLPT N3.",
            urlString: "https://example.com/pyoko/jlpt-n3.csv"
        )
    ]
}
