//
//  SnapshotRendererError.swift
//  SnapshotTestUtils
//
//  Created by Samarenko Andrey on 18.06.2024.
//

import Foundation

enum SnapshotRendererError: LocalizedError {
    case unableToGetCurrentContext
    case unableToGetImageFromContext
    case unableToGetRootViewController
    
    var errorDescription: String? {
        let description: String
        switch self {
        case .unableToGetCurrentContext:
            description = "Unable to extract current context to draw diff-image."
        case .unableToGetImageFromContext:
            description = "Unable to extract image from created context."
        case .unableToGetRootViewController:
            description = "UIWindow has no associated rootViewController."
        }
        
        return description.format(as: .executionError)
    }
}
