//
//  BaseSnapshotTestCase+UICollectionView.swift
//  Meduza
//
//  Created by Samarenko Andrey on 12.06.2024.
//

import UIKit

// MARK: - BaseSnapshotTestCase + UICollectionView

extension BaseSnapshotTestCase {
    
    func record(
        _ view: UICollectionView,
        renderContext: SnapshotRendererContext.CollectionView,
        using metaInfo: SnapshotTestCaseMetaInfo
    ) throws {
        let snapshot = SnapshotRenderer.image(
            view,
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
        _ view: UICollectionView,
        renderContext: SnapshotRendererContext.CollectionView,
        using metaInfo: SnapshotTestCaseMetaInfo
    ) throws {
        let renderedImage = SnapshotRenderer.image(view, using: renderContext)
        let recordedImage = try SnapshotFileManager.load(for: metaInfo)
        
        try compare(
            recordedImage,
            renderedImage,
            using: metaInfo
        )
    }
}

