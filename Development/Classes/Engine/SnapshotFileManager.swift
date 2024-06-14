//
//  SnapshotFileManager.swift
//  Meduza
//
//  Created by Samarenko Andrey on 12.06.2024.
//

import UIKit

// MARK: - Extensions

private extension String {
    // Main directory
    static let rootUnitTestsFolderName = "UnitTests"
    
    // Sub-directories
    static let referenceImagesFolderName = "ReferenceImages_64"
    static let failureDiffsFolderName = "FailureDiffs"
    
    // Default path extension
    static let png = "png"
}

private extension CharacterSet {
    
    /// Множество символов, которые не включаются в наименование файла снепшота
    static let invalidCharactersForFileName: CharacterSet = {
        let whiteSpacesSet = CharacterSet.whitespaces
        let punctuationSet = CharacterSet.punctuationCharacters
        
        return whiteSpacesSet.union(punctuationSet)
    }()
}

// MARK: - DTO

enum SnapshotType {
    /// Типы изобаржений при прохождении теста / записи снепшотов
    case reference          // записанное изображение
    
    /// Типы изображений при падении теста
    case failedReference    // изображение, с которым производится сравнение в тесте
    case failedTest         // изображение, полученное в результате теста
    case failedDiff         // разница между изображениями
}

// Мета-информация для формирования полного пути к снепшот-файлу
struct SnapshotTestCaseMetaInfo {
    // Дополнительный идентификатор тест-кейса
    let identifier: String?
    // Корневая директория проекта
    let rootPath: String
    // Тест-класс, в котором выполняется снэпшот-тестирование
    let testClass: AnyClass
    // Метод, который инициировал вызов assert'a
    let invocationSelector: Selector
    // Масштаб экрана
    let screenScale: CGFloat
    // Стиль интерфейса
    let interfaceStyle: UIUserInterfaceStyle
    // Максимальная допустимая разница в процентном соотношении ( на один пиксель )
    let pixelTolerance: CGFloat
    // Максимальная допустимая разница в процентном соотношении ( на bit-map представление )
    let overallTolerance: CGFloat
}

// MARK: - Errors

enum SnapshotFileManagerError: LocalizedError {
    
    case unableToCreatePNGData(filePath: String)
    case noRecordAvailable(filePath: String)
    case unableToLoadImage(filePath: String)
    case unknownUserInterfaceStyle
    
    var errorDescription: String? {
        
        let descriptionSummary: String
        switch self {
        case .unableToCreatePNGData(let filePath):
            descriptionSummary = "UIImage.pngData() function has returned error for path: \(filePath)."
        case .noRecordAvailable(let filePath):
            descriptionSummary = "No recorded snapshot found for path: \(filePath)."
        case .unableToLoadImage(let filePath):
            descriptionSummary = "UIImage(contentsOfFile:) function has returned error for path: \(filePath)."
        case .unknownUserInterfaceStyle:
            descriptionSummary = "Unknown UIUserInterfaceStyle."
        }
        
        return descriptionSummary.format(as: .executionError)
    }
}

// MARK: - Implementation

/// Статический класс без зависимостей для работы с файловой системой
final class SnapshotFileManager {
    
    // MARK: - Initialization

    // Экземпляр класса создавать нельзя
    private init() {}
    
    // MARK: - Internal
    
    static func load(
        for metaInfo: SnapshotTestCaseMetaInfo
    ) throws -> UIImage {
        let type = SnapshotType.reference
        
        let folderPath = folderPath(
            for: type,
            metaInfo.testClass,
            metaInfo.rootPath
        )
        
        let filePath = try filePath(
            for: folderPath,
            snapshotType: type,
            metaInfo: metaInfo
        )
        
        let filePathString = filePath.path
        guard FileManager.default.fileExists(atPath: filePathString) else {
            throw SnapshotFileManagerError.noRecordAvailable(filePath: filePathString)
        }
        
        guard let loadedImage = UIImage(contentsOfFile: filePathString) else {
            throw SnapshotFileManagerError.unableToLoadImage(filePath: filePathString)
        }
        
        return loadedImage
    }

