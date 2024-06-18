//
//  SnapshotUtils.swift
//  SnapshotTestUtils
//
//  Created by Samarenko Andrey on 19.06.2024.
//

import Foundation
import UIKit

final class SnapshotUtils {
    
    static func compare(
        _ recordedImage: UIImage,
        _ renderedImage: UIImage,
        using metaInfo: SnapshotMetaInfo,
        _ renderContext: SnapshotRenderContext
    ) throws -> Bool {
        let isEqual = try SnapshotComparator.compare(
            recordedImage,
            with: renderedImage,
            pixelTolerance: metaInfo.pixelTolerance,
            overallTolerance: metaInfo.overallTolerance
        )
        
        guard isEqual else {
            try SnapshotLogger.perform {
                let activityName: String = metaInfo.selectorDescription
                let diffImage = try SnapshotRenderer.renderDifference(between: recordedImage, and: renderedImage)
                
                SnapshotLogger.logFailedComparison(
                    activityName: activityName,
                    recordedImage,
                    renderedImage,
                    diffImage
                )
                
                try SnapshotFileManager.save(snapshot: recordedImage, with: .failedReference, renderContext, metaInfo)
                try SnapshotFileManager.save(snapshot: renderedImage, with: .failedTest, renderContext, metaInfo)
                try SnapshotFileManager.save(snapshot: diffImage, with: .failedDiff, renderContext, metaInfo)
            }
            
            return false
        }
        
        return true
    }
    
    static func apply(
        _ renderContext: SnapshotRenderContext,
        to window: UIWindow
    ) {
        window.backgroundColor = renderContext.backgroundColor
        window.overrideUserInterfaceStyle = renderContext.interfaceStyle
    }
}
