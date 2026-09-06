import Foundation

enum DeckOrigin: String, Codable, CaseIterable {
    
    case builtIn
    case file
    case url
    case googleSheets
    
    // Reserved for future direct integrations
    
    case googleDrive
    case iCloudDrive
    
    var title: String {
        
        switch self {
            
        case .builtIn:
            return "Built-in"
            
        case .file:
            return "File"
            
        case .url:
            return "URL"
            
        case .googleSheets:
            return "Google Sheets"
            
        case .googleDrive:
            return "Google Drive"
            
        case .iCloudDrive:
            return "iCloud Drive"
        }
    }
    
    var systemImage: String {
        
        switch self {
            
        case .builtIn:
            return "shippingbox"
            
        case .file:
            return "doc"
            
        case .url:
            return "link"
            
        case .googleSheets:
            return "tablecells"
            
        case .googleDrive:
            return "externaldrive"
            
        case .iCloudDrive:
            return "icloud"
        }
    }
}
