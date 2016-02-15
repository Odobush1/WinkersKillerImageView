//
//  UIViewController+Alerts.swift
//  WrinklesKiller
//
//  Created by Alex on 2/2/16.
//  Copyright © 2016 Alex. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func showAlertWithTitle(title: String, message: String, complition: (() -> ())?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
            if let block = complition {
                block()
            }
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(OKAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}