//
//  SnapshotRenderer.swift
//  Meduza
//
//  Created by Samarenko Andrey on 12.06.2024.
//

import Foundation
import UIKit

// MARK: - DTO

struct SnapshotRendererContext {
    
    struct ViewController {
        // Тема приложения, в которой необходимо отрисовать представление.
        let interfaceStyle: UIUserInterfaceStyle
        let backgroundColor: UIColor
        let ignoreSafeArea: Bool
        let window: UIWindow
    }
    
    struct View {
        
        let interfaceStyle: UIUserInterfaceStyle
        // Высота представления (выставляется как констрейнт), при отсутствии - рассчитывается с помощью `autoLayout`-механизма.
        let height: CGFloat?
        // Ширина представения (выставляется как констрейнт), при отсутствии - рассчитывается с помощью `autoLayout`-мехнизма.
        let widthResolutionStrategy: WidthResolutionStrategy?
        
        let backgroundColor: UIColor
        let window: UIWindow
    }
    
    struct CollectionView {
        let interfaceStyle: UIUserInterfaceStyle
        let backgroundColor: UIColor
        let window: UIWindow
    }
    
    struct NavigationViewController {
        let interfaceStyle: UIUserInterfaceStyle
        let backgroundColor: UIColor
        let window: UIWindow
    }
}

// MARK: - Errors

enum SnapshotRendererError: LocalizedError {
    case unableToGetCurrentContext
    case unableToGetImageFromContext
    case unableToGetRootViewController
    
    var errorDescription: String? {
        let description: String
        switch self {
        case .unableToGetCurrentContext:
            description = "Unable to extract current context to draw diff-image."
        case .unableToGetImageFromContext:
            description = "Unable to extract image from created context."
        case .unableToGetRootViewController:
            description = "UIWindow has no associated rootViewController."
        }
        
        return description.format(as: .executionError)
    }
}


// MARK: - Implementation

/// Статический класс без зависимостей для отрисовки различных представлений
final class SnapshotRenderer {
    
    // MARK: - Initialization
    // Экземпляр класса создавать нельзя
    private init() {}

    // MARK: - Internal

    /// Метод для отрисовки `View`-представления
    ///
    /// - Parameters:
    ///   - view: Представление для отрисовки.
    ///   - window: `UIWindow` экземпляр, предоставляющий контекст для отрисовки представления.
    /// - Returns: Рендер представления в качестве экземпляра `UIImage`
    static func image(
        _ view: UIView,
        using context: SnapshotRendererContext.View
    ) -> UIImage {
        // Констрейнты, которые применяются в рамках записи
        var activeConstraints: [NSLayoutConstraint] = []
        
        // Переопределение темы, в которой будет произведен рендер изображения
        context.window.overrideUserInterfaceStyle = context.interfaceStyle
        
        // Переопределение цвета `UIWindow`
        context.window.backgroundColor = context.backgroundColor
        
        // Добавление `View` на `UIWindow` для корректной отработки `layoutIfNeeded`
        context.window.addSubview(view)
        
        // Выключаем ненужную функциональность во избежание конфликтующих констрейнтов
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Активация констрейнтов если размеры заданы в ручную
        if let customHeight = context.height {
            activeConstraints.append(view.heightAnchor.constraint(equalToConstant: customHeight))
        }
        
        switch context.widthResolutionStrategy {
        case .aspectFit(let value):
            activeConstraints.append(view.widthAnchor.constraint(lessThanOrEqualToConstant: value))
        case .aspectFill(let value):
            activeConstraints.append(view.widthAnchor.constraint(equalToConstant: value))
        case .none:
            break
        }
        
        NSLayoutConstraint.activate(activeConstraints)
        
        // Заставляем view рассчитать собственные размеры
        view.layoutIfNeeded()
        
        // Процесс ренедеринга представления - в рамках самого представления
        let graphicRenderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let image = graphicRenderer.image { context in
            view.layer.render(in: context.cgContext)
        }
        // Удаление представление с экрана
        view.removeFromSuperview()
        
        // Удаление примененных констрейнтов для записи снепшота
        view.removeConstraints(activeConstraints)
        
        return image
    }
    
    static func image(
        _ collectionView: UICollectionView,
        using context: SnapshotRendererContext.CollectionView
    ) -> UIImage {
        // Констрейнты, которые применяются в рамках записи
        var activeConstraints: [NSLayoutConstraint] = []
        
        // Рассчитываем оптимальный размер коллекции по её содержимому
        collectionView.frame.size = collectionView.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
        // Получаем точный размер содержимого
        let contentSize = collectionView.collectionViewLayout.collectionViewContentSize
        
        // Переопределение темы, в которой будет произведен рендер изображения
        context.window.overrideUserInterfaceStyle = context.interfaceStyle
        
        // Переопределение цвета `UIWindow`
        context.window.backgroundColor = context.backgroundColor
        
        // Добавление `View` на `UIWindow` для корректной отработки `layoutIfNeeded`
        context.window.addSubview(collectionView)
        
        // Выключаем ненужную функциональность во избежание конфликтующих констрейнтов
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Активация констрейнтов если размеры заданы в ручную
        activeConstraints.append(collectionView.heightAnchor.constraint(equalToConstant: contentSize.height))
        activeConstraints.append(collectionView.widthAnchor.constraint(equalToConstant: contentSize.width))
        
        NSLayoutConstraint.activate(activeConstraints)
        
        // Заставляем view рассчитать собственные размеры
        collectionView.layoutIfNeeded()
        
        // Процесс ренедеринга представления - в рамках самого представления
        let graphicRenderer = UIGraphicsImageRenderer(bounds: collectionView.bounds)
        let image = graphicRenderer.image { _ in
            collectionView.drawHierarchy(in: collectionView.bounds, afterScreenUpdates: true)
        }
        // Удаление представление с экрана
        collectionView.removeFromSuperview()
        
        // Удаление примененных констрейнтов
        collectionView.removeConstraints(activeConstraints)
        
        return image
    }
    
