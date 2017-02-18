import UIKit

extension UIViewController {
    func showAlert(withTitle title: String, message: String, complition: (() -> ())?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alertController.dismiss(animated: true, completion: complition)
        }
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
}
