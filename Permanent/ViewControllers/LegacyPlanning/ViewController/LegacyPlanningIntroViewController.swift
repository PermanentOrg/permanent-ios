//
//  LegacyPlanningViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.04.2023.
//

import UIKit

class LegacyPlanningIntroViewController: BaseViewController<LegacyPlanningViewModel> {
    @IBOutlet weak var setUpTitleLabel: UILabel!
    @IBOutlet weak var setUpDescriptionLabel: UILabel!
    @IBOutlet weak var accountLegacyTitleLabel: UILabel!
    @IBOutlet weak var accountLegacyDescriptionLabel: UILabel!
    @IBOutlet weak var archiveLegacyTitleLabel: UILabel!
    @IBOutlet weak var archiveLegacyDescriptionLabel: UILabel!
    @IBOutlet weak var setUpMyAccountButton: LegacyPlanningSetUpButton!
    @IBOutlet weak var tellMoreButton: UIButton!
    @IBOutlet weak var logoWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var isShowMoreEnabled: Bool = false {
        didSet {
            if isShowMoreEnabled {
                showElements()
            } else {
                hideElements()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        styleNavBar()
        setupNavBar()
        setupUI()
    }
    
    private func setupNavBar() {
        titleLabelSetup()
        if let viewControllersCount = navigationController?.viewControllers.count, viewControllersCount > 1 {
            backButtonSetup()
        }
        closeButtonSetup()
    }
    
    private func setupUI() {
        view.backgroundColor = .darkBlue
        setupTitleLabel()
        setupDescriptionLabel()
        
        tellMoreButton.setTitleColor(.white, for: .normal)
        tellMoreButton.setTitle("Tell me more about Legacy Planning".localized(), for: .normal)
        
        accountLegacyTitleLabel.isHidden = true
        accountLegacyDescriptionLabel.isHidden = true
        archiveLegacyTitleLabel.isHidden = true
        archiveLegacyDescriptionLabel.isHidden = true
    }
    
    private func titleLabelSetup() {
        let titleLabel = UILabel()
        titleLabel.text = "Legacy Planning".localized()
        titleLabel.textColor = .white
        titleLabel.font = TextFontStyle.style35.font
        titleLabel.sizeToFit()
        
        navigationItem.titleView = titleLabel
    }
    
    private func backButtonSetup() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(named: "newBackButton"), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 10)
        
        let backButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = backButtonItem
    }
    
    private func closeButtonSetup() {
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(named: "newCloseButton"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: -20)
        
        let closeButtonItem = UIBarButtonItem(customView: closeButton)
        navigationItem.rightBarButtonItem = closeButtonItem
    }
    
    func setupTitleLabel() {
        for label in [setUpTitleLabel, accountLegacyTitleLabel, archiveLegacyTitleLabel] {
            label?.textColor = .white
        }
    }
    
    func setupDescriptionLabel() {
        for label in [accountLegacyDescriptionLabel, archiveLegacyDescriptionLabel, setUpDescriptionLabel] {
            label?.textColor = UIColor.white.withAlphaComponent(0.66)
        }
    }
    
    func showElements() {
        scrollView.isScrollEnabled = true
        
        UIView.animate(withDuration: 0.4, animations: {
            self.logoWidthConstraint.constant = 48
            self.logoHeightConstraint.constant = 48
            self.tellMoreButton.setTitle("I’ll do this later".localized(), for: .normal)
            
            self.setUpTitleLabel.textAlignment = .left
            self.setUpDescriptionLabel.textAlignment = .left
            self.setUpDescriptionLabel.text = "Your Legacy Plan will determine when, how, and with whom your materials will be shared. Your Legacy Plan has two parts. First, decide when Permanent should consider your account to be inactive by creating an Account Legacy Plan. Second, decide what happens to the materials in your Archives by creating an Archive Legacy Plan for each of them.".localized()
            self.accountLegacyTitleLabel.isHidden = false
            self.accountLegacyDescriptionLabel.isHidden = false
            self.archiveLegacyTitleLabel.isHidden = false
            self.archiveLegacyDescriptionLabel.isHidden = false
            self.view.layoutIfNeeded()
        })
    }
    
    func hideElements() {
        scrollView.isScrollEnabled = false
        UIView.animate(withDuration: 0.4, animations: {
            self.scrollView.contentOffset = .zero
            self.logoWidthConstraint.constant = 128
            self.logoHeightConstraint.constant = 128
            
            self.setUpTitleLabel.textAlignment = .center
            self.setUpDescriptionLabel.textAlignment = .center
            self.setUpDescriptionLabel.text = "Decide when your account becomes inactive and what happens to your files. Share them with trusted people or have us delete them.".localized()
            
            self.accountLegacyTitleLabel.isHidden = true
            self.accountLegacyDescriptionLabel.isHidden = true
            self.archiveLegacyTitleLabel.isHidden = true
            self.archiveLegacyDescriptionLabel.isHidden = true
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func setUpAccountAction(_ sender: Any) {
        if let legacyPlanningStewardVC = UIViewController.create(withIdentifier: .legacyPlanningSteward, from: .legacyPlanning) as? LegacyPlanningStewardViewController {
            legacyPlanningStewardVC.viewModel?.stewardType = .account
            navigationController?.pushViewController(legacyPlanningStewardVC, animated: true)
        }
    }
    
    @IBAction func tellMeMoreAction(_ sender: Any) {
        if isShowMoreEnabled {
            dismiss(animated: true, completion: nil)
        } else {
            isShowMoreEnabled.toggle()
        }
    }
    
    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}
