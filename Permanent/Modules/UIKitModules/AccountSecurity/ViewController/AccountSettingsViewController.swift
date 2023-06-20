//
//  AccountSettingsViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 07.01.2021.
//

import UIKit

class AccountSettingsViewController: BaseViewController<SecurityViewModel> {
    @IBOutlet var contentUpdateButton: RoundedButton!
    @IBOutlet var firstLineView: UIView!
    @IBOutlet var logWithBiometricsView: SwitchSettingsView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = SecurityViewModel()
        viewModel?.viewDelegate = self
        
        initUI()
    }

    private func initUI() {
        title = .security
        view.backgroundColor = .white
        firstLineView.backgroundColor = .lightGray
        logWithBiometricsView.text = viewModel!.getAuthTypeText()
        
        contentUpdateButton.configureActionButtonUI(title: "Change password".localized())

        logWithBiometricsView.delegate = self

        logWithBiometricsView.isUserInteractionEnabled = viewModel!.getUserBiomericsStatus()
        logWithBiometricsView.toggle(isOn: viewModel!.getAuthToggleStatus())
    }
    
    // MARK: Actions
    @IBAction func pressedUpdateButton(_ sender: RoundedButton) {
        let viewController = UIViewController.create(withIdentifier: .passwordUpdate, from: .settings) as! PasswordUpdateViewController
        viewController.viewModel = viewModel
        let navigationController: NavigationController = NavigationController(rootViewController: viewController)
        
        self.present(navigationController, animated: true, completion: nil)
    }
    
    func switchToggleWasPressed(sender: UISwitch) {
        PreferencesManager.shared.set(sender.isOn, forKey: Constants.Keys.StorageKeys.biometricsAuthEnabled)
    }
}

extension AccountSettingsViewController: ActionForSwitchSettingsView {}

extension AccountSettingsViewController: SecurityViewModelViewDelegate {
    func passwordUpdated(success: Bool) {
        if success {
            self.view.showNotificationBanner(title: "Password was successfully updated".localized())
        } else {
            self.view.showNotificationBanner(title: .errorMessage, backgroundColor: .brightRed, textColor: .white, animationDelayInSeconds: Constants.Design.longNotificationBarAnimationDuration)
        }
    }
}
