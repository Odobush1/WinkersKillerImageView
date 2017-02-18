import AVFoundation
import GPUImage

extension UIImage {
    private func copyImage() -> UIImage? {
        guard let cgImage = cgImage?.copy() else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
    
    func scaleImage(toRect rect: CGRect) -> UIImage? {
        let ratioRect = AVMakeRect(aspectRatio: size, insideRect: rect)
        UIGraphicsBeginImageContextWithOptions(ratioRect.size, false, 1)
        draw(in: ratioRect)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    func combineImage(withImage image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, true, 1)
        draw(at: CGPoint.zero)
        image.draw(at: CGPoint.zero)
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resultImage
    }
    
    func maskedImage(withMask maskImage: UIImage) -> UIImage? {
        guard let maskImageRef = maskImage.cgImage,
            let sourceImage = cgImage,
            let colorSpace = sourceImage.colorSpace,
            let dataProvider = maskImageRef.dataProvider,
            let mask = CGImage(maskWidth: maskImageRef.width,
                               height: maskImageRef.height,
                               bitsPerComponent: maskImageRef.bitsPerComponent,
                               bitsPerPixel: maskImageRef.bitsPerPixel,
                               bytesPerRow: maskImageRef.bytesPerRow,
                               provider: dataProvider,
                               decode: nil,
                               shouldInterpolate: false) else {
                return nil
        }
        
        let alpha = sourceImage.alphaInfo
        if alpha != .first && alpha != .last && alpha != .premultipliedFirst && alpha != .premultipliedLast {
            let width = sourceImage.width
            let height = sourceImage.height
            let offscreenContext = CGContext(data: nil,
                                             width: width,
                                             height: height,
                                             bitsPerComponent: 8,
                                             bytesPerRow: 0,
                                             space: colorSpace,
                                             bitmapInfo: CGBitmapInfo().rawValue)
            offscreenContext?.draw(sourceImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            let imageRefWithAlpha = offscreenContext?.makeImage()
            guard let unwrapedImage = imageRefWithAlpha?.masking(mask) else { return nil }
            return UIImage(cgImage: unwrapedImage)
        }
        guard let unwrapedImage = sourceImage.masking(mask) else { return nil }
        return UIImage(cgImage: unwrapedImage)
    }
    
    func addGPUBlur() -> UIImage? {
        guard let copyImage = self.copyImage() else { return nil }
        let bilateralFilter = GPUImageBilateralFilter()
        bilateralFilter.distanceNormalizationFactor = 4
        
        let blendFilter = GPUImageDissolveBlendFilter()
        blendFilter.mix = 0.5
        bilateralFilter.addTarget(blendFilter, atTextureLocation: 1)
        
        let overlayPicture = GPUImagePicture(image: self)
        overlayPicture?.addTarget(bilateralFilter)
        bilateralFilter.useNextFrameForImageCapture()
        overlayPicture?.processImage()
        
        let originalPicture = GPUImagePicture(image: copyImage)
        originalPicture?.addTarget(blendFilter, atTextureLocation: 0)
        blendFilter.useNextFrameForImageCapture()
        originalPicture?.processImage()
        
        return blendFilter.imageFromCurrentFramebuffer(with: imageOrientation)
    }
}
