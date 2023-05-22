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
    
    @IBOutlet weak var addLegacyStewardView: UIView!
    @IBOutlet weak var addedLegacyStewardView: UIView!
    @IBOutlet weak var addedLegacyStewardName: UILabel!
    @IBOutlet weak var addedLegacyStewardEmail: UILabel!
    @IBOutlet weak var addedLegacyStewardStatusView: UIView!
    @IBOutlet weak var addedLegacyStewardStatusLabel: UILabel!
    @IBOutlet weak var addedLegacyStewardDeleteButton: UIButton!
    var selectedArchive: ArchiveVOData?
    
    private let overlayView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.selectedArchive = selectedArchive
        viewModel?.getCurrentSteward()
        
        setupUI()
        styleNavBar()
        
        NotificationCenter.default.addObserver(forName: LegacyPlanningViewModel.didUpdateSelectedSteward, object: nil, queue: nil) { [weak self] notif in
            self?.updateTrustedSteward()
        }
        
        NotificationCenter.default.addObserver(forName: LegacyPlanningViewModel.isLoadingNotification, object: nil, queue: nil) { [weak self] notif in
            if let isLoading = self?.viewModel?.isLoading, isLoading {
                self?.showSpinner()
            } else {
                self?.hideSpinner()
            }
        }
        
        addedLegacyStewardDeleteButton.isHidden = true
    }
    
    override func styleNavBar() {
        super.styleNavBar()
    }
    
    private func setupUI() {
        view.backgroundColor = .backgroundPrimary
        view.layer.backgroundColor = UIColor.whiteGray.cgColor
        
        overlayView.frame = view.bounds
        view.addSubview(overlayView)
        overlayView.backgroundColor = .bgOverlay
        overlayView.alpha = 0
        
        titleLabelSetup()
        backButtonSetup()
        closeButtonSetup()
        addLegacyStewardSetup()
        addedLegacyStewardSetup()
        customizeSeparatorView()
        
        if let imageThumbnail = viewModel?.selectedArchive?.thumbURL500 {
            archiveThumbnailImage.sd_setImage(with: URL(string: imageThumbnail))
        }

        archiveNameLabelSetup(text: "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: viewModel?.selectedArchive?.fullName ?? ""))
        archivePermissionSetup(text: AccessRole.roleForValue(viewModel?.selectedArchive?.accessRole ?? "").groupName)
        designateStewardLabelSetup(text: "Designate an Archive Steward".localized())
        designateArchiveStewardLabelSetup(text: "Who should be the owner of this archive in the event of incapacitation?".localized())
        saveArchiveLegacyButtonSetup(text: "Save archive Legacy Plan".localized())
        trustedStewardTitleLabelSetup(text: "A trusted steward".localized())
        trustedStewardDescriptionLabelSetup(text: "The Archive steward will receive a note when your Legacy Plan is activated.".localized())
    }
    
    private func titleLabelSetup() {
        let titleLabel = UILabel()
        titleLabel.text = "Archive Legacy Planning".localized()
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
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: -20) // Adjust the position
        
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
    
    private func trustedStewardDescriptionLabelSetup(text: String) {
        trustedStewardDescriptionLabel.textColor = .black
        trustedStewardDescriptionLabel.font = TextFontStyle.style39.font
        trustedStewardDescriptionLabel.lineBreakMode = .byWordWrapping
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.36
        
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
    }
    
    private func addLegacyStewardSetup() {
        addLegacyStewardLabel.text = "Add Legacy Steward".localized()
        addLegacyStewardLabel.textColor = .darkBlue
        addLegacyStewardLabel.font = TextFontStyle.style44.font
        addLegacyStewardButton.setImage(UIImage(named: "addLegacyPerson")?.withRenderingMode(.alwaysTemplate), for: .normal)
        addLegacyStewardButton.tintColor = .darkBlue
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
            addLegacyStewardView.isHidden = true
            addedLegacyStewardView.isHidden = false
            
            addSelectedStewardText()
        } else {
            addLegacyStewardView.isHidden = false
            addedLegacyStewardView.isHidden = true
        }
        
        saveArchiveLegacyButton.isSelectable = viewModel?.selectedSteward?.status == .pending
    }
    
    private func customizeSeparatorView() {
        separatorView.alpha = 0.08

        separatorView.layer.backgroundColor = UIColor.middleGray.cgColor
        separatorView.layer.cornerRadius = 2
    }
    
    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveArchiveLegacyButtonAction(_ sender: Any) {
        if let statusViewController = UIViewController.create(withIdentifier: .legacyPlanningStatus, from: .legacyPlanning) as? LegacyPlanningStatusViewController {
            statusViewController.viewModel = viewModel
            navigationController?.viewControllers = [statusViewController]
        }
    }
    
    @IBAction func addLegacyPersonButtonAction(_ sender: Any) {
        if let trustedStewardVC = UIViewController.create(withIdentifier: .trustedSteward, from: .legacyPlanning) as? TrustedStewardViewController {
            trustedStewardVC.viewModel = viewModel
            let navControl = NavigationController(rootViewController: trustedStewardVC)
            self.present(navControl, animated: true, completion: nil)
        }
    }
    
    @IBAction func deleteAddedLegacyPersonButtonAction(_ sender: Any) {
    }
}
