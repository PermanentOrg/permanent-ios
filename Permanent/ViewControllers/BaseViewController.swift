//
//  BaseViewController.swift
//  Permanent
//
//  Created by Gabi Tiplea on 17/08/2020.
//

import UIKit
class BaseViewController<T: ViewModelInterface>: UIViewController {
    var viewModel: T?
    
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
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Translations.ok, style: .default, handler: nil))

        present(alert, animated: true)
    }
    
    func styleNavBar() {
        navigationController?.navigationBar.barTintColor = .darkBlue
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: Text.style14.font
        ]
    }
    
    func closeKeyboard() {
        view.endEditing(true)
    }
}
