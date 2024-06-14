//
//  BaseSnapshotTestCase+UINavigationController.swift
//  Meduza
//
//  Created by Samarenko Andrey on 12.06.2024.
//

import Foundation
import UIKit

// MARK: - BaseSnapshotTestCase + UINavigationController

extension BaseSnapshotTestCase {
    
    func record(
        _ navigationViewController: UINavigationController,
        renderContext: SnapshotRendererContext.NavigationViewController,
        using metaInfo: SnapshotTestCaseMetaInfo
    ) throws {
        let snapshot = try SnapshotRenderer.image(
            navigationViewController,
            using: renderContext
        )
        
        let recordedPath = try SnapshotFileManager.save(
            snapshot: snapshot,
            with: .reference,
            metaInfo: metaInfo
        )
        
        throw SnapshotBaseError.ranInRecordMode(recordedPath: recordedPath)
    }
    
    func verify(
        _ navigationViewController: UINavigationController,
        renderContext: SnapshotRendererContext.NavigationViewController,
        using metaInfo: SnapshotTestCaseMetaInfo
    ) throws {
        let renderedImage = try SnapshotRenderer.image(navigationViewController, using: renderContext)
        let recordedImage = try SnapshotFileManager.load(for: metaInfo)
        
        try compare(
            recordedImage,
            renderedImage,
            using: metaInfo
        )
    }
}
