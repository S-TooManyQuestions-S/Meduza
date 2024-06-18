//
//  BaseSnapshotTestCase+UICollectionView.swift
//  Meduza
//
//  Created by Samarenko Andrey on 12.06.2024.
//

import UIKit

// MARK: - BaseSnapshotTestCase + UICollectionView

final class CollectionViewSnapshot: Snapshot {

    // Private
    private var collectionView: UICollectionView
    private var window: UIWindow
    
    // MARK: - Initialization
    
    init(
        with collectionView: UICollectionView,
        in window: UIWindow
    ) {
        self.collectionView = collectionView
        self.window = window
    }
    
    // MARK: - Snapshot
    
    func record(
        in renderContexts: [SnapshotRenderContext],
        using metaInfo: SnapshotMetaInfo
    ) throws {
        try renderContexts.forEach { renderContext in
            SnapshotUtils.apply(renderContext, to: window)
            let snapshot = SnapshotRenderer.render(collectionView, in: window)
            
            try SnapshotFileManager.save(
                snapshot: snapshot,
                with: .reference,
                renderContext,
                metaInfo
            )
        }
    }
    
    func verify(
        in renderContexts: [SnapshotRenderContext],
        using metaInfo: SnapshotMetaInfo
    ) throws -> Bool {
        return try renderContexts.filter { renderContext in
            SnapshotUtils.apply(renderContext, to: window)
            let recordedImage = try SnapshotFileManager.load(
                for: metaInfo,
                renderContext
            )
            
            let renderedImage = SnapshotRenderer.render(
                collectionView,
                in: window
            )
            
            let isSuccessFull = try SnapshotUtils.compare(
                recordedImage,
                renderedImage,
                using: metaInfo,
                renderContext
            )
            
            return !isSuccessFull
        }.isEmpty
    }
    
    func setUp() throws {
        // Констрейнты, которые применяются в рамках записи
        var constraints: [NSLayoutConstraint] = []
        
        // Рассчитываем оптимальный размер коллекции по её содержимому
        collectionView.frame.size = collectionView.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
        // Получаем точный размер содержимого
        let contentSize = collectionView.collectionViewLayout.collectionViewContentSize
        
        // Добавление `View` на `UIWindow` для корректной отработки `layoutIfNeeded`
        window.addSubview(collectionView)
        
        // Выключаем ненужную функциональность во избежание конфликтующих констрейнтов
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Активация констрейнтов если размеры заданы в ручную
        constraints.append(collectionView.heightAnchor.constraint(equalToConstant: contentSize.height))
        constraints.append(collectionView.widthAnchor.constraint(equalToConstant: contentSize.width))
        
        NSLayoutConstraint.activate(constraints)
        
        // Заставляем view рассчитать собственные размеры
        collectionView.layoutIfNeeded()
    }

    func tearDown() {
        window.willRemoveSubview(collectionView)
        collectionView.removeFromSuperview()
        
        NSLayoutConstraint.deactivate(collectionView.constraints)
    }
}
