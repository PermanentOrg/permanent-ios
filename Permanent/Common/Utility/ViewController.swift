//  
//  ViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26.01.2021.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    var actionDialog: ActionDialogView?
    
    private let overlayView = UIView() // Maybe var?
    
    // MARK: - View Controller
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }
    
    // MARK: - Events
    
    func setupOverlayView() {
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0
    }
    
    func showActionDialog(
        styled style: ActionDialogStyle,
        withTitle title: String,
        description: String? = nil,
        placeholders: [String]? = nil,
        prefilledValues: [String]? = nil,
        dropdownValues: [String]? = nil,
        positiveButtonTitle: String,
        cancelButtonTitle: String = .cancel,
        positiveButtonColor: UIColor = .primary,
        cancelButtonColor: UIColor = .brightRed,
        positiveAction: @escaping ButtonAction
    ) {
        
        guard actionDialog == nil else { return }
        
        actionDialog = ActionDialogView(
            frame: CGRect(origin: CGPoint(x: 0, y: view.bounds.height), size: view.bounds.size),
            style: style,
            title: title,
            description: description,
            positiveButtonTitle: positiveButtonTitle,
            cancelButtonTitle: cancelButtonTitle,
            positiveButtonColor: positiveButtonColor,
            cancelButtonColor: cancelButtonColor,
            placeholders: placeholders,
            prefilledValues: prefilledValues,
            dropdownValues: dropdownValues,
            onDismiss: {
                self.view.dismissPopup(
                    self.actionDialog,
                    overlayView: self.overlayView,
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
