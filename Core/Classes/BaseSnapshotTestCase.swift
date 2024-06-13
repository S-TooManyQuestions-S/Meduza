//
//  BaseSnapshotTestCase.swift
//  Meduza
//
//  Created by Samarenko Andrey on 12.06.2024.
//

import UIKit
import Foundation
import XCTest

enum SnapshotBaseError: LocalizedError {
    
    case keyWindowNotFound
    case sourceRootNotFound
    case invocationSelectorNotFound
    case ranInRecordMode(recordedPath: String)
    case comparisonError
    
    var errorDescription: String? {
        switch self {
        case .keyWindowNotFound:
            return String("`UIApplication.shared.windows.first` not found.")
                .format(as: .executionError)
        case .sourceRootNotFound:
            return String("`SOURCE_ROOT`-key not found in environment variables of your test-scheme.")
                .format(as: .executionError)
        case .invocationSelectorNotFound:
            return String("Variable `self.invocation.selector` getter returned nil.")
                .format(as: .executionError)
        case .ranInRecordMode(let recordedPath):
            return String("Test ran in record mode. Image is now saved via path:\n\(recordedPath).")
                .format(as: .recordModeError)
        case .comparisonError:
            return String("Images are different.")
                .format(as: .comparisonError)
        }
    }
}

public enum WidthResolutionStrategy {
    case aspectFit(value: CGFloat)
    case aspectFill(value: CGFloat)
}

open class BaseSnapshotTestCase: XCTestCase {
    
    // State
    open var recordMode: Bool = false
    
    // Window
    func window() throws -> UIWindow {
        guard let window = UIApplication.shared.windows.first else {
            throw SnapshotBaseError.keyWindowNotFound
        }
        return window
    }
    
    // MARK: - XCTestCase
    
    open override func tearDownWithError() throws {
        try window().rootViewController = UIViewController()
    }
    
    // MARK: - Public API
    
    open func verifyViewController(
        _ viewController: UIViewController,
        identifier: String? = nil,
        pixelToleracne: CGFloat,
        overallTolerance: CGFloat,
        interfaceStyles: Set<UIUserInterfaceStyle>,
        backgroundColor: UIColor,
        ignoreSafeArea: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            for interfaceStyle in interfaceStyles {
                let metaInfo = try metaInfo(
                    identifier: identifier,
                    with: interfaceStyle,
                    pixelTolerance: pixelToleracne,
                    overallTolerance: overallTolerance
                )
                
                let window = try window()
                let context = SnapshotRendererContext.ViewController(
                    interfaceStyle: interfaceStyle,
                    backgroundColor: backgroundColor,
                    ignoreSafeArea: ignoreSafeArea,
                    window: window
                )
                
                if recordMode {
                    try record(viewController, renderContext: context, using: metaInfo)
                } else {
                    try verify(viewController, renderContext: context, using: metaInfo)
                }
            }
        } catch {
            XCTFail(error.localizedDescription, file: file, line: line)
        }
    }
    
    
    open func verifyView(
        _ view: UIView,
        identifier: String? = nil,
        pixelToleracne: CGFloat,
        overallTolerance: CGFloat,
        interfaceStyles: Set<UIUserInterfaceStyle>,
        height: CGFloat? = nil,
        widthStrategy: WidthResolutionStrategy? = nil,
        backgroundColor: UIColor,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            for interfaceStyle in interfaceStyles {
                let metaInfo = try metaInfo(
                    identifier: identifier,
                    with: interfaceStyle,
                    pixelTolerance: pixelToleracne,
                    overallTolerance: overallTolerance
                )
                
                let window = try window()
                let context = SnapshotRendererContext.View(
                    interfaceStyle: interfaceStyle,
                    height: height,
                    widthResolutionStrategy: widthStrategy,
                    backgroundColor: backgroundColor,
                    window: window
                )
                
                if recordMode {
                    try record(view, renderContext: context, using: metaInfo)
                } else {
                    try verify(view, renderContext: context, using: metaInfo)
                }
            }
        } catch {
            XCTFail(error.localizedDescription, file: file, line: line)
        }
    }
    
    open func verifyCollectionView(
        _ collectionView: UICollectionView,
        identifier: String? = nil,
        pixelToleracne: CGFloat,
        overallTolerance: CGFloat,
        interfaceStyles: Set<UIUserInterfaceStyle>,
        backgroundColor: UIColor,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            for interfaceStyle in interfaceStyles {
                let metaInfo = try metaInfo(
                    identifier: identifier,
                    with: interfaceStyle,
                    pixelTolerance: pixelToleracne,
                    overallTolerance: overallTolerance
                )
                
                let window = try window()
                let context = SnapshotRendererContext.CollectionView(
                    interfaceStyle: interfaceStyle,
                    backgroundColor: backgroundColor,
                    window: window
                )
                
                if recordMode {
                    try record(collectionView, renderContext: context, using: metaInfo)
                } else {
                    try verify(collectionView, renderContext: context, using: metaInfo)
                }
            }
        } catch {
            XCTFail(error.localizedDescription, file: file, line: line)
        }
    }
    
    open func verifyNavigationBar(
        _ navigationViewController: UINavigationController,
        identifier: String? = nil,
        pixelToleracne: CGFloat,
        overallTolerance: CGFloat,
        interfaceStyles: Set<UIUserInterfaceStyle>,
        backgroundColor: UIColor,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            for interfaceStyle in interfaceStyles {
                let metaInfo = try metaInfo(
                    identifier: identifier,
                    with: interfaceStyle,
                    pixelTolerance: pixelToleracne,
                    overallTolerance: overallTolerance
                )
                
                let window = try window()
                let context = SnapshotRendererContext.NavigationViewController(
                    interfaceStyle: interfaceStyle,
                    backgroundColor: backgroundColor,
                    window: window
                )
                
                if recordMode {
                    try record(navigationViewController, renderContext: context, using: metaInfo)
                } else {
                    try verify(navigationViewController, renderContext: context, using: metaInfo)
                }
            }
        } catch {
            XCTFail(error.localizedDescription, file: file, line: line)
        }
    }
    
}

// MARK: - Private

private extension BaseSnapshotTestCase {

    func metaInfo(
        identifier: String?,
        with interfaceStyle: UIUserInterfaceStyle,
        pixelTolerance: CGFloat,
        overallTolerance: CGFloat
    ) throws -> SnapshotTestCaseMetaInfo {
        guard let rootPath = ProcessInfo.processInfo.environment["SOURCE_ROOT"] else {
            throw SnapshotBaseError.sourceRootNotFound
        }
        
        let testClass: AnyClass = self.classForCoder
        
        guard let invocationSelector = self.invocation?.selector else {
            throw SnapshotBaseError.invocationSelectorNotFound
        }

        let screenScale = try window().screen.scale
        
        return SnapshotTestCaseMetaInfo(
            identifier: identifier,
            rootPath: rootPath,
            testClass: testClass,
            invocationSelector: invocationSelector,
            screenScale: screenScale,
            interfaceStyle: interfaceStyle,
            pixelTolerance: pixelTolerance,
            overallTolerance: overallTolerance
        )
    }
}


