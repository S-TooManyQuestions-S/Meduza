//
//  SnapshotComparator.swift
//  Meduza
//
//  Created by Samarenko Andrey on 12.06.2024.
//

import CoreGraphics
import UIKit

// MARK: - Errors

enum ImagesComparingError: LocalizedError {
    
    case unableToCreateCGImages
    case unableToExtractColorSpace
    case unableToCreateContexts
    case unableToBoundMemory
    case imagesOfDifferentSize(lhs: CGSize, rhs: CGSize)
    
    var errorDescription: String? {
        let descriptionSummary: String
        switch self {
        case .unableToCreateCGImages:
            descriptionSummary = "UIImage.cgImage property returned nil."
        case .unableToExtractColorSpace:
            descriptionSummary = "UIImage.colorSpace property returned nil."
        case .unableToCreateContexts:
            descriptionSummary = "Attempt to create CGContext from images meta-info has failed."
        case .unableToBoundMemory:
            descriptionSummary = "Attempt to bound memory to iterate over bitmap has failed."
        case .imagesOfDifferentSize(let lhs, let rhs):
            descriptionSummary = "Attempt to compare images of different size: {\(lhs.height); \(lhs.width)}, {\(rhs.height); \(rhs.width)}."
        }
       
        return descriptionSummary.format(as: .executionError)
    }
}

// MARK: - Implementation

/// Статический класс без зависимостей для сравнения снепшотов
final class SnapshotComparator {
    
    // MARK: - Initialization
    // Экземпляр класса создавать нельзя
    private init() {}

    // MARK: - Internal

    @inline(__always)
    static func compare(
        _ referenceImage: UIImage,
        with actualImage: UIImage,
        pixelTolerance: CGFloat,
        overallTolerance: CGFloat
    ) throws -> Bool {
        guard let referenceCGImage = referenceImage.cgImage,
              let actualCGImage = actualImage.cgImage
        else { throw ImagesComparingError.unableToCreateCGImages }
        
        // Работа осуществляется с картинками одного размера
        guard assertSize(referenceCGImage, actualCGImage) else {
            throw ImagesComparingError.imagesOfDifferentSize(lhs: referenceImage.size, rhs: actualImage.size)
        }
        
        // Берем минимум, чтобы лишний раз обезопасить себя от выхода за пределы памяти, выделенной
        // для строки в bitmap-представлении изображения
        let minBytesPerRow: size_t = min(
            referenceCGImage.bytesPerRow,
            actualCGImage.bytesPerRow
        )
        
        // Получаем количество памяти, необходимое для bitmap-представления изображения путем
        // перемножения памяти, требуемой для одной строки bitmap-представления на количество этих строк, т.е. `height`
        let imageSizeBytes: size_t = referenceCGImage.height * minBytesPerRow
        
        // Процесс ручного выделения памяти для последующей итерации по bit-map представлению изображения
        let ptrReferenceImagePixels = calloc(1, imageSizeBytes)
        let ptrActualImagePixels = calloc(1, imageSizeBytes)
        
        // Подготовка контекстов для рендеринга изображений и итерации по bit-map представлений
        guard
            let referenceCGImageColorSpace = referenceCGImage.colorSpace,
            let actualCGImageColorSpace = actualCGImage.colorSpace
        else { throw ImagesComparingError.unableToExtractColorSpace }
        
        // Функция для releaseCallBack'a контекста - необходимости принудительно освобождать контекст при использовании ARC нет
        func releaseDataCallback(
            info: UnsafeMutableRawPointer?,
            data: UnsafeMutableRawPointer?
        ) {
            free(info)
        }
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).rawValue
        
        // создание контекстов для наполнения bit-map представлений на основе CGImage
        
