//
//  SnapshotRenderer.swift
//  Meduza
//
//  Created by Samarenko Andrey on 12.06.2024.
//

import Foundation
import UIKit

// MARK: - Implementation

/// Статический класс без зависимостей для отрисовки различных представлений
final class SnapshotRenderer {
    
    // MARK: - Initialization

    // Экземпляр класса создавать нельзя
    private init() {}

    // MARK: - Internal
    
    static func render(
        _ view: UIView,
        in window: UIWindow
    ) -> UIImage {
        let graphicRenderer = UIGraphicsImageRenderer(bounds: view.bounds)
        return graphicRenderer.image { context in
            window.layer.render(in: context.cgContext)
        }
    }
    
    static func render(
        _ collectionView: UICollectionView,
        in window: UIWindow
    ) -> UIImage {
        let size = collectionView.collectionViewLayout.collectionViewContentSize
        let graphicRenderer = UIGraphicsImageRenderer(size: size)
        return graphicRenderer.image { context in
            window.layer.render(in: context.cgContext)
        }
    }
    
    static func render(
        _ navigationBar: UINavigationBar,
        in window: UIWindow
    ) -> UIImage {
        let contentSize = navigationBar.bounds.size
        
        let graphicRenderer = UIGraphicsImageRenderer(size: contentSize)
        return graphicRenderer.image { context in
            window.layer.render(in: context.cgContext)
        }
    }
    
    static func render(
        window: UIWindow,
        ignoreSafeAreaInsets: Bool
    ) -> UIImage {
        if ignoreSafeAreaInsets {
            let safeAreaInsets = window.safeAreaInsets
            let contentRect = window.bounds.inset(by: safeAreaInsets)
            
            let graphicRenderer = UIGraphicsImageRenderer(bounds: contentRect)
            return graphicRenderer.image { context in
                context.cgContext.translateBy(
                    x: -safeAreaInsets.left,
                    y: -safeAreaInsets.top
                )
                window.layer.render(in: context.cgContext)
            }
        } else {
            let contentRect = window.bounds
            
            let graphicRenderer = UIGraphicsImageRenderer(bounds: contentRect)
            return graphicRenderer.image { context in
                window.layer.render(in: context.cgContext)
            }
        }
    }
    
    /// Метод отрисовки изображения для представления пиксельных различий в двух `UIImage`-представлениях
    ///
    /// - Parameters:
    ///   - originalImage: Оригинальное-изображение, с которым производится сравнение
    ///   - image: Новое изображение, которое сравнивается
    ///
    /// - Returns: `UIImage`-представление для иллюстрации различий между двумя `UIImage`-представлениями с помощью
    /// наложения их друг на друга и применения `difference blend-mode`'a
    static func renderDifference(
        between originalImage: UIImage,
        and image: UIImage
    ) throws -> UIImage {
        
        // Максимально возможные размеры изображения ( если изображения разного размера )
        let diffImageSize = CGSize(
            width: max(originalImage.size.width, image.size.width),
            height: max(originalImage.size.height, image.size.height)
        )
        // Для игнорирования alpha-канала и оптимизации отрисовки
        let isBitmapOpaque: Bool = true
        // Задаем равный нулю, чтобы использовался scale устройства
        let scale: CGFloat = 0.0
        
        UIGraphicsBeginImageContextWithOptions(diffImageSize, isBitmapOpaque, scale)
        
        // Отрисовка оригинального изображения
        let originalImageRect = CGRect(
            x: 0,
            y: 0,
            width: originalImage.size.width,
            height: originalImage.size.height
        )
        originalImage.draw(in: originalImageRect)
        
        guard let currentContext = UIGraphicsGetCurrentContext() else {
            throw SnapshotRendererError.unableToGetCurrentContext
        }
        
        // Выставление прозрачности второго изображения для наглядности
        currentContext.setAlpha(0.5)
        
        // Для применения эффектов и оптимизации рендеринга группы изображений
        currentContext.beginTransparencyLayer(auxiliaryInfo: nil)
        
        // Отрисовка изображения, которое сравнивают с оригиналом
        let newImageRect = CGRect(
            x: 0,
            y: 0,
            width: image.size.width,
            height: image.size.height
        )
        
        image.draw(in: newImageRect)
        
        // Устанавливаем `blendMode` для получения разницы путем комбинирования слоев
        // с использованием принципа: `ResultColor=∣SourceColor−DestinationColor∣`
        currentContext.setBlendMode(.difference)
        
        // Применяем комбинацию слоев к полностью белому слою (0xFFFFFF)
        // для явного обозначения расхождений. Инвертируем цвета: 0x<current_color> - 0xFFFFFF = 0x<diff_color>
        currentContext.setFillColor(UIColor.white.cgColor)
        
        // Применяем `blendMode` только к `rect`, в который вписано оригинальное изображение
        currentContext.fill([originalImageRect])
        
        currentContext.endTransparencyLayer()
        
        guard let diffImage = UIGraphicsGetImageFromCurrentImageContext() else {
            throw SnapshotRendererError.unableToGetImageFromContext
        }
        UIGraphicsEndImageContext()
        
        return diffImage
    }
}
