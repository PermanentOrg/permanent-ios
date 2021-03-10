//
//  BaseViewController.swift
//  Permanent
//
//  Created by Gabi Tiplea on 17/08/2020.
//

import UIKit
class BaseViewController<T: ViewModelInterface>: UIViewController {
    var viewModel: T?
    var actionDialog: ActionDialogView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel?.viewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel?.viewWillDisappear()
    }
    
    func showAlert(title: String?, message: String?) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: .ok, style: .default, handler: nil))

            self.present(alert, animated: true)
        }
    }
    
    func showErrorAlert(message: String?) {
        DispatchQueue.main.async {
            self.showAlert(title: .error, message: message)
        }
    }
    
    func styleNavBar() {
        navigationController?.navigationBar.barTintColor = .darkBlue
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: Text.style14.font
        ]
        navigationController?.navigationBar.tintColor = .white
    }
    
    func closeKeyboard() {
        view.endEditing(true)
    }
    
    func showActionDialog(
        styled style: ActionDialogStyle,
        withTitle title: String,
        description: String? = nil,
        placeholders: [String]? = nil,
        prefilledValues: [String]? = nil,
        dropdownValues: [String]? = nil,
        positiveButtonTitle: String,
        positiveAction: @escaping ButtonAction,
        overlayView: UIView?
    ) {
        
        guard actionDialog == nil else { return }
        
        actionDialog = ActionDialogView(
            frame: CGRect(origin: CGPoint(x: 0, y: view.bounds.height), size: view.bounds.size),
            style: style,
            title: title,
            description: description,
            positiveButtonTitle: positiveButtonTitle,
            placeholders: placeholders,
            prefilledValues: prefilledValues,
            dropdownValues: dropdownValues,
            onDismiss: {
                self.view.dismissPopup(
                    self.actionDialog,
                    overlayView: overlayView,
                    completion: { _ in
                        self.actionDialog?.removeFromSuperview()
                        self.actionDialog = nil
                    })
            }
        )
        
        actionDialog?.positiveAction = positiveAction
        view.addSubview(actionDialog!)
        self.view.presentPopup(actionDialog, overlayView: overlayView)
    } 
}
