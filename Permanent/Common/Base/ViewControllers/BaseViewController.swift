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

    var floatingActionIsland: FloatingActionIslandViewController?
    
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
        self.showAlert(title: .error, message: message)
    }
    
    func styleNavBar() {
        navigationController?.navigationBar.tintColor = .white
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .darkBlue
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: TextFontStyle.style14.font
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
        
        if #available(iOS 26.0, *) {
            // On iOS 26, the global UINavigationBar.appearance() proxy may have isTranslucent
            // reset to true (by CustomNavigationView.onDisappear). Setting it at the instance
            // level here ensures UIKit screens always render as opaque dark blue, regardless
            // of the proxy state at the moment of a modal transition.
            navigationController?.navigationBar.isTranslucent = false
        }
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
        cancelButtonTitle: String = .cancel,
        positiveButtonColor: UIColor = .primary,
        cancelButtonColor: UIColor = .brightRed,
        textFieldKeyboardType: UIKeyboardType = .default,
        overlayView: UIView?
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
            textFieldKeyboardType: textFieldKeyboardType,
            onDismiss: { [weak self] in
                guard let self = self else { return }
                self.view.dismissPopup(
                    self.actionDialog,
                    overlayView: overlayView,
                    completion: { _ in
                        self.actionDialog?.removeFromSuperview()
                        self.actionDialog = nil
                    }
                )
            }
        )
        
        actionDialog?.positiveAction = positiveAction
        actionDialog?.titleLabel.textAlignment = .center
        actionDialog?.subtitleLabel.textAlignment = .center
        view.addSubview(actionDialog!)
        view.presentPopup(actionDialog, overlayView: overlayView)
    }

    func showFloatingActionIsland(withLeftItems leftItems: [FloatingActionItem], rightItems: [FloatingActionItem]) {
        floatingActionIsland = FloatingActionIslandViewController()
        floatingActionIsland?.leftItems = leftItems
        floatingActionIsland?.rightItems = rightItems
        floatingActionIsland?.view.translatesAutoresizingMaskIntoConstraints = false

        floatingActionIsland?.willMove(toParent: self)
        addChild(floatingActionIsland!)
        view.addSubview(floatingActionIsland!.view)

        let bottomAnchor: NSLayoutConstraint
        if #available(iOS 26, *) {
            // Anchor above the safe area so the pill clears the home indicator
            bottomAnchor = floatingActionIsland!.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6)
        } else {
            bottomAnchor = floatingActionIsland!.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32)
        }
        NSLayoutConstraint.activate([
            floatingActionIsland!.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomAnchor,
            floatingActionIsland!.view.widthAnchor.constraint(equalToConstant: view.frame.width - 64),
            // Explicit height so the view has a proper touch target (required on iOS 26 where
            // toolbar uses centerY rather than top+bottom anchors to define view height)
            floatingActionIsland!.view.heightAnchor.constraint(equalToConstant: 64),
        ])

        floatingActionIsland?.didMove(toParent: self)
    }

    func dismissFloatingActionIsland(_ completion: (() -> Void)? = nil) {
        floatingActionIsland?.animateDismiss { [self] in
            floatingActionIsland?.willMove(toParent: nil)
            floatingActionIsland?.view.removeFromSuperview()
            floatingActionIsland?.removeFromParent()
            floatingActionIsland?.didMove(toParent: nil)

            floatingActionIsland = nil
            completion?()
        }
    }
}
