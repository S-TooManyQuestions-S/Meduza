//
//  SnapshotComparatorError.swift
//  SnapshotTestUtils
//
//  Created by Samarenko Andrey on 18.06.2024.
//

import Foundation

enum SnapshotComparatorError: LocalizedError {
    
    case unableToCreateCGImages(String)
    case unableToExtractColorSpace
    case unableToCreateContexts
    case unableToBoundMemory
    case imagesOfDifferentSize(lhs: CGSize, rhs: CGSize)
    
    var errorDescription: String? {
        let descriptionSummary: String
        switch self {
        case .unableToCreateCGImages(let image):
            descriptionSummary = "UIImage.cgImage property returned nil for \(image)."
        case .unableToExtractColorSpace:
            descriptionSummary = "UIImage.colorSpace property returned nil."
        case .unableToCreateContexts:
            descriptionSummary = "Attempt to create CGContext from images meta-info has failed."
        case .unableToBoundMemory:
            descriptionSummary = "Attempt to bound memory to iterate over bitmap has failed."
        case .imagesOfDifferentSize(let lhs, let rhs):
            descriptionSummary = "Attempt to compare images of different size: {\(lhs.height); \(lhs.width)}, {\(rhs.height); \(rhs.width)}."
        }
       
        return descriptionSummary.format(as: .executionError)
    }
}
