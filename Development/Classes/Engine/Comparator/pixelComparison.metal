//
//  pixelComparison.metal
//  SnapshotTestUtils
//
//  Created by Samarenko Andrey on 31.07.2024.
//

#include <metal_stdlib>
using namespace metal;

kernel void compareTextures(
    texture2d<float, access::read> texture1 [[texture(0)]],
    texture2d<float, access::read> texture2 [[texture(1)]],
    volatile device atomic_uint &failedPixels [[buffer(0)]],
    // Константы для сравнения
    constant float &tolerance [[buffer(1)]],
    // Координаты пикселя a.k.a. номер потока
    uint2 gid [[thread_position_in_grid]]
) {
    // Ensure the comparison stays within the texture bounds
    if (gid.x >= texture1.get_width() || gid.y >= texture1.get_height()) {
        return;
    }

    // Read color from both textures
    float4 color1 = texture1.read(gid);
    float4 color2 = texture2.read(gid);

    // Compute the absolute difference
    float4 diff = abs(color1 - color2);
    
    // Compare against tolerance
    if (any(diff > tolerance)) {
        atomic_fetch_add_explicit(&failedPixels, 1, memory_order_relaxed);
    }
}
