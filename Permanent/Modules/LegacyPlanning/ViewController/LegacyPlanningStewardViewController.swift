//
//  ArchiveLegacyPlanningViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.04.2023.
//

import UIKit

class LegacyPlanningStewardViewController: BaseViewController<LegacyPlanningViewModel> {
    @IBOutlet weak var archiveThumbnailImage: UIImageView!
    @IBOutlet weak var archiveNameLabel: UILabel!
    @IBOutlet weak var archivePermissionView: UIView!
    @IBOutlet weak var archivePermissionViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var archivePermissionLabel: UILabel!
    @IBOutlet weak var designateStewardLabel: UILabel!
    @IBOutlet weak var designateArchiveStewardLabel: UILabel!
    @IBOutlet weak var saveArchiveLegacyButton: LegacyPlanningSaveButton!
    @IBOutlet weak var trustedStewardView: UIView!
    @IBOutlet weak var trustedStewardImage: UIImageView!
    @IBOutlet weak var trustedStewardTitleLabel: UILabel!
    @IBOutlet weak var trustedStewardDescriptionLabel: UILabel!
    @IBOutlet weak var addLegacyStewardLabel: UILabel!
    @IBOutlet weak var addLegacyStewardButton: UIButton!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var topArchiveDetailsView: UIView!
    @IBOutlet weak var topArchiveDetailsHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var addLegacyStewardView: UIView!
    @IBOutlet weak var addedLegacyStewardView: UIView!
    @IBOutlet weak var addedLegacyStewardName: UILabel!
    @IBOutlet weak var addedLegacyStewardEmail: UILabel!
    @IBOutlet weak var addedLegacyStewardStatusView: UIView!
    @IBOutlet weak var addedLegacyStewardStatusLabel: UILabel!
    @IBOutlet weak var addedLegacyStewardDeleteButton: UIButton!
    @IBOutlet weak var alertAccountStewardView: UIView!
    @IBOutlet weak var alertLegacyStewardImageView: UIImageView!
    @IBOutlet weak var alertLegacyStewardLabel: UILabel!
    @IBOutlet weak var alertLegacyStewardSeparatorView: UIView!
    @IBOutlet weak var alertLegacyStewardGoToButton: LegacyPlanningSimpleGoToButton!
    var selectedArchive: ArchiveVOData?
    
    private let overlayView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if viewModel?.stewardType == .archive {
            viewModel?.selectedArchive = selectedArchive
            viewModel?.trackEvents(action: AccountEventAction.openArchiveSteward)
        } else {
            viewModel?.trackEvents(action: AccountEventAction.openLegacyContact)
        }
        
        viewModel?.isLoading = { [weak self] loading in
            if loading {
                self?.showSpinner()
            } else {
                self?.hideSpinner()
            }
        }
        
        viewModel?.showError = { [weak self] error in
            self?.showAlert(title: .error, message: .errorMessage)
        }
        
        viewModel?.stewardWasUpdated = { [weak self] _ in
            self?.updateTrustedSteward()
        }
        
        viewModel?.stewardWasSaved = { [weak self] _ in
            self?.updateTrustedSteward()
        }
        
        viewModel?.accountStewardStatusUpdated = { [weak self] hasAccountSteward in
            self?.updateArchiveStewardButtonState(hasAccountSteward: hasAccountSteward)
        }
        
        viewModel?.getSteward()
        
        // Check account steward status for archive steward type
        if viewModel?.stewardType == .archive {
            viewModel?.checkAccountStewardExists()
        }
        
        setupUI()
        styleNavBar()
        
