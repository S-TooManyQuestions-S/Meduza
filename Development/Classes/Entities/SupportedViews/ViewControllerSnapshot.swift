//
//  BaseSnapshotTestCase+UIViewController.swift
//  Meduza
//
//  Created by Samarenko Andrey on 12.06.2024.
//

import UIKit

final class ViewControllerSnapshot: Snapshot {
    
    // Private
    private var viewController: UIViewController
    private var window: UIWindow
    
    // MARK: - Initialization
    
    init(
        with viewController: UIViewController,
        in window: UIWindow
    ) {
        self.viewController = viewController
        self.window = window
    }
    
    // MARK: - Snapshot

    func record(
        in renderContexts: [SnapshotRenderContext],
        using metaInfo: SnapshotMetaInfo
    ) throws {
        for renderContext in renderContexts {
            SnapshotUtils.apply(renderContext, to: window)
            
            let snapshot = SnapshotRenderer.render(
                window: window,
                ignoreSafeAreaInsets: renderContext.ignoreSafeArea
            )
            
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
        try renderContexts.filter { renderContext in
            SnapshotUtils.apply(renderContext, to: window)
            
            let recordedImage = try SnapshotFileManager.load(
                for: metaInfo,
                renderContext
            )
            
            let renderedImage = SnapshotRenderer.render(
                window: window,
                ignoreSafeAreaInsets: renderContext.ignoreSafeArea
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
        // Добавление `ViewController'a` на `UIWindow` для корректной отработки `layoutIfNeeded`
        guard let rootViewController = window.rootViewController else {
            throw SnapshotRendererError.unableToGetRootViewController
        }
        
        // Добавление тестируемого `ViewController`'a в качестве `child` для корректного жизненного цикла
        rootViewController.addChild(viewController)
        rootViewController.view.addSubview(viewController.view)
        viewController.view.frame = rootViewController.view.bounds
        viewController.didMove(toParent: rootViewController)
        
        // Заставляем view рассчитать собственные размеры
        viewController.view.layoutIfNeeded()
    }
    
    func tearDown() {
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.willMove(toParent: nil)
    }
}
