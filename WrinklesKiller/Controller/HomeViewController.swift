import UIKit

class HomeViewController: UIViewController {
    @IBOutlet fileprivate weak var imageView: ImproveFaceImageView!
    @IBOutlet fileprivate weak var compareButton: UIButton!
    @IBOutlet fileprivate weak var resultButton: UIButton!
    
    fileprivate var isOriginalPhotoShown = true
    
    lazy fileprivate var imagePicker: UIImagePickerController = {
            let tempImagePicker = UIImagePickerController()
            tempImagePicker.delegate = self
            tempImagePicker.allowsEditing = false
            
            if UIImagePickerController.isCameraDeviceAvailable(.front) {
                tempImagePicker.sourceType = .camera
                tempImagePicker.cameraDevice = .front
             } else if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                tempImagePicker.sourceType = .camera
                tempImagePicker.cameraDevice = .rear
            } else {
                tempImagePicker.sourceType = .photoLibrary
            }
            return tempImagePicker
    }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if imageView.image == nil {
            guard let testImage = UIImage(named: "testImage") else { return }
            imageView.setOriginalImage(testImage)
        }
    }
    
    //MARK: IBAction
    @IBAction func newPhotoButtonPressed(_ sender: UIButton) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func handleImageButtonPressed(_ sender: UIButton) {
        imageView.showHandledImage()
        compareButton.isEnabled = true
        resultButton.isEnabled = false
    }
    
    @IBAction func compareButtonPressed(_ sender: UIButton) {
        isOriginalPhotoShown = !isOriginalPhotoShown
        isOriginalPhotoShown ? imageView.showHandledImage() : imageView.showOriginalImage()
    }
}

//MARK:UIImagePickerControllerDelegate
extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage]
        
        guard let resultImage = image as? UIImage else { return }
        imageView.setOriginalImage(resultImage)
        compareButton.isEnabled = false
        resultButton.isEnabled = true
    
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