        addedLegacyStewardDeleteButton.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel?.getSteward()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }
    
    override func styleNavBar() {
        super.styleNavBar()
    }
    
    private func setupUI() {
        view.backgroundColor = .backgroundPrimary
        view.layer.backgroundColor = UIColor.whiteGray.cgColor
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0
        
        titleLabelSetup()
        if navigationController?.viewControllers.count ?? 0 > 1 {
            backButtonSetup()
        }
        closeButtonSetup()
        addLegacyStewardSetup()
        addedLegacyStewardSetup()
        customizeSeparatorView()
        alertLegacyStewardGoToButtonSetup(text: "Designate a Legacy Contact")
        
        if viewModel?.stewardType == .archive {
            // Initially hide the archive details until we know the account steward status
            topArchiveDetailsView.isHidden = true
            topArchiveDetailsHeightConstraint.constant = 0
            alertAccountStewardView.isHidden = true
            saveArchiveLegacyButton.isHidden = true

            if let imageThumbnail = viewModel?.selectedArchive?.thumbURL500 {
                archiveThumbnailImage.sd_setImage(with: URL(string: imageThumbnail))
            }
            
            archiveNameLabelSetup(text: "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: viewModel?.selectedArchive?.fullName ?? ""))
            archivePermissionSetup(text: AccessRole.roleForValue(viewModel?.selectedArchive?.accessRole ?? "").groupName)
            designateStewardLabelSetup(text: "Designate an Archive Steward".localized())
            designateArchiveStewardLabelSetup(text: "Who should be the owner of this archive in the event of your death or incapacitation?".localized())
            saveArchiveLegacyButtonSetup(text: "Go to Legacy Plan".localized())
            trustedStewardTitleLabelSetup(text: "A trusted archive steward".localized())
            trustedStewardDescriptionLabelSetup(text: "The Archive steward will receive a note when your Legacy Plan is activated.".localized())
            alertLegacyPlanningSetup(text: "Before you can add an Archive Steward for this archive below, designate a Legacy Contact first.")
        } else {
            alertAccountStewardView.isHidden = true
            topArchiveDetailsView.isHidden = true
            topArchiveDetailsHeightConstraint.constant = 0
            
            designateStewardLabelSetup(text: "Designate a Legacy Contact".localized())
            designateArchiveStewardLabelSetup(text: "Who will reach out to Permanent to let us know of your death or permanent incapacitation?".localized())
            saveArchiveLegacyButtonSetup(text: "Go to Legacy Plan".localized())
            trustedStewardTitleLabelSetup(text: "A trusted legacy contact".localized())
            trustedStewardDescriptionLabelSetup(text: "A trusted person who can inform Permanent about your death or long term disability.".localized())
        }
    }
    
    private func titleLabelSetup() {
        let titleLabel = UILabel()
        if viewModel?.stewardType == .archive {
            titleLabel.text = "Archive Legacy Planning".localized()
        } else {
            titleLabel.text = "Legacy Planning".localized()
        }
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
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 10) // Adjust the position
        
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
    
    private func archiveNameLabelSetup(text: String) {
        archiveNameLabel.textColor = .darkBlue
        archiveNameLabel.font = TextFontStyle.style15.font
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.9
        
        archiveNameLabel.textAlignment = .left
        archiveNameLabel.attributedText = NSMutableAttributedString(
            string: text,
            attributes: [
                NSAttributedString.Key.kern: -0.26,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]
        )
    }
    
    private func archivePermissionSetup(text: String) {
        archivePermissionLabel.backgroundColor = .clear
        archivePermissionLabel.textColor = .darkBlue
        archivePermissionLabel.font = TextFontStyle.style36.font
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.47
        
        archivePermissionLabel.textAlignment = .center
        archivePermissionLabel.attributedText = NSMutableAttributedString(
            string: text.uppercased(),
            attributes: [
                NSAttributedString.Key.kern: 0.8,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]
        )
        
        archivePermissionView.backgroundColor = .white
        archivePermissionView.layer.backgroundColor = UIColor(red: 0.553, green: 0, blue: 0.522, alpha: 0.2).cgColor
        archivePermissionView.layer.cornerRadius = 4
        
        archivePermissionViewWidthConstraint.constant = archivePermissionLabel.frame.width + 4
    }
    
    private func designateStewardLabelSetup(text: String) {
        designateStewardLabel.textColor = .darkBlue
        designateStewardLabel.font = TextFontStyle.style31.font
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.91
        
        designateStewardLabel.textAlignment = .left
        designateStewardLabel.attributedText = NSMutableAttributedString(
            string: text.uppercased(),
            attributes: [
                NSAttributedString.Key.kern: 0.8,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]
        )
    }
    
    private func designateArchiveStewardLabelSetup(text: String) {
        designateArchiveStewardLabel.textColor = .darkBlue
        designateArchiveStewardLabel.font = TextFontStyle.style3.font
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.06
        
        designateArchiveStewardLabel.textAlignment = .left
        designateArchiveStewardLabel.attributedText = NSMutableAttributedString(
            string: text,
            attributes: [
                NSAttributedString.Key.kern: -0.36,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]
        )
    }
    
    private func trustedStewardTitleLabelSetup(text: String) {
        trustedStewardView.layer.cornerRadius = 4
        trustedStewardImage.image = UIImage(named: "trustedSteward")
        
        trustedStewardTitleLabel.textColor = .darkBlue
        trustedStewardTitleLabel.font = TextFontStyle.style35.font
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.17
        
        trustedStewardTitleLabel.textAlignment = .left
        trustedStewardTitleLabel.attributedText = NSMutableAttributedString(
            string: text,
            attributes: [
                NSAttributedString.Key.kern: -0.3,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]
        )
    }
    
    private func alertLegacyPlanningSetup(text: String) {
        alertAccountStewardView.layer.cornerRadius = 4
        alertAccountStewardView.layer.backgroundColor = UIColor(red: 0.998, green: 0.939, blue: 0.779, alpha: 1).cgColor
        alertLegacyStewardImageView.image = UIImage(named: "LegacyPlanningWarning")
        
        alertLegacyStewardLabel.textColor = .darkBlue
        alertLegacyStewardLabel.font = TextFontStyle.style34.font
        
        alertLegacyStewardLabel.textAlignment = .left
        alertLegacyStewardLabel.lineBreakMode = .byWordWrapping
        alertLegacyStewardLabel.numberOfLines = 0
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.36
        
        alertLegacyStewardLabel.text = text
    }
    
    private func trustedStewardDescriptionLabelSetup(text: String) {
        trustedStewardDescriptionLabel.textColor = .black
        trustedStewardDescriptionLabel.font = TextFontStyle.style39.font
        trustedStewardDescriptionLabel.lineBreakMode = .byWordWrapping
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.10
        
        trustedStewardDescriptionLabel.textAlignment = .left
        trustedStewardDescriptionLabel.attributedText = NSMutableAttributedString(
            string: text,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]
        )
    }
    
    private func saveArchiveLegacyButtonSetup(text: String) {
        saveArchiveLegacyButton.layer.cornerRadius = 8
        saveArchiveLegacyButton.clipsToBounds = true
        saveArchiveLegacyButton.rightSideImage.image = UIImage(named: "legacyPlanRightArrow")
        saveArchiveLegacyButton.leftSideLabel.text = text
        saveArchiveLegacyButton.isSelectable = true
    }

    private func alertLegacyStewardGoToButtonSetup(text: String) {
        alertLegacyStewardGoToButton.layer.cornerRadius = 8
        alertLegacyStewardGoToButton.clipsToBounds = true
        alertLegacyStewardGoToButton.textLabel.text = text
        alertLegacyStewardGoToButton.isSelectable = true
    }
    
    private func addLegacyStewardSetup() {
        if viewModel?.stewardType == .archive {
            addLegacyStewardLabel.text = "Add Legacy Steward".localized()
        } else {
            addLegacyStewardLabel.text = "Add Legacy Contact".localized()
        }
        addLegacyStewardLabel.textColor = .darkBlue
        addLegacyStewardLabel.font = TextFontStyle.style44.font
        addLegacyStewardButton.setImage(UIImage(named: "addLegacyPerson")?.withRenderingMode(.alwaysTemplate), for: .normal)
        addLegacyStewardButton.tintColor = .darkBlue
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addLegacyPersonButtonAction(_:)))
        addLegacyStewardLabel.isUserInteractionEnabled = true
        addLegacyStewardLabel.addGestureRecognizer(tapGesture)
        
        if viewModel?.stewardType == .archive {
            print("button disabled.")
        }
    }
    
    private func addedLegacyStewardSetup() {
        formatAddedLegacyStewardName()
        formatAddedLegacyStewardEmail()
        formatAddedLegacyStewardStatus()
        formatAddedLegacyStewardDeleteButton()
    }
    
    func formatAddedLegacyStewardName() {
        addedLegacyStewardName.textColor = .darkBlue
        addedLegacyStewardName.font = TextFontStyle.style44.font
    }
    
    func formatAddedLegacyStewardEmail() {
        addedLegacyStewardEmail.textColor = .middleGray
        addedLegacyStewardEmail.font = TextFontStyle.style39.font
    }
    
    private func formatAddedLegacyStewardStatus() {
        addedLegacyStewardStatusLabel.backgroundColor = .clear
        addedLegacyStewardStatusLabel.textColor = .warning
        addedLegacyStewardStatusLabel.font = TextFontStyle.style36.font
        
        addedLegacyStewardStatusView.backgroundColor = .white
        addedLegacyStewardStatusView.layer.backgroundColor = UIColor.lightWarning.cgColor
        addedLegacyStewardStatusView.layer.cornerRadius = 4
    }
    
    private func addSelectedStewardText() {
        if let name = viewModel?.selectedSteward?.name, let email = viewModel?.selectedSteward?.email, let status = viewModel?.selectedSteward?.currentStatus() {
            let paragraphStyleName = NSMutableParagraphStyle()
            paragraphStyleName.lineHeightMultiple = 1.36
            addedLegacyStewardName.attributedText = NSMutableAttributedString(
                string: name,
                attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyleName]
            )
            
            let paragraphStyleEmail = NSMutableParagraphStyle()
            paragraphStyleEmail.lineHeightMultiple = 1.36
            
            addedLegacyStewardEmail.attributedText = NSMutableAttributedString(
                string: email,
                attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyleEmail]
            )
            
            let paragraphStyleStatus = NSMutableParagraphStyle()
            paragraphStyleStatus.lineHeightMultiple = 1.47
            
            addedLegacyStewardStatusLabel.textAlignment = .center
            addedLegacyStewardStatusLabel.attributedText = NSMutableAttributedString(
                string: status.uppercased(),
                attributes: [
                    NSAttributedString.Key.kern: 0.8,
                    NSAttributedString.Key.paragraphStyle: paragraphStyleStatus
                ]
            )
        }
    }
    
    private func formatAddedLegacyStewardDeleteButton() {
        addedLegacyStewardDeleteButton.setImage(UIImage(named: "deleteLegacySteward")?.withRenderingMode(.alwaysTemplate), for: .normal)
        addedLegacyStewardDeleteButton.tintColor = .lightRed
    }
    
    func updateTrustedSteward() {
        if let _ = viewModel?.selectedSteward {
            UIView.animate(withDuration: 0.4, animations: {
                self.separatorView.isHidden = false
                self.addLegacyStewardView.isHidden = true
                self.addedLegacyStewardView.isHidden = false
                self.view.layoutIfNeeded()
            })
            addSelectedStewardText()
        } else {
            UIView.animate(withDuration: 0.4, animations: {
                self.separatorView.isHidden = false
                self.addLegacyStewardView.isHidden = false
                self.addedLegacyStewardView.isHidden = true
                self.view.layoutIfNeeded()
            })
        }
    }
    
    private func customizeSeparatorView() {
        separatorView.alpha = 0.08

        separatorView.layer.backgroundColor = UIColor.middleGray.cgColor
        separatorView.layer.cornerRadius = 2

        alertLegacyStewardSeparatorView.layer.backgroundColor = UIColor(red: 0.998, green: 0.874, blue: 0.536, alpha: 1).cgColor
        alertLegacyStewardSeparatorView.layer.cornerRadius = 2
    }
    
    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func editButtonTapped(_ sender: Any) {
        navigateToAdd()
    }
    
    @IBAction func saveArchiveLegacyButtonAction(_ sender: Any) {
        if let statusViewController = UIViewController.create(withIdentifier: .legacyPlanningStatus, from: .legacyPlanning) as? LegacyPlanningStatusViewController {
            statusViewController.viewModel = LegacyPlanningStatusViewModel()
            navigationController?.viewControllers = [statusViewController]
        }
    }
    
    @IBAction func addLegacyPersonButtonAction(_ sender: Any) {
        navigateToAdd()
    }
    
    @IBAction func deleteAddedLegacyPersonButtonAction(_ sender: Any) {

    }
    
    @IBAction func designateLegacyContact(_ sender: Any) {
        let presentingVC = self.presentingViewController
        dismiss(animated: true) { [weak self] in
            let legacyPlanningLoadingVC = LegacyPlanningLoadingViewController()
            legacyPlanningLoadingVC.viewModel = LegacyPlanningViewModel()
            legacyPlanningLoadingVC.viewModel?.account = self?.viewModel?.account
            let host = NavigationController(rootViewController: legacyPlanningLoadingVC)
            host.modalPresentationStyle = .fullScreen
            if !Constants.Design.isPhone {
                host.modalPresentationStyle = .formSheet
            }
            
            presentingVC?.present(host, animated: true, completion: nil)
        }
    }
    
    func navigateToAdd() {
        if let trustedStewardVC = UIViewController.create(withIdentifier: .trustedSteward, from: .legacyPlanning) as? TrustedStewardViewController {
            trustedStewardVC.viewModel = viewModel
            let navControl = NavigationController(rootViewController: trustedStewardVC)
            navControl.modalPresentationStyle = .fullScreen
            if !Constants.Design.isPhone {
                navControl.modalPresentationStyle = .formSheet
            }
            self.present(navControl, animated: true, completion: nil)
        }
    }
    
    private func updateArchiveStewardButtonState(hasAccountSteward: Bool) {
        guard viewModel?.stewardType == .archive else { return }
        
        // Update button and label state
        let isEnabled = hasAccountSteward
        addLegacyStewardButton.isEnabled = isEnabled
        addLegacyStewardLabel.isUserInteractionEnabled = isEnabled
        
        // Update visual appearance and show/hide info label
        if isEnabled {
            addLegacyStewardLabel.textColor = .darkBlue
            addLegacyStewardButton.tintColor = .darkBlue
            addLegacyStewardLabel.alpha = 1.0
            addLegacyStewardButton.alpha = 1.0
        } else {
            addLegacyStewardLabel.textColor = .middleGray
            addLegacyStewardButton.tintColor = .middleGray
            addLegacyStewardLabel.alpha = 0.6
            addLegacyStewardButton.alpha = 0.6
        }
        
        // Update visibility of archive details and alert views based on account steward status
        if hasAccountSteward {
            topArchiveDetailsView.isHidden = false
            topArchiveDetailsHeightConstraint.constant = 88
            alertAccountStewardView.isHidden = true
            saveArchiveLegacyButton.isHidden = false
        } else {
            topArchiveDetailsView.isHidden = true
            topArchiveDetailsHeightConstraint.constant = 0
            alertAccountStewardView.isHidden = false
            saveArchiveLegacyButton.isHidden = true
        }
    }
}