        guard
            let referenceImageContext = CGContext(
                data: ptrReferenceImagePixels,
                width: referenceCGImage.width,
                height: referenceCGImage.height,
                bitsPerComponent: referenceCGImage.bitsPerComponent,
                bytesPerRow: minBytesPerRow,
                space: referenceCGImageColorSpace,
                bitmapInfo: bitmapInfo,
                releaseCallback: releaseDataCallback,
                releaseInfo: ptrReferenceImagePixels
            ),
            let actualImageContext = CGContext(
                data: ptrActualImagePixels,
                width: actualCGImage.width,
                height: actualCGImage.height,
                bitsPerComponent: actualCGImage.bitsPerComponent,
                bytesPerRow: minBytesPerRow,
                space: actualCGImageColorSpace,
                bitmapInfo: bitmapInfo,
                releaseCallback: releaseDataCallback,
                releaseInfo: ptrActualImagePixels
            )
        else { throw ImagesComparingError.unableToCreateContexts }
        
        referenceImageContext.draw(referenceCGImage, in: CGRect(x: 0, y: 0, width: referenceCGImage.width, height: referenceCGImage.height))
        actualImageContext.draw(actualCGImage, in: CGRect(x: 0, y: 0, width: actualCGImage.width, height: actualCGImage.height))
        
        // Для удобства интерпертируем указатели как структуру в 1 байт ( capacity )
        guard
            let ptr_referenceImage = ptrReferenceImagePixels?.bindMemory(to: UInt8.self, capacity: 1),
            let ptr_actualimage = ptrActualImagePixels?.bindMemory(to: UInt8.self, capacity: 1)
        else { throw ImagesComparingError.unableToBoundMemory }
        
        let pixelCount: Int = referenceCGImage.height * referenceCGImage.width
        
        return comparePixels(
            ptr_referenceImage,
            ptr_actualimage,
            pixelCount: pixelCount,
            pixelTolerance: pixelTolerance,
            overallTolerance: overallTolerance
        )
    }
    
    // MARK: - Private
    
    @inline(__always)
    private static func comparePixels(
        _ lhs: UnsafeMutablePointer<UInt8>,
        _ rhs: UnsafeMutablePointer<UInt8>,
        pixelCount: Int,
        pixelTolerance: CGFloat,
        overallTolerance: CGFloat
    ) -> Bool {
        
        var lhsPtr = lhs
        var rhsPtr = rhs
        
        var numberOfDifferentPixels: UInt64 = 0
        let totalPixels = CGFloat(pixelCount)
        
        let maxDifferentPixels = UInt64(overallTolerance * totalPixels)
        
        for _ in 0..<pixelCount {
            if !isEqual(lhsPtr, rhsPtr, pixelTolerance: pixelTolerance) {
                numberOfDifferentPixels += 1
                
                if numberOfDifferentPixels > maxDifferentPixels {
                    return false
                }
            }
            
            lhsPtr += 4
            rhsPtr += 4
        }
        
        return true
    }
    
    @inline(__always)
    private static func isEqual(
        _ lhs: UnsafeMutablePointer<UInt8>,
        _ rhs: UnsafeMutablePointer<UInt8>,
        pixelTolerance: CGFloat
    ) -> Bool {
        
        // red channel
        if difference(between: lhs.pointee, and: rhs.pointee) > pixelTolerance { return false }
        // green channel
        if difference(between: lhs.advanced(by: 1).pointee, and: rhs.advanced(by: 1).pointee) > pixelTolerance { return false }
        // blue channel
        if difference(between: lhs.advanced(by: 2).pointee, and: rhs.advanced(by: 2).pointee) > pixelTolerance { return false }
        // alpha channel
        if difference(between: lhs.advanced(by: 3).pointee, and: rhs.advanced(by: 3).pointee) > pixelTolerance { return false }
        
        return true
    }
    
    @inline(__always)
    private static func difference(
        between lhs: UInt8,
        and rhs: UInt8
    ) -> CGFloat {
        if lhs >= rhs {
            return CGFloat(lhs - rhs) / 256
        } else {
            return CGFloat(rhs - lhs) / 256
        }
    }
    
    @inline(__always)
    private static func assertSize(_ lhs: CGImage, _ rhs: CGImage) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }
}

