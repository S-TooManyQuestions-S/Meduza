//
//  BaseSnapshotTestCase+UIView.swift
//  Meduza
//
//  Created by Samarenko Andrey on 12.06.2024.
//

import UIKit

struct SnapshotConstraintContext {
    let height: CGFloat?
    let widthResolution: WidthResolutionStrategy
}

public enum WidthResolutionStrategy {
    case aspectFit(value: CGFloat)
    case aspectFill(value: CGFloat)
    case none
}


// MARK: - BaseSnapshotTestCase + UIView

final class ViewSnapshot: Snapshot {
    
    // Private
    private var view: UIView
    private var window: UIWindow
    
    // Models
    private let constraintContext: SnapshotConstraintContext
    
    // MARK: - Initialization
    
    init(
        with view: UIView,
        in window: UIWindow,
        using context: SnapshotConstraintContext
    ) {
        self.view = view
        self.window = window
        
        self.constraintContext = context
    }
    
    // MARK: - Snapshot

    func record(
        in renderContexts: [SnapshotRenderContext],
        using metaInfo: SnapshotMetaInfo
    ) throws {
        try renderContexts.forEach { renderContext in
            SnapshotUtils.apply(renderContext, to: window)
            
            let snapshot = SnapshotRenderer.render(view, in: window)
            
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
                view,
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
        
        // Добавление `View` на `UIWindow` для корректной отработки `layoutIfNeeded`
        window.addSubview(view)
        
        // Выключаем ненужную функциональность во избежание конфликтующих констрейнтов
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Активация констрейнтов если размеры заданы в ручную
        if let customHeight = constraintContext.height {
            constraints.append(view.heightAnchor.constraint(equalToConstant: customHeight))
        }
        
        switch constraintContext.widthResolution {
        case .aspectFit(let value):
            constraints.append(view.widthAnchor.constraint(lessThanOrEqualToConstant: value))
        case .aspectFill(let value):
            constraints.append(view.widthAnchor.constraint(equalToConstant: value))
        case .none:
            break
        }
        
        NSLayoutConstraint.activate(constraints)
        
        // Заставляем view рассчитать собственные размеры
        view.layoutIfNeeded()
    }
    
    func tearDown() {
        window.willRemoveSubview(view)
        view.removeFromSuperview()
        
        NSLayoutConstraint.deactivate(view.constraints)
    }
}
