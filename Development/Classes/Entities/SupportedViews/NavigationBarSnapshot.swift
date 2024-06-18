//
//  BaseSnapshotTestCase+UINavigationController.swift
//  Meduza
//
//  Created by Samarenko Andrey on 12.06.2024.
//

import UIKit

// MARK: - BaseSnapshotTestCase + UINavigationController

final class NavigationBarSnapshot: Snapshot {
    
    // Private
    private var navigationController: UINavigationController
    private var window: UIWindow
    
    // MARK: - Initialization
    
    init(
        with navigationController: UINavigationController,
        in window: UIWindow
    ) {
        self.navigationController = navigationController
        self.window = window
    }
    
    // MARK: - Snapshot

    func record(
        in renderContexts: [SnapshotRenderContext],
        using metaInfo: SnapshotMetaInfo
    ) throws {
        try renderContexts.forEach { renderContext in
            SnapshotUtils.apply(renderContext, to: window)
            
            let snapshot = SnapshotRenderer.render(navigationController.navigationBar, in: window)
            
            try SnapshotFileManager.save(
                snapshot: snapshot,
                with: .reference,
                renderContext,
                metaInfo
            )
        }
        
        throw SnapshotBaseError.ranInRecordMode
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
            
            let renderedImage = SnapshotRenderer.render(navigationController.navigationBar, in: window)
            
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
        // Добавление `ViewController'a` на `UIWindow` для корректной отработки `layoutIfNeeded`
        guard let rootViewController = window.rootViewController else {
            throw SnapshotRendererError.unableToGetRootViewController
        }
        
        // Добавление тестируемого `ViewController`'a в качестве `child` для корректного жизненного цикла
        rootViewController.addChild(navigationController)
        rootViewController.view.addSubview(navigationController.view)
        navigationController.view.frame = rootViewController.view.bounds
        navigationController.didMove(toParent: rootViewController)
        
        // Заставляем view рассчитать собственные размеры
        navigationController.view.layoutIfNeeded()
    }

    func tearDown() {
        navigationController.view.removeFromSuperview()
        navigationController.removeFromParent()
        navigationController.willMove(toParent: nil)
    }
}
