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
        if spinnerView != nil {
            return
        }

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
    
    public func showToast(message: String, seconds: Double = 3.0) {
        let toast = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        toast.view.alpha = 0.5
        present(toast, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            toast.dismiss(animated: true)
        }
    }
}

extension UIViewController {
    static func create(withIdentifier id: ViewControllerId, from storyboard: StoryboardName) -> UIViewController {
        let storyboard = UIStoryboard(name: storyboard.name, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: id.value)
    }
}
