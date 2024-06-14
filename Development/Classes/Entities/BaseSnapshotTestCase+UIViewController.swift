//
//  BaseSnapshotTestCase+UIViewController.swift
//  Meduza
//
//  Created by Samarenko Andrey on 12.06.2024.
//

import UIKit

// MARK: - BaseSnapshotTestCase + UIViewController

extension BaseSnapshotTestCase {
    
    func record(
        _ viewController: UIViewController,
        renderContext: SnapshotRendererContext.ViewController,
        using metaInfo: SnapshotTestCaseMetaInfo
    ) throws {
        let snapshot = try SnapshotRenderer.image(
            viewController,
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
        _ viewController: UIViewController,
        renderContext: SnapshotRendererContext.ViewController,
        using metaInfo: SnapshotTestCaseMetaInfo
    ) throws {
        let renderedImage = try SnapshotRenderer.image(viewController, using: renderContext)
        let recordedImage = try SnapshotFileManager.load(for: metaInfo)
        
        try compare(
            recordedImage,
            renderedImage,
            using: metaInfo
        )
    }
}
