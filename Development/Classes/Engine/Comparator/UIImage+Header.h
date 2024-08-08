//
//  UIImage+Header.h
//  SnapshotTestUtils
//
//  Created by Samarenko Andrey on 15.07.2024.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Compare)

/**
 Compares the image against another given image.

 @param image The other image to compare against.
 @param perPixelTolerance How much (in percentage) any given pixel's colors are allowed to change from the pixel in the reference image.
 @param overallTolerance The overall percentage of pixels that are allowed to change from the pixels in the reference image.
 @return A BOOL which represents if the image is the same or not.
 */
- (BOOL)fb_compareWithImage:(UIImage *)image perPixelTolerance:(CGFloat)perPixelTolerance overallTolerance:(CGFloat)overallTolerance;

@end

NS_ASSUME_NONNULL_END
