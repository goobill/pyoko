//
//  AppearancePreference.swift
//  pyoko
//
//  Created by Bill on 06/09/2026.
//

import SwiftUI

enum AppearancePreference:
    String,
    CaseIterable,
    Identifiable {
    
    case system
    case light
    case dark
    
    var id: Self {
        self
    }
    
    var title: String {
        switch self {
        case .system:
            return "System"
            
        case .light:
            return "Light"
            
        case .dark:
            return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
            
        case .light:
            return .light
            
        case .dark:
            return .dark
        }
    }
}
