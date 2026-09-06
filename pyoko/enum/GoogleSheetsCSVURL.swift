//
//  GoogleSheetsCSVURL.swift
//  pyoko
//
//  Created by Bill on 06/09/2026.
//

import Foundation

struct GoogleSheetCSVReference {
    
    let csvURL: URL
    
    let identifier: String
}

enum GoogleSheetsCSVURL {
    
    static func makeReference(
        from rawURL: String
    ) throws -> GoogleSheetCSVReference {
        
        let trimmed =
            rawURL.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
        
        guard
            let originalURL =
                URL(
                    string: trimmed
                ),
            let components =
                URLComponents(
                    url: originalURL,
                    resolvingAgainstBaseURL:
                        false
                ),
            let host =
                components.host?
                    .lowercased(),
            host == "docs.google.com"
        else {
            
            throw DataLoaderError
                .invalidGoogleSheetURL
        }
        
        let pathParts =
            components.path
                .split(separator: "/")
                .map(String.init)
        
        guard
            pathParts.count >= 3,
            pathParts[0] ==
                "spreadsheets",
            pathParts[1] ==
                "d"
        else {
            
            throw DataLoaderError
                .invalidGoogleSheetURL
        }
        
        let gid =
            getGID(
                from: components
            )
            ?? "0"
        
        // Published Google Sheet:
        //
        // /spreadsheets/d/e/<ID>/pub
        
        if pathParts.count >= 5,
           pathParts[2] == "e" {
            
            let publishedID =
                pathParts[3]
            
            guard
                !publishedID.isEmpty
            else {
                
                throw DataLoaderError
                    .invalidGoogleSheetURL
            }
            
            var csvComponents =
                URLComponents()
            
            csvComponents.scheme =
                "https"
            
            csvComponents.host =
                "docs.google.com"
            
            csvComponents.path =
                "/spreadsheets/d/e/\(publishedID)/pub"
            
            csvComponents.queryItems = [
                
                URLQueryItem(
                    name: "gid",
                    value: gid
                ),
                
                URLQueryItem(
                    name: "single",
                    value: "true"
                ),
                
                URLQueryItem(
                    name: "output",
                    value: "csv"
                )
            ]
            
            guard
                let csvURL =
                    csvComponents.url
            else {
                
                throw DataLoaderError
                    .invalidGoogleSheetURL
            }
            
            return GoogleSheetCSVReference(
                csvURL: csvURL,
                identifier:
                    "published:\(publishedID):\(gid)"
            )
        }
        
        // Normal Google Sheets URL:
        //
        // /spreadsheets/d/<spreadsheet-id>/edit
        
        let spreadsheetID =
            pathParts[2]
        
        guard
            !spreadsheetID.isEmpty
        else {
            
            throw DataLoaderError
                .invalidGoogleSheetURL
        }
        
        var csvComponents =
            URLComponents()
        
        csvComponents.scheme =
            "https"
        
        csvComponents.host =
            "docs.google.com"
        
        csvComponents.path =
            "/spreadsheets/d/\(spreadsheetID)/export"
        
        csvComponents.queryItems = [
            
            URLQueryItem(
                name: "format",
                value: "csv"
            ),
            
            URLQueryItem(
                name: "gid",
                value: gid
            )
        ]
        
        guard
            let csvURL =
                csvComponents.url
        else {
            
            throw DataLoaderError
                .invalidGoogleSheetURL
        }
        
        return GoogleSheetCSVReference(
            csvURL: csvURL,
            identifier:
                "\(spreadsheetID):\(gid)"
        )
    }
    
    // MARK: - GID
    
    private static func getGID(
        from components:
            URLComponents
    ) -> String? {
        
        if let queryGID =
            components
                .queryItems?
                .first(
                    where: {
                        $0.name == "gid"
                    }
                )?
                .value {
            
            return queryGID
        }
        
        guard
            let fragment =
                components.fragment
        else {
            return nil
        }
        
        let values =
            fragment.split(
                separator: "&"
            )
        
        for value in values {
            
            let parts =
                value.split(
                    separator: "=",
                    maxSplits: 1
                )
            
            guard
                parts.count == 2,
                parts[0] == "gid"
            else {
                continue
            }
            
            return String(
                parts[1]
            )
        }
        
        return nil
    }
}
