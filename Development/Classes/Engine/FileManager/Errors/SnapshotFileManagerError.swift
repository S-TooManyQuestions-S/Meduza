//
//  SnapshotFileManagerError.swift
//  SnapshotTestUtils
//
//  Created by Samarenko Andrey on 18.06.2024.
//

import Foundation

enum SnapshotFileManagerError: LocalizedError {
    
    case unableToCreatePNGData(filePath: String)
    case noRecordAvailable(filePath: String)
    case unableToLoadImage(filePath: String)
    case unknownUserInterfaceStyle
    
    var errorDescription: String? {
        
        let descriptionSummary: String
        switch self {
        case .unableToCreatePNGData(let filePath):
            descriptionSummary = "UIImage.pngData() function has returned error for path: \(filePath)."
        case .noRecordAvailable(let filePath):
            descriptionSummary = "No recorded snapshot found for path: \(filePath)."
        case .unableToLoadImage(let filePath):
            descriptionSummary = "UIImage(contentsOfFile:) function has returned error for path: \(filePath)."
        case .unknownUserInterfaceStyle:
            descriptionSummary = "Unknown UIUserInterfaceStyle."
        }
        
        return descriptionSummary.format(as: .executionError)
    }
}
