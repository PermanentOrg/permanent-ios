//
//  UIViewControllerExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 05/10/2020.
//

import UIKit

private var spinnerView: UIView?

extension UIViewController {
    func showSpinner(colored color: UIColor = .primary) {
        spinnerView = UIView(frame: self.view.bounds)
        spinnerView?.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)

        let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator.center = spinnerView!.center
        activityIndicator.color = color
        activityIndicator.startAnimating()

        spinnerView?.addSubview(activityIndicator)
        self.view.addSubview(spinnerView!)
    }

    func hideSpinner() {
        spinnerView?.removeFromSuperview()
        spinnerView = nil
    }
}
