//
//  UIImage+Utils.swift
//  WrinklesKiller
//
//  Created by Alex on 2/2/16.
//  Copyright © 2016 Alex. All rights reserved.
//

import UIKit
import AVFoundation
import GPUImage

extension UIImage {
    func copyImage() -> UIImage? {
        guard let cgImage = CGImageCreateCopy(self.CGImage) else {
            return nil
        }
        let resultImage = UIImage.init(CGImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
        return resultImage
    }
    
    func scaleImageToRect(toRect: CGRect) -> UIImage {
        let rect = AVMakeRectWithAspectRatioInsideRect(self.size, toRect)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1.0)
        drawInRect(rect)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    func combineImageWithImage(image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, true, 1.0)
        drawAtPoint(CGPointZero)
        image.drawAtPoint(CGPointZero)
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resultImage
    }
    
    func maskedImageWithMask(maskImage: UIImage) -> UIImage? {
        let maskImageRef = maskImage.CGImage
        let mask = CGImageMaskCreate(CGImageGetWidth(maskImageRef),
            CGImageGetHeight(maskImageRef),
            CGImageGetBitsPerComponent(maskImageRef),
            CGImageGetBitsPerPixel(maskImageRef),
            CGImageGetBytesPerRow(maskImageRef),
            CGImageGetDataProvider(maskImageRef), nil, false)
        let sourceImage = self.CGImage
        var maskedImage: CGImageRef
        let alpha = CGImageGetAlphaInfo(sourceImage)
        
        if alpha != .First && alpha != .Last && alpha != .PremultipliedFirst && alpha != .PremultipliedLast {
            let width = (CGImageGetWidth(sourceImage))
            let height = CGImageGetHeight(sourceImage)
            let offscreenContext = CGBitmapContextCreate(nil, width, height, 8, 0, CGImageGetColorSpace(sourceImage),
                CGBitmapInfo.ByteOrderDefault.rawValue)
            CGContextDrawImage(offscreenContext, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), sourceImage)
            let imageRefWithAlpha = CGBitmapContextCreateImage(offscreenContext)
            guard let unwrapedImage = CGImageCreateWithMask(imageRefWithAlpha, mask) else {
                return nil
            }
            maskedImage = unwrapedImage
        } else {
            guard let unwrapedImage = CGImageCreateWithMask(sourceImage, mask) else {
                return nil
            }
            maskedImage = unwrapedImage
        }
        return UIImage.init(CGImage: maskedImage)
    }
    
    func addGPUBlurOnImage() -> UIImage? {
        guard let copyImage = self.copyImage() else {
            return nil
        }
        let bilateralFilter = GPUImageBilateralFilter.init()
        bilateralFilter.distanceNormalizationFactor = 4
        
        let blendFilter = GPUImageDissolveBlendFilter.init()
        blendFilter.mix = 0.5
        bilateralFilter.addTarget(blendFilter, atTextureLocation: 1)
        
        let overlayPicture = GPUImagePicture.init(image: self)
        overlayPicture.addTarget(bilateralFilter)
        bilateralFilter.useNextFrameForImageCapture()
        overlayPicture.processImage()
        
        let originalPicture = GPUImagePicture.init(image: copyImage)
        originalPicture.addTarget(blendFilter, atTextureLocation: 0)
        blendFilter.useNextFrameForImageCapture()
        originalPicture.processImage()
        
        return blendFilter.imageFromCurrentFramebufferWithOrientation(self.imageOrientation)
    }
}
