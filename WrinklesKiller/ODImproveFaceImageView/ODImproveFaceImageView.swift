import UIKit

final class ODImproveFaceImageView: UIImageView {
    fileprivate var originalImage: UIImage?
    fileprivate var processedImage: UIImage?
    
    lazy fileprivate var activityIndicator: UIActivityIndicatorView? = {
        let activity = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        activity.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        activity.center = self.center
        self.addSubview(activity)
        return activity
    }()
    
    func setOriginalImage(_ image: UIImage) {
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
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
            guard let mask = self.detectFace(workImage) else {
                self.stopAnimatingOnMainQueue()
                return
            }
            guard let bluredImage = workImage.addGPUBlur() else {
                self.stopAnimatingOnMainQueue()
                return
            }
            guard let maskedImage = bluredImage.maskedImage(withMask: mask) else {
                self.stopAnimatingOnMainQueue()
                return
            }
            
            guard let original = self.originalImage,
                let scaledPhoto = maskedImage.scaleImage(toRect: self.bounds) else {
                self.stopAnimatingOnMainQueue()
                return
            }
            self.processedImage = original.combineImage(withImage: scaledPhoto)
        
            DispatchQueue.main.async(execute: {
                self.stopAnimatingOnMainQueue()
                self.image = self.processedImage
            })
         })
    }
    
    func detectFace(_ undetectedImage: UIImage) -> UIImage? {
        guard let workImage = CIImage.init(image: undetectedImage) else { return nil }
        
        let context = CIContext.init(options: [kCIContextUseSoftwareRenderer : true])
        let detector = CIDetector.init(ofType: CIDetectorTypeFace, context: context, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
        let features = detector?.features(in: workImage)
        UIGraphicsBeginImageContextWithOptions(undetectedImage.size, false, 1)
        let contextReference = UIGraphicsGetCurrentContext()
        contextReference?.translateBy(x: 0, y: undetectedImage.size.height)
        contextReference?.scaleBy(x: 1, y: -1)
        contextReference?.saveGState()
        contextReference?.setFillColor(red: 1, green: 0, blue: 1, alpha: 1)
        contextReference?.fill(CGRect(x: 0, y: 0, width: undetectedImage.size.width , height: undetectedImage.size.height))
        contextReference?.restoreGState()
        
        //FIXME: Make for
        if (features?.count == 1) {
            guard let feature = features?[0] as? CIFaceFeature,
                let reference = contextReference,
                let resultImage = self.proccesFeature(feature, contextReference: reference) else {
                    return nil
            }
            
            return resultImage
        }
        return nil
    }
    
    func proccesFeature(_ feature: CIFaceFeature, contextReference: CGContext) -> UIImage? {
        if feature.hasLeftEyePosition == false || feature.hasRightEyePosition == false || feature.hasMouthPosition == false {
            return nil
        }
        
        contextReference.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
        let betweenEyesPoint = feature.leftEyePosition.pointBetweenPoint(feature.rightEyePosition)
        let distanceBetweenEyes = feature.leftEyePosition.distanceToPoint(feature.rightEyePosition)
        let radius = distanceBetweenEyes / 2
        let distanceToNose = betweenEyesPoint.distanceToPoint(feature.mouthPosition)
        let faceWidth = radius * 2 + radius * 2 + radius
        let elipsX = betweenEyesPoint.x - (radius * 2) - (radius / 2)
        let elipsY = betweenEyesPoint.y - distanceToNose - (radius * 2)
        let elipsHeight = (distanceToNose * 2) + (radius * 2) + (radius / 2)
        let rectEllipse = CGRect(x: elipsX, y: elipsY, width: faceWidth, height: elipsHeight)
        
        contextReference.saveGState()
        
        let angle = faceRotationOfFeature(feature)
        let flowerPetal = CGMutablePath()
        let midleX = rectEllipse.midX
        let midleY = rectEllipse.midY
        let transform = CGAffineTransform(translationX: -midleX, y: -midleY).concatenating(CGAffineTransform(rotationAngle: angle)).concatenating(CGAffineTransform(translationX: midleX, y: midleY))
       
        flowerPetal.addEllipse(in: rectEllipse, transform: transform)
        //CGPathAddEllipseInRect(flowerPetal, &transform, rectEllipse)
        contextReference.addPath(flowerPetal)
        contextReference.fillPath()
        contextReference.restoreGState()
    
        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return maskedImage
    }

    func faceRotationOfFeature(_ feature: CIFaceFeature) -> CGFloat {
        let pointX = (feature.rightEyePosition.x + feature.leftEyePosition.x) / 2
        let pointY = (feature.rightEyePosition.y + feature.leftEyePosition.y) / 2
        let betweenEyesMidPoint = CGPoint(x: pointX, y: pointY)
        let originEndPoint = CGPoint(x: feature.mouthPosition.x, y: betweenEyesMidPoint.y)
        let angle1 = atan2f(Float(feature.mouthPosition.y - betweenEyesMidPoint.y), Float(feature.mouthPosition.x - betweenEyesMidPoint.x))
        let angle2 = atan2f(Float(feature.mouthPosition.y - originEndPoint.y), Float(feature.mouthPosition.x - originEndPoint.x))
        return CGFloat(angle1 - angle2)
    }
    
    func prepareImageForHandling(_ image: UIImage) {
        activityIndicator?.startAnimating()
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
            UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 1)
            image.draw(in: self.bounds)
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            DispatchQueue.main.async(execute: {
                self.stopAnimatingOnMainQueue()
                self.originalImage = result
                self.image = result
            })
        })
    }
    
    private func stopAnimatingOnMainQueue() {
        DispatchQueue.main.async(execute: {
            self.activityIndicator?.stopAnimating()
        })
    }
}

