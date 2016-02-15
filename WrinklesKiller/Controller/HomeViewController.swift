//
//  HomeViewController.swift
//  WrinklesKiller
//
//  Created by Alex on 1/25/16.
//  Copyright © 2016 Alex. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet private weak var imageView: ODImproveFaceImageView?
    @IBOutlet private weak var compareButton: UIButton?
    @IBOutlet private weak var resultButton: UIButton?
    
    private var isOriginalPhotoShown: Bool = true
    
    lazy private var imagePicker: UIImagePickerController = {
            let tempImagePicker = UIImagePickerController.init()
            tempImagePicker.delegate = self
            tempImagePicker.allowsEditing = false
            
            if UIImagePickerController.isCameraDeviceAvailable(.Front) {
                tempImagePicker.sourceType = .Camera
                tempImagePicker.cameraDevice = .Front
             } else if UIImagePickerController.isCameraDeviceAvailable(.Rear) {
                tempImagePicker.sourceType = .Camera
                tempImagePicker.cameraDevice = .Rear
            } else {
                tempImagePicker.sourceType = .PhotoLibrary
            }
            return tempImagePicker
    }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if imageView?.image == nil {
            guard let testImage = UIImage.init(named: "testImage") else {
                return
            }
            imageView?.setOriginalImage(testImage)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

//MARK: IBAction
private extension HomeViewController {
    @IBAction func newPhotoButtonPressed(sender: UIButton) {
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func handleImageButtonPressed(sender: UIButton) {
        imageView?.showHandledImage()
        compareButton?.enabled = true
        resultButton?.enabled = false
    }
    
    @IBAction func compareButtonPressed(sender: UIButton) {
        isOriginalPhotoShown = !isOriginalPhotoShown
        
        if isOriginalPhotoShown {
            imageView?.showHandledImage()
            return
        }
        imageView?.showOriginalImage()
    }
}

//MARK:UIImagePickerControllerDelegate
extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let image = info[UIImagePickerControllerOriginalImage]
        
        guard let resultImage = image as? UIImage else {
            return
        }
        imageView?.cleanImageView()
        imageView?.setOriginalImage(resultImage)
        compareButton?.enabled = false
        resultButton?.enabled = true
        
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
}