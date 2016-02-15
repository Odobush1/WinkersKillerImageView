//
//  ODImproveFaceImageView.swift
//  WrinklesKiller
//
//  Created by Alex on 2/2/16.
//  Copyright © 2016 Alex. All rights reserved.
//

import UIKit

final class ODImproveFaceImageView: UIImageView {
    private var originalImage: UIImage?
    private var processedImage: UIImage?
    
    lazy private var activityIndicator: UIActivityIndicatorView? = {
        let activity = UIActivityIndicatorView.init(activityIndicatorStyle: .WhiteLarge)
        activity.frame = CGRectMake(0, 0, 30, 30)
        activity.center = self.center
        self.addSubview(activity)
        return activity
    }()
    
    func setOriginalImage(image: UIImage) {
        prepareImageForHandling(image)
    }
    
    func showHandledImage() {
        guard let bluredImage = processedImage else {
            handleImage()
            return
        }
        image = bluredImage
    }
    
    func showOriginalImage() {
        image = originalImage
    }
    
    func cleanImageView() {
        originalImage = nil
        processedImage = nil
    }
}

private extension ODImproveFaceImageView {
    func handleImage() {
        guard let workImage = image else {
            return
        }
        activityIndicator?.startAnimating()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            guard let mask = self.detectFace(workImage) else {
                self.stopAnimatingOnMainQueue()
                return
            }
            guard let bluredImage = workImage.addGPUBlurOnImage() else {
                self.stopAnimatingOnMainQueue()
                return
            }
            guard let maskedImage = bluredImage.maskedImageWithMask(mask) else {
                self.stopAnimatingOnMainQueue()
                return
            }
            let scaledPhoto = maskedImage.scaleImageToRect(self.bounds)
            guard let original = self.originalImage else {
                self.stopAnimatingOnMainQueue()
                return
            }
            self.processedImage = original.combineImageWithImage(scaledPhoto)
        
            dispatch_async(dispatch_get_main_queue(), {
                self.stopAnimatingOnMainQueue()
                self.image = self.processedImage
            })
         })
    }
    
    func detectFace(undetectedImage: UIImage) -> UIImage? {
        guard let workImage = CIImage.init(image: undetectedImage) else {
            return nil
        }
        let context = CIContext.init(options: [kCIContextUseSoftwareRenderer : true])
        let detector = CIDetector.init(ofType: CIDetectorTypeFace, context: context, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
        let features = detector.featuresInImage(workImage)
        UIGraphicsBeginImageContextWithOptions(undetectedImage.size, false, 1)
        let contextReference = UIGraphicsGetCurrentContext()
        CGContextTranslateCTM(contextReference, 0, undetectedImage.size.height)
        CGContextScaleCTM(contextReference, 1, -1)
        CGContextSaveGState(contextReference)
        CGContextSetRGBFillColor(contextReference, 1, 0, 1, 1)
        CGContextFillRect(contextReference, CGRectMake(0, 0, undetectedImage.size.width , undetectedImage.size.height))
        CGContextRestoreGState(contextReference)
        
        //FIXME: Make for
        if (features.count == 1) {
            guard let feature = features[0] as? CIFaceFeature else {
                return nil
            }
            guard let reference = contextReference else {
                return nil
            }
            guard let resultImage = self.proccesFeature(feature, contextReference: reference) else {
                return nil
            }
            return resultImage
        }
        return nil
    }
    
    func proccesFeature(feature: CIFaceFeature, contextReference: CGContext) -> UIImage? {
        if !feature.hasLeftEyePosition || !feature.hasRightEyePosition || !feature.hasMouthPosition {
            return nil
        }
        
        CGContextSetRGBFillColor(contextReference, 0, 0, 0, 1)
        let betweenEyesPoint = feature.leftEyePosition.pointBetweenPoint(feature.rightEyePosition)
        let distanceBetweenEyes = feature.leftEyePosition.distanceToPoint(feature.rightEyePosition)
        let radius = distanceBetweenEyes / 2
        let distanceToNose = betweenEyesPoint.distanceToPoint(feature.mouthPosition)
        let faceWidth = radius * 2 + radius * 2 + radius
        let elipsX = betweenEyesPoint.x - (radius * 2) - (radius / 2)
        let elipsY = betweenEyesPoint.y - distanceToNose - (radius * 2)
        let elipsHeight = (distanceToNose * 2) + (radius * 2) + (radius / 2)
        let rectEllipse = CGRectMake(elipsX, elipsY, faceWidth, elipsHeight)
        
        CGContextSaveGState(contextReference)
        
        let angle = faceRotationOfFeature(feature)
        let flowerPetal = CGPathCreateMutable()
        let midleX = CGRectGetMidX(rectEllipse)
        let midleY = CGRectGetMidY(rectEllipse)
        var transform = CGAffineTransformConcat(CGAffineTransformConcat(CGAffineTransformMakeTranslation(-midleX, -midleY),CGAffineTransformMakeRotation(angle)), CGAffineTransformMakeTranslation(midleX, midleY))
        
        CGPathAddEllipseInRect(flowerPetal, &transform, rectEllipse)
        CGContextAddPath(contextReference, flowerPetal)
        CGContextFillPath(contextReference)
        CGContextRestoreGState(contextReference)
    
        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return maskedImage
    }

    func faceRotationOfFeature(feature: CIFaceFeature) -> CGFloat {
        let pointX = (feature.rightEyePosition.x + feature.leftEyePosition.x) / 2
        let pointY = (feature.rightEyePosition.y + feature.leftEyePosition.y) / 2
        let betweenEyesMidPoint = CGPointMake(pointX, pointY)
        let originEndPoint = CGPointMake(feature.mouthPosition.x, betweenEyesMidPoint.y)
        let angle1 = atan2f(Float(feature.mouthPosition.y - betweenEyesMidPoint.y), Float(feature.mouthPosition.x - betweenEyesMidPoint.x))
        let angle2 = atan2f(Float(feature.mouthPosition.y - originEndPoint.y), Float(feature.mouthPosition.x - originEndPoint.x))
        return CGFloat(angle1 - angle2)
    }
    
    func prepareImageForHandling(image: UIImage) {
        activityIndicator?.startAnimating()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 1)
            image.drawInRect(self.bounds)
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            dispatch_async(dispatch_get_main_queue(), {
                self.stopAnimatingOnMainQueue()
                self.originalImage = result
                self.image = result
            })
        })
    }
}

private extension ODImproveFaceImageView {
    func stopAnimatingOnMainQueue() {
        dispatch_async(dispatch_get_main_queue(), {
            guard let indicator = self.activityIndicator else {
                return
            }
            indicator.stopAnimating()
        })
    }
}