    static func save(
        snapshot: UIImage,
        with type: SnapshotType,
        metaInfo: SnapshotTestCaseMetaInfo
    ) throws -> String {
        let folderPath = folderPath(
            for: type,
            metaInfo.testClass,
            metaInfo.rootPath
        )
        
        try FileManager.default.createDirectory(
            atPath: folderPath.path,
            withIntermediateDirectories: true
        )
        
        let filePath = try filePath(
            for: folderPath,
            snapshotType: type,
            metaInfo: metaInfo
        )
        
        guard let pngData = snapshot.pngData() else {
            throw SnapshotFileManagerError.unableToCreatePNGData(filePath: filePath.path)
        }
            
        try pngData.write(
            to: filePath,
            options: .atomic
        )
        
        return filePath.path
    }
    
    // MARK: - Private
    
    private static func filePath(
        for folderPath: URL,
        snapshotType: SnapshotType,
        metaInfo: SnapshotTestCaseMetaInfo
    ) throws -> URL {
        let fileName = try fileName(
            for: snapshotType,
            metaInfo.identifier,
            metaInfo.invocationSelector,
            metaInfo.screenScale,
            metaInfo.interfaceStyle
        )
        
        return folderPath
            .appendingPathComponent(fileName)
            .appendingPathExtension(.png)
    }
    
    /// Создание директории для snapshot-представления
    /// - Parameters:
    ///   - snapshotType: Тип snapshot'а для формирования директории
    /// - Returns:
    ///     - `<referenceImageDirectoryPath>/<class.type>` для записи снепшотов
    ///     - `<failureImageDirectoryPath>/<class.type>` для записи данных об упавших снепшотах
    private static func folderPath(
        for snapshotType: SnapshotType,
        _ testClass: AnyClass,
        _ projectPath: String
    ) -> URL {
        var projectDirectoryURL = URL(fileURLWithPath: projectPath)
            .appendingPathComponent(String.rootUnitTestsFolderName)
        
        switch snapshotType {
        case .reference:
            projectDirectoryURL
                .appendPathComponent(String.referenceImagesFolderName)
        case .failedReference,
             .failedTest,
             .failedDiff:
            projectDirectoryURL
                .appendPathComponent(String.failureDiffsFolderName)
        }
        
        let folderName = NSStringFromClass(testClass)
        
        return projectDirectoryURL.appendingPathComponent(folderName)
    }
    
    /// Создание наименования файла snapshot'a
    /// - Parameters:
    ///   - snapshotType: Тип snapshot'а для формирования префикса.
    /// - Returns: Наименование файла снепшота в формате `<snapshot_type>_<selector_name>_<theme>_<@scale>
    private static func fileName(
        for snapshotType: SnapshotType,
        _ identifier: String?,
        _ invocationSelector: Selector,
        _ screenScale: CGFloat,
        _ userInterfaceStyle: UIUserInterfaceStyle
    ) throws -> String {
        // Префикс файла в зависимости от типа снэпшота
        var rawFileName: String
        switch snapshotType {
        case .reference:       rawFileName = ""
        case .failedReference: rawFileName = "reference_"
        case .failedTest:      rawFileName = "test_"
        case .failedDiff:      rawFileName = "diff_"
        }
        
        // Наименование метода тест-кейса
        let methodName = invocationSelector.description
        rawFileName.append(methodName)
        
        if let identifier,
           !identifier.isEmpty {
            rawFileName.append("_")
            rawFileName.append(identifier)
        }
        
        // Наименование темы, в которой сделан снепшот
        let userInterfaceRawValue: String?
        switch userInterfaceStyle {
        case .light:
            userInterfaceRawValue = nil
        case .dark:
            userInterfaceRawValue = "dark"
        default:
            throw SnapshotFileManagerError.unknownUserInterfaceStyle
        }
        if let userInterfaceRawValue {
            rawFileName.append("_")
            rawFileName.append(userInterfaceRawValue)
        }
       
        // Удаление лишних знаков из названия файла
        var validatedFileName = rawFileName
            .components(separatedBy: CharacterSet.invalidCharactersForFileName)
            .joined(separator: "_")
        
        // Разрешение, в котором сделан снепшот
        let screenScaleSuffix = "@\(Int(screenScale))x"
        validatedFileName.append(screenScaleSuffix)
        
        return validatedFileName
    }
}
