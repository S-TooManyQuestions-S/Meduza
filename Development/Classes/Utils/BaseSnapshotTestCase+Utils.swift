//
//  BaseSnapshotTestCase+Utils.swift
//  Meduza
//
//  Created by Samarenko Andrey on 12.06.2024.
//

import UIKit

// MARK: - Common

extension BaseSnapshotTestCase {
    
    func compare(
        _ recordedImage: UIImage,
        _ renderedImage: UIImage,
        using metaInfo: SnapshotTestCaseMetaInfo
    ) throws {
        let isEqual = try SnapshotComparator.compare(
            recordedImage,
            with: renderedImage,
            pixelTolerance: metaInfo.pixelTolerance,
            overallTolerance: metaInfo.overallTolerance
        )
        
        guard isEqual else {
            let activityName: String = metaInfo.invocationSelector.description
            let diffImage = try SnapshotRenderer.difference(recordedImage, with: renderedImage)
            
            SnapshotLogger.logFailedComparison(
                activityName: activityName,
                recordedImage,
                renderedImage,
                diffImage
            )
            
            try SnapshotFileManager.save(snapshot: recordedImage, with: .failedReference, metaInfo: metaInfo)
            try SnapshotFileManager.save(snapshot: renderedImage, with: .failedTest, metaInfo: metaInfo)
            try SnapshotFileManager.save(snapshot: diffImage, with: .failedDiff, metaInfo: metaInfo)
            
            throw SnapshotBaseError.comparisonError
        }
    }
}
