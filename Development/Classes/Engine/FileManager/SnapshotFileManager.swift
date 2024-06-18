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

// MARK: - Implementation

/// Статический класс без зависимостей для работы с файловой системой
final class SnapshotFileManager {
    
    // MARK: - Initialization

    // Экземпляр класса создавать нельзя
    private init() {}
    
    // MARK: - Internal
    
    static func load(
        for metaInfo: SnapshotMetaInfo,
        _ renderContext: SnapshotRenderContext
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
            metaInfo: metaInfo,
            renderContext: renderContext
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
        _ renderContext: SnapshotRenderContext,
        _ metaInfo: SnapshotMetaInfo
    ) throws {
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
            metaInfo: metaInfo,
            renderContext: renderContext
        )
        
        guard let pngData = snapshot.pngData() else {
            throw SnapshotFileManagerError.unableToCreatePNGData(filePath: filePath.path)
        }
            
        try pngData.write(
            to: filePath,
            options: .atomic
        )
        
        SnapshotLogger.log(message: "Snapshot successfully saved! Path: \(filePath.path)", .info)
    }
    
    // MARK: - Private
    
    private static func filePath(
        for folderPath: URL,
        snapshotType: SnapshotType,
        metaInfo: SnapshotMetaInfo,
        renderContext: SnapshotRenderContext
    ) throws -> URL {
        let fileName = try fileName(
            for: snapshotType,
            metaInfo.identifier,
            metaInfo.selectorDescription,
            metaInfo.screenScale,
            renderContext.interfaceStyle
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
        _ invocationSelectorDescription: String,
        _ screenScale: CGFloat,
        _ userInferfaceStyle: UIUserInterfaceStyle
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
        rawFileName.append(invocationSelectorDescription)
        
        if let identifier,
           !identifier.isEmpty {
            rawFileName.append("_")
            rawFileName.append(identifier)
        }
        
        // Наименование темы, в которой сделан снепшот
        let userInterfaceRawValue: String?
        switch userInferfaceStyle {
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