    /// Метод для отрисовки `ViewСontroller`-представления
    ///
    /// - Parameters:
    ///   - viewController: Представление для отрисовки.
    ///   - userInterfaceStyle: Тема приложения, в которой необходимо отрисовать представление.
    ///   - window: `UIWindow` экземпляр, предоставляющий контекст для отрисовки представления.
    ///   - ignoreSafeAreaInsets: Необходимо ли обрезать `safeArea` при рендеринге изображения (использовать с `AppHost`)
    ///
    /// - Warning: Метод размещает контроллер принудительно на все пространство `UIWindow`, предоставляемое устройством, на котором производится рендеринг
    ///
    /// - Returns: Рендер представления в качестве экземпляра `UIImage`
    static func image(
        _ viewController: UIViewController,
        using context: SnapshotRendererContext.ViewController
    ) throws -> UIImage {
        // Добавление `ViewController'a` на `UIWindow` для корректной отработки `layoutIfNeeded`
        guard let rootViewController = context.window.rootViewController else {
            throw SnapshotRendererError.unableToGetRootViewController
        }
        
        // Добавление тестируемого `ViewController`'a в качестве `child` для корректного жизненного цикла
        rootViewController.addChild(viewController)
        rootViewController.view.addSubview(viewController.view)
        viewController.view.frame = rootViewController.view.bounds
        viewController.didMove(toParent: rootViewController)
        
        // Переопределение темы, в которой будет произведен рендер изображения
        context.window.overrideUserInterfaceStyle = context.interfaceStyle
        
        // Переопределение цвета `UIWindow`
        context.window.backgroundColor = context.backgroundColor
        
        // Заставляем view рассчитать собственные размеры
        viewController.view.layoutIfNeeded()
        
        // Процесс рендеринга представления - в рамках всего экрана
        let renderedImage: UIImage = context.ignoreSafeArea
        ? renderContentView(viewController.view, in: context.window)
        : renderWindow(viewController.view, in: context.window)
        
        // Удаление представления с экрана
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.willMove(toParent: nil)
        
        return renderedImage
    }
    
    static func image(
        _ navigationViewController: UINavigationController,
        using context: SnapshotRendererContext.NavigationViewController
    ) throws -> UIImage {
        // Добавление `ViewController'a` на `UIWindow` для корректной отработки `layoutIfNeeded`
        guard let rootViewController = context.window.rootViewController else {
            throw SnapshotRendererError.unableToGetRootViewController
        }
        
        // Добавление тестируемого `ViewController`'a в качестве `child` для корректного жизненного цикла
        rootViewController.addChild(navigationViewController)
        rootViewController.view.addSubview(navigationViewController.view)
        navigationViewController.view.frame = rootViewController.view.bounds
        navigationViewController.didMove(toParent: rootViewController)
        
        // Переопределение темы, в которой будет произведен рендер изображения
        context.window.overrideUserInterfaceStyle = context.interfaceStyle
        
        // Переопределение цвета `UIWindow`
        context.window.backgroundColor = context.backgroundColor
        
        // Заставляем view рассчитать собственные размеры
        navigationViewController.view.layoutIfNeeded()
        
        // Процесс рендеринга представления - в рамках всего экрана
        let renderedImage = renderNavigationBar(navigationViewController.navigationBar)
        
        // Удаление представления с экрана
        navigationViewController.view.removeFromSuperview()
        navigationViewController.removeFromParent()
        navigationViewController.willMove(toParent: nil)
        
        return renderedImage
    }
    
    /// Метод отрисовки изображения для представления пиксельных различий в двух `UIImage`-представлениях
    ///
    /// - Parameters:
    ///   - originalImage: Оригинальное-изображение, с которым производится сравнение
    ///   - image: Новое изображение, которое сравнивается
    ///
    /// - Returns: `UIImage`-представление для иллюстрации различий между двумя `UIImage`-представлениями с помощью
    /// наложения их друг на друга и применения `difference blend-mode`'a
    static func difference(
        _ originalImage: UIImage,
        with image: UIImage
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
    
    // MARK: - Private

    @inline(__always)
    private static func renderContentView(
        _ view: UIView?,
        in window: UIWindow
    ) -> UIImage {
        
        let safeAreaInsets = window.safeAreaInsets
        let contentRect = window.bounds.inset(by: safeAreaInsets)
        
        let graphicRenderer = UIGraphicsImageRenderer(bounds: contentRect)
        return graphicRenderer.image { context in
            context.cgContext.translateBy(
                x: -safeAreaInsets.left,
                y: -safeAreaInsets.top
            )
            view?.layer.render(in: context.cgContext)
        }
    }
    
    @inline(__always)
    private static func renderWindow(
        _ view: UIView?,
        in window: UIWindow
    ) -> UIImage {
        
        let contentRect = window.bounds
        
        let graphicRenderer = UIGraphicsImageRenderer(bounds: contentRect)
        return graphicRenderer.image { context in
            view?.layer.render(in: context.cgContext)
        }
    }
    
    @inline(__always)
    private static func renderNavigationBar(
        _ navigationBar: UINavigationBar
    ) -> UIImage {
        let contentSize = navigationBar.bounds.size
        
        let graphicRenderer = UIGraphicsImageRenderer(size: contentSize)
        return graphicRenderer.image { context in
            navigationBar.layer.render(in: context.cgContext)
        }
    }
}

