//
//  MetaInfoProvider.swift
//  SnapshotTestUtils
//
//  Created by Samarenko Andrey on 18.06.2024.
//

import Foundation
import XCTest

// Мета-информация
struct SnapshotMetaInfo {
    // Дополнительный идентификатор тест-кейса
    let identifier: String?
    // Корневая директория проекта
    let rootPath: String
    // Тест-класс, в котором выполняется снэпшот-тестирование
    let testClass: AnyClass
    // Метод, который инициировал вызов assert'a ( описание )
    let selectorDescription: String
    // Масштаб экрана
    let screenScale: CGFloat
    // Максимальная допустимая разница в процентном соотношении ( на один пиксель )
    let pixelTolerance: CGFloat
    // Максимальная допустимая разница в процентном соотношении ( на bit-map представление )
    let overallTolerance: CGFloat
}

enum SnapshotMetaInfoProviderError: LocalizedError {
    
    case sourceRootNotFound
    case invocationSelectorNotFound
    case testClassIsNil
    
    var errorDescription: String? {
        switch self {
        case .sourceRootNotFound:
            return String("`SOURCE_ROOT`-key not found in environment variables of your test-scheme.")
                .format(as: .executionError)
        case .invocationSelectorNotFound:
            return String("Variable `<test_class>.invocation.selector` getter returned nil.")
                .format(as: .executionError)
        case .testClassIsNil:
            return String("Variable `<test_class>` is nil.")
        }
    }
}

final class MetaInfoProvider {
    
    // Private
    private weak var testCaseClass: BaseSnapshotTestCase?
    
    // MARK: - Initialization

    init(
        for testCaseClass: BaseSnapshotTestCase
    ) {
        self.testCaseClass = testCaseClass
    }
    
    // MARK: - Internal
    
    func makeMetaInfo(
        identifier: String?,
        pixelTolerance: CGFloat,
        overallTolerance: CGFloat,
        screenScale: CGFloat
    ) throws -> SnapshotMetaInfo {
        
        let rootPath = try makeRootPath()
        let testClass: AnyClass = try makeTestClass()
        let selectorDescription = try makeSelectorDescription()
        
        return SnapshotMetaInfo(
            identifier: identifier,
            rootPath: rootPath,
            testClass: testClass,
            selectorDescription: selectorDescription,
            screenScale: screenScale,
            pixelTolerance: pixelTolerance,
            overallTolerance: overallTolerance
        )
    }
    
    // MARK: - Private
    
    private func makeRootPath() throws -> String {
        if let rootPath = ProcessInfo.processInfo.environment["SOURCE_ROOT"] {
            return rootPath
        } else {
            throw SnapshotMetaInfoProviderError.sourceRootNotFound
        }
    }
    
    private func makeSelectorDescription() throws -> String {
        if let selector = testCaseClass?.invocation?.selector {
            return selector.description
        } else {
            throw SnapshotMetaInfoProviderError.invocationSelectorNotFound
        }
    }
    
    private func makeTestClass() throws -> AnyClass {
        if let testCaseClass {
            return testCaseClass.classForCoder
        } else {
            throw SnapshotMetaInfoProviderError.testClassIsNil
        }
    }
}
