//
//  SnapshotComparator.swift
//  Meduza
//
//  Created by Samarenko Andrey on 12.06.2024.
//

import CoreGraphics
import UIKit
import MetalKit
import Foundation

private extension String {
    static let comparisonFunctionName: String = "compareTextures"
}

private extension String {
    static let resourcesBundle = "SnapshotTestUtilsResources.bundle"
}

extension Bundle {

    public static let mobileBankUI = Bundle.resourcesBundle(for: ClassForBundle.self, resourcesBundle: .resourcesBundle)

    private class ClassForBundle {}
}

// MARK: - Implementation

/// Статический класс без зависимостей для сравнения снепшотов
final class SnapshotComparator {
    
    // MARK: - Initialization

    // Device-based GPU
    private static let device: MTLDevice = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Unable to create default device!")
        }
        return device
    }()
    // Device-based command-queue to interact with GPU
    private static let queue: MTLCommandQueue = {
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Unable to create command queue!")
        }
        return commandQueue
    }()
    // Device-based library for importing `.metal`-functions
    private static let library: MTLLibrary = {
        guard let library = try? device.makeDefaultLibrary(bundle: Bundle.mobileBankUI) else {
            fatalError("Unable to create default lib!")
        }
        
        return library
    }()
    // Computed Pipeline for comparing UIImages
    private static let pipelineState: MTLComputePipelineState = {
        guard let function = library.makeFunction(name: String.comparisonFunctionName) else {
            fatalError("Unable to create function \"pixelComparison\" for default library!")
        }
        guard let pipelineState = try? device.makeComputePipelineState(function: function) else {
            fatalError("Unable to create make compute pipeline state for function!")
        }
        
        return pipelineState
    }()
    
    private static func createTexture(from image: UIImage) -> MTLTexture? {
        guard let cgImage = image.cgImage else { return nil }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: cgImage.width,
            height: cgImage.height,
            mipmapped: false
        )
        
        textureDescriptor.usage = [
            .shaderRead,
            .shaderWrite
        ]
        
        let bytesPerPixel: Int = 4
        let bytesPerRow: Int = cgImage.width * bytesPerPixel
        let imageSizeBytes: Int = cgImage.height * bytesPerRow
         
        guard let ptrImageData = calloc(1, imageSizeBytes) else {
            fatalError("Unable to calloc image data")
        }
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).rawValue
        
        guard let imageColorSpace = cgImage.colorSpace else {
            fatalError("Can't create color space from UIImage")
        }
        
        func releaseDataCallback(
            info: UnsafeMutableRawPointer?,
            data: UnsafeMutableRawPointer?
        ) {
            free(info)
        }
        
        guard let referenceImageContext = CGContext(
            data: ptrImageData,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: imageColorSpace,
            bitmapInfo: bitmapInfo,
            releaseCallback: releaseDataCallback,
            releaseInfo: ptrImageData
        ) else {
            fatalError("Can't create image context for UIImage")
        }
        
        referenceImageContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))

        let region = MTLRegionMake2D(0, 0, cgImage.width, cgImage.height)
        
        let texture = device.makeTexture(descriptor: textureDescriptor)
        texture?.replace(
            region: region,
            mipmapLevel: 0,
            withBytes: ptrImageData,
            bytesPerRow: bytesPerRow
        )
        
        return texture
    }
    
    static func compare(
        _ lhs: UIImage,
        _ rhs: UIImage,
        perPixelTolerance: CGFloat,
        overallTolerance: CGFloat
    ) -> Bool {
        var perPixelTolerance: CGFloat = perPixelTolerance
        var numberOfFailedPixels: UInt32 = 0
    
        guard let lhsTexture = createTexture(from: lhs),
              let rhsTexture = createTexture(from: rhs)
        else {
            fatalError("Failed to create textures from UIImage")
        }
        
        guard let commandBuffer = queue.makeCommandBuffer() else {
            fatalError("Unable to create command buffer!")
        }
        
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Unable to create command encoder!")
        }
        
        commandEncoder.setComputePipelineState(pipelineState)
        // texture parameters
        commandEncoder.setTexture(lhsTexture, index: 0)
        commandEncoder.setTexture(rhsTexture, index: 1)
        
        // device parameters
        let failedPixelsBuffer = device.makeBuffer(
            bytes: &numberOfFailedPixels,
            length: MemoryLayout<UInt32>.size,
            options: .storageModeShared
        )
        commandEncoder.setBuffer(failedPixelsBuffer, offset: 0, index: 0)
        
        let perPixelToleranceBuffer = device.makeBuffer(
            bytes: &perPixelTolerance,
            length: MemoryLayout<Float>.size,
            options: .storageModeShared
        )
        commandEncoder.setBuffer(perPixelToleranceBuffer, offset: 0, index: 1)
        
        // calculate grid size
        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (lhsTexture.width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (lhsTexture.height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )
        commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        
        // commit actions
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let resultPointer = failedPixelsBuffer?.contents().bindMemory(to: UInt32.self, capacity: 1)
        guard let result = resultPointer?.pointee else {
            fatalError("No value for result!")
        }
        
        guard let cgImage = lhs.cgImage else {
            fatalError("Unable to create cgImage!")
        }
        
        let bytesPerPixel: Int = 4
        let bytesPerRow: Int = cgImage.width * bytesPerPixel
        let imageSizeBytes: Int = cgImage.height * bytesPerRow
        
        let failedPercent = CGFloat(result) / CGFloat(imageSizeBytes)
        
        return failedPercent <= overallTolerance
    }
}
