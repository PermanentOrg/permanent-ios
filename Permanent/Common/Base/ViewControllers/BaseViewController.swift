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
    
    func showAddButtonMenu(overlayView: UIView?) {
        let addButtonMenuView = AddButtonMenuView(frame: CGRect(origin: CGPoint(x: 0, y: view.bounds.height), size: view.bounds.size))
        addButtonMenuView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(addButtonMenuView)
        view.presentPopup(addButtonMenuView, overlayView: overlayView)
    }

    func showFloatingActionIsland(withLeftItems leftItems: [FloatingActionItem], rightItems: [FloatingActionItem]) {
        floatingActionIsland = FloatingActionIslandViewController()
        floatingActionIsland?.leftItems = leftItems
        floatingActionIsland?.rightItems = rightItems
        floatingActionIsland?.view.translatesAutoresizingMaskIntoConstraints = false

        floatingActionIsland?.willMove(toParent: self)
        addChild(floatingActionIsland!)
        view.addSubview(floatingActionIsland!.view)

        NSLayoutConstraint.activate([
            floatingActionIsland!.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            floatingActionIsland!.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32),
            floatingActionIsland!.view.widthAnchor.constraint(equalToConstant: view.frame.width - 64)
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
