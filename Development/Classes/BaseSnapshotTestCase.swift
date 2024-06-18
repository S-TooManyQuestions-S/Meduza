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
    case ranInRecordMode
    case comparisonError
    
    var errorDescription: String? {
        switch self {
        case .keyWindowNotFound:
            return String("`UIApplication.shared.windows.first` not found.")
                .format(as: .executionError)
        case .ranInRecordMode:
            return String("Test ran in record mode. Image is now saved.")
                .format(as: .recordModeError)
        case .comparisonError:
            return String("Images are different.")
                .format(as: .comparisonError)
        }
    }
}

open class BaseSnapshotTestCase: XCTestCase {
    
    // Dependencies
    private var metaInfoProvider: MetaInfoProvider!
    
    // Private
    private var window: UIWindow {
        if let appHostWindow = UIApplication.shared.windows.first {
            SnapshotLogger.log(message: "AppHost window found!", .info)
            return appHostWindow
        } else {
            SnapshotLogger.log(message: "AppHost window not found. New UIWindow instance will be used!", .warning)
            return UIWindow()
        }
    }
    
    // State
    open var recordMode: Bool = false
    
    // MARK: - XCTestCase
    
    open override func setUp() {
        super.setUp()
        
        metaInfoProvider = MetaInfoProvider(for: self)
    }
    
    open override func tearDown() {
        metaInfoProvider = nil

        super.tearDown()
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
            // given
            let metaInfo = try metaInfoProvider.makeMetaInfo(
                identifier: identifier,
                pixelTolerance: pixelToleracne,
                overallTolerance: overallTolerance,
                screenScale: window.screen.scale
            )
            
            let snapshot = ViewControllerSnapshot(with: viewController, in: window)
            let contexts = interfaceStyles.map { SnapshotRenderContext(interfaceStyle: $0, backgroundColor: backgroundColor, ignoreSafeArea: ignoreSafeArea) }
            
            try verify(snapshot, in: contexts, using: metaInfo)
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
        widthStrategy: WidthResolutionStrategy = .none,
        backgroundColor: UIColor,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            // given
            let metaInfo = try metaInfoProvider.makeMetaInfo(
                identifier: identifier,
                pixelTolerance: pixelToleracne,
                overallTolerance: overallTolerance,
                screenScale: window.screen.scale
            )
            let constraintContext = SnapshotConstraintContext(height: height, widthResolution: widthStrategy)
            
            let snapshot = ViewSnapshot(with: view, in: window, using: constraintContext)
            let contexts = interfaceStyles.map { SnapshotRenderContext(interfaceStyle: $0, backgroundColor: backgroundColor) }
            
            try verify(snapshot, in: contexts, using: metaInfo)
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
            // given
            let metaInfo = try metaInfoProvider.makeMetaInfo(
                identifier: identifier,
                pixelTolerance: pixelToleracne,
                overallTolerance: overallTolerance,
                screenScale: window.screen.scale
            )
            
            let snapshot = CollectionViewSnapshot(with: collectionView, in: window)
            let contexts = interfaceStyles.map { SnapshotRenderContext(interfaceStyle: $0, backgroundColor: backgroundColor) }
            
            try verify(snapshot, in: contexts, using: metaInfo)
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
            // given
            let metaInfo = try metaInfoProvider.makeMetaInfo(
                identifier: identifier,
                pixelTolerance: pixelToleracne,
                overallTolerance: overallTolerance,
                screenScale: window.screen.scale
            )
            
            let snapshot = NavigationBarSnapshot(with: navigationViewController, in: window)
            let contexts = interfaceStyles.map { SnapshotRenderContext(interfaceStyle: $0, backgroundColor: backgroundColor) }
            
            try verify(snapshot, in: contexts, using: metaInfo)
        } catch {
            XCTFail(error.localizedDescription, file: file, line: line)
        }
    }
    
    // MARK: - Private
    
    private func verify(
        _ snapshot: Snapshot,
        in contexts: [SnapshotRenderContext],
        using metaInfo: SnapshotMetaInfo
    ) throws {
        try snapshot.setUp()
        defer { snapshot.tearDown() }
        
        if recordMode {
            try snapshot.record(in: contexts, using: metaInfo)
            throw SnapshotBaseError.ranInRecordMode
        } else {
            guard try snapshot.verify(in: contexts, using: metaInfo) else {
                throw SnapshotBaseError.comparisonError
            }
        }
    }
}
