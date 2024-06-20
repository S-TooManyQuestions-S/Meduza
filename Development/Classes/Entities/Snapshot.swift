//
//  Snapshot.swift
//  SnapshotTestUtils
//
//  Created by Samarenko Andrey on 18.06.2024.
//

import UIKit

struct SnapshotRenderContext {
    let interfaceStyle: UIUserInterfaceStyle
    let backgroundColor: UIColor
    let ignoreSafeArea: Bool
    
    // MARK: - Initialization
    
    init(
        interfaceStyle: UIUserInterfaceStyle,
        backgroundColor: UIColor,
        ignoreSafeArea: Bool = false
    ) {
        self.interfaceStyle = interfaceStyle
        self.backgroundColor = backgroundColor
        self.ignoreSafeArea = ignoreSafeArea
    }
}

protocol Snapshot {
        
    func setUp() throws
    
    func tearDown()
    
    func record(
        in renderContexts: [SnapshotRenderContext],
        using metaInfo: SnapshotMetaInfo
    ) throws
    
    func verify(
        in renderContexts: [SnapshotRenderContext],
        using metaInfo: SnapshotMetaInfo
    ) throws -> Bool
}
