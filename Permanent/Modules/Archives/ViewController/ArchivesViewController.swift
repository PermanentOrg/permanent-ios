//
//  ArchivesViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 20.08.2021.
//

import UIKit

protocol ArchivesViewControllerDelegate: AnyObject {
    func archivesViewController(_ vc: ArchivesViewController, shouldChangeToArchive toArchive: ArchiveVOData) -> Bool
    func archivesViewControllerDidChangeArchive(_ vc: ArchivesViewController)
}

extension ArchivesViewControllerDelegate {
    func archivesViewController(_ vc: ArchivesViewController, shouldChangeToArchive toArchive: ArchiveVOData) -> Bool {
        return true
    }
}
 
class ArchivesViewController: BaseViewController<ArchivesViewModel> {
    @IBOutlet weak var currentArchiveContainer: UIView!
    @IBOutlet weak var currentArhiveImage: UIImageView!
    @IBOutlet weak var currentArchiveLabel: UILabel!
    @IBOutlet weak var currentArhiveNameLabel: UILabel!
    @IBOutlet weak var createNewArchiveButton: RoundedButton!
    @IBOutlet weak var currentArchiveRightButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentArchiveDefaultIcon: UIImageView!
    
    weak var delegate: ArchivesViewControllerDelegate?
    var isManaging = true
    
    var accountArchives: [ArchiveVOData]?
    
    private let overlayView = UIView()
    private var tableViewSections: [ArchiveVOData.Status] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = ArchivesViewModel()
        
        updateArchivesList()
        initUI()
        setupTableView()
        styleNavBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }
    
    override func styleNavBar() {
        super.styleNavBar()
        
        if isManaging {
            title = "Archives".localized()
        } else {
            title = "Change Archive".localized()
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed(_:)))
        }
    }
    
    private func initUI() {
        currentArchiveContainer.layer.borderWidth = 1
        currentArchiveContainer.layer.borderColor = UIColor.gray.cgColor
        
        currentArchiveLabel.text = "Current Archive".localized()
        currentArchiveLabel.font = TextFontStyle.style7.font
        currentArchiveLabel.textColor = .darkBlue
        
        currentArhiveNameLabel.text = nil
        currentArhiveNameLabel.font = TextFontStyle.style17.font
        currentArhiveNameLabel.textColor = .darkBlue
        
        createNewArchiveButton.configureActionButtonUI(title: String("Create new archive".localized()))
        createNewArchiveButton.isHidden = !isManaging
        tableViewBottomConstraint.constant = isManaging ? 80 : 20
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0.0
    }
    
    fileprivate func setupTableView() {
        tableView.separatorColor = .clear
        
        tableView.register(UINib(nibName: String(describing: ArchiveScreenChooseArchiveDetailsTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: ArchiveScreenChooseArchiveDetailsTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: ArchiveScreenPendingArchiveDetailsTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: ArchiveScreenPendingArchiveDetailsTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: ArchiveScreenSectionTitleTableViewCell.self), bundle: nil), forHeaderFooterViewReuseIdentifier: String(describing: ArchiveScreenSectionTitleTableViewCell.self))
    }
    
    // MARK: - Actions
    @IBAction func createNewArchiveAction(_ sender: Any) {
        var archiveTypes = ArchiveType.allCases.map{$0.archiveName}
        
        if let removeItemIdx = archiveTypes.firstIndex(of: ArchiveType.nonProfit.archiveName) {
            archiveTypes.remove(at: removeItemIdx)
        }
        
        self.showActionDialog(
            styled: .inputWithDropdown,
            withTitle: "Create new archive".localized(),
            placeholders: ["Archive name".localized(), "Archive Type".localized()],
            dropdownValues: archiveTypes,
            positiveButtonTitle: .create,
            positiveAction: {
                if let fieldsInput = self.actionDialog?.fieldsInput,
                    let name = fieldsInput.first,
                    let typeValue = fieldsInput.last,
                    let type = ArchiveType.create(localizedValue: typeValue) {
                    self.actionDialog?.positiveButton.isEnabled = false
                    self.actionDialog?.cancelButton.isEnabled = false
                    self.viewModel?.createArchive(name: name, type: type.rawValue, { success, error in
                        if success {
                            self.updateArchivesList()
                        } else {
                            self.showAlert(title: .error, message: .errorMessage)
                        }
                        
                        self.actionDialog?.dismiss()
                        self.actionDialog = nil
                    })
                }
            },
            overlayView: self.overlayView
        )
    }
    
    @IBAction func currentArchiveRightButtonPressed(_ sender: Any) {
        var actions: [PRMNTAction] = []
        
        if viewModel?.currentArchive()?.archiveID != self.viewModel?.defaultArchiveId {
            actions.insert(PRMNTAction(title: "Make Default".localized(), iconName: "star-fill", color: .primary, handler: { [weak self] action in
                guard let archiveId = self?.viewModel?.currentArchive()?.archiveID else { return }
                self?.showSpinner()
                self?.viewModel?.updateAccount(withDefaultArchiveId: archiveId, { accountVO, error in
                    self?.hideSpinner()
                    if error == nil {
                        self?.updateCurrentArchive()
                        self?.tableView.reloadData()
                    } else {
                        self?.showAlert(title: .error, message: .errorMessage)
                    }
                })
            }), at: 0)
        }
        if AccessRole.roleForValue(viewModel?.currentArchive()?.accessRole ?? "") == .owner {
            actions.insert(PRMNTAction(title: "Configure Archive Steward".localized(), iconName: "legacyPlanning", color: .primary, handler: { [weak self] action in
                self?.presentArchiveStewardScreen(archiveData: self?.viewModel?.currentArchive())
            }), at: 0)
        }
        let actionSheet = PRMNTActionSheetViewController(title: currentArchiveLabel.text, actions: actions)
        present(actionSheet, animated: true)
    }
    
    @objc func doneButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func switchToArchive(_ archive: ArchiveVOData) {
        showSpinner()
        
        viewModel?.changeArchive(archive, { [self] success, error in
            hideSpinner()
            
            if success {
                updateCurrentArchive()
                tableView.reloadData()
                
                delegate?.archivesViewControllerDidChangeArchive(self)
            } else {
                showAlert(title: .error, message: .errorMessage)
            }
        })
    }
    
    func deleteArchive(_ archiveVO: ArchiveVOData) {
        showSpinner()
        viewModel?.deleteArchive(archiveId: archiveVO.archiveID, archiveNbr: archiveVO.archiveNbr, { [self] success, error in
            hideSpinner()
            if success {
                updateCurrentArchive()
                updateArchivesList()
            } else {
                showAlert(title: .error, message: .errorMessage)
            }
        })
    }
    
    // MARK: - UI
    func updateCurrentArchive() {
        if let archive = viewModel?.currentArchive(),
           let archiveName: String = archive.fullName,
           let archiveThumbURL: String = archive.thumbURL500 {
            currentArhiveImage.image = nil
            currentArchiveRightButton.isHidden = true
            currentArhiveImage.load(urlString: archiveThumbURL)
            
            currentArhiveNameLabel.text = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
            if AppEnvironment.shared.isRunningInAppExtension() {
                if archive.archiveID == viewModel?.defaultArchiveId {
                    currentArchiveRightButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
                    currentArchiveRightButton.isEnabled = false
                    currentArchiveRightButton.isHidden = false
                } else {
                    currentArchiveRightButton.isHidden = true
                }
            } else {
                currentArchiveRightButton.isHidden = false
                if archive.archiveID == viewModel?.defaultArchiveId || isManaging {
                    currentArchiveRightButton.setImage(UIImage(named: "more"), for: .normal)
                    currentArchiveRightButton.isEnabled = true
                    currentArchiveDefaultIcon.isHidden = !(archive.archiveID == viewModel?.defaultArchiveId)
                } else {
                    currentArchiveRightButton.isHidden = true
                }
            }
        }
    }
    
    func updateArchivesList() {
        showSpinner()
        
        viewModel?.getAccountInfo({ [self] account, error in
            if error == nil {
                if let currentArchives = self.accountArchives {
                    hideSpinner()
                    
                    viewModel?.allArchives = currentArchives
                    self.accountArchives = nil
                    tableView.reloadData()
                    updateCurrentArchive()
                } else {
                    viewModel?.getAccountArchives { [self] accountArchives, error in
                        hideSpinner()
                        
                        if error == nil {
                            tableView.reloadData()
                            updateCurrentArchive()
                        } else {
                            showAlert(title: .error, message: .errorMessage)
                        }
                    }
                }
            } else {
                showAlert(title: .error, message: .errorMessage)
            }
        })
    }
    
    private func rightButtonAction(archiveName: String, archiveThumbnail: String, archive: ArchiveVOData) -> ((ArchiveScreenChooseArchiveDetailsTableViewCell) -> Void) {
        return { [weak self] cell in
            guard let archiveVO = cell.archiveData else { return }
            var actions: [PRMNTAction] = []
            if archiveVO.archiveID != self?.viewModel?.defaultArchiveId
            {
                actions.insert(PRMNTAction(title: "Make Default".localized(), iconName: "star-fill", color: .primary, handler: { action in
                    guard let archiveId = archiveVO.archiveID else { return }
                    self?.showSpinner()
                    self?.viewModel?.updateAccount(withDefaultArchiveId: archiveId, { accountVO, error in
                        self?.hideSpinner()
                        if error == nil {
                            self?.updateCurrentArchive()
                            self?.tableView.reloadData()
                        } else {
                            self?.showAlert(title: .error, message: .errorMessage)
                        }
                    })
                }), at: 0)
            }
            
            if AccessRole.roleForValue(archiveVO.accessRole ?? "") == .owner {
                actions.insert(PRMNTAction(title: "Configure Archive Steward".localized(), iconName: "legacyPlanning", color: .primary, handler: { [weak self] action in
                    self?.presentArchiveStewardScreen(archiveData: archive)
                }), at: 0)
                
                actions.insert(PRMNTAction(title: "Delete Archive".localized(), iconName: "Delete-1", color: .destructive, handler: { [self] action in
                    let description = "Are you sure you want to permanently delete The <ARCHIVE_NAME> Archive?".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveVO.fullName ?? "")
                    
                    self?.showActionDialog(
                        styled: .simpleWithDescription,
                        withTitle: description,
                        description: "",
                        positiveButtonTitle: "Delete".localized(),
                        positiveAction: {
                            self?.actionDialog?.dismiss()
                            self?.deleteArchive(archiveVO)
                        },
                        cancelButtonTitle: "Cancel".localized(),
                        positiveButtonColor: .brightRed,
                        cancelButtonColor: .primary,
                        overlayView: self?.overlayView
                    )
                }), at: 0)
            }
            
            let actionSheet = PRMNTActionSheetViewController(title: archiveName, thumbnail: archiveThumbnail, actions: actions)
            self?.present(actionSheet, animated: true)
        }
    }
    
    private func acceptButtonAction() -> ((ArchiveScreenPendingArchiveDetailsTableViewCell) -> Void) {
        return { [weak self] cell in
            self?.showSpinner()
            guard let archiveData = cell.archiveData else { return }
            self?.viewModel?.pendingArchiveOperation(archive: archiveData, accept: true, { success, error in
                self?.hideSpinner()
                if error == nil {
                    self?.updateArchivesList()
                } else {
                    self?.showAlert(title: .error, message: .errorMessage)
                }
            })
        }
    }
        
    private func declineButtonAction() -> ((ArchiveScreenPendingArchiveDetailsTableViewCell) -> Void) {
        return { [weak self] cell in
            self?.showSpinner()
            guard let archiveData = cell.archiveData else { return }
            self?.viewModel?.pendingArchiveOperation(archive: archiveData, accept: false, { success, error in
                self?.hideSpinner()
                if error == nil {
                    self?.updateArchivesList()
                } else {
                    self?.showAlert(title: .error, message: .errorMessage)
                }
            })
        }
    }
    
    private func presentArchiveStewardScreen(archiveData: ArchiveVOData?) {
        if let archiveLegacyPlanningVC = UIViewController.create(withIdentifier: .legacyPlanningSteward, from: .legacyPlanning) as? LegacyPlanningStewardViewController, let archiveData = archiveData {
            archiveLegacyPlanningVC.viewModel = LegacyPlanningViewModel()
            archiveLegacyPlanningVC.selectedArchive = archiveData
            archiveLegacyPlanningVC.viewModel?.account = viewModel?.account
            archiveLegacyPlanningVC.viewModel?.stewardType = .archive
            let navControl = NavigationController(rootViewController: archiveLegacyPlanningVC)
            navControl.modalPresentationStyle = .fullScreen
            self.present(navControl, animated: true, completion: nil)
        }
    }
}

extension ArchivesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfItemsInSection = 0
        
        if tableViewSections[section] == .pending {
            numberOfItemsInSection = viewModel?.pendingArchives.count ?? 0
        }
        if tableViewSections[section] == .ok {
            numberOfItemsInSection = viewModel?.selectableArchives.count ?? 0
        }

        return numberOfItemsInSection
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if tableViewSections[indexPath.section] == .ok {
            if let tableViewCell = tableView.dequeueReusableCell(withIdentifier: String(describing: ArchiveScreenChooseArchiveDetailsTableViewCell.self)) as? ArchiveScreenChooseArchiveDetailsTableViewCell,
                let tableViewData = viewModel?.selectableArchives {
                let archiveVO = tableViewData[indexPath.row]
                tableViewCell.updateCell(withArchiveVO: archiveVO, isDefault: archiveVO.archiveID == viewModel?.defaultArchiveId, isManaging: isManaging)

                tableViewCell.rightButtonAction = rightButtonAction(archiveName: archiveVO.fullName ?? "", archiveThumbnail: archiveVO.thumbURL200 ?? "", archive: archiveVO)
                
                cell = tableViewCell
            }
        } else if tableViewSections[indexPath.section] == .pending {
            if let tableViewCell = tableView.dequeueReusableCell(withIdentifier: String(describing: ArchiveScreenPendingArchiveDetailsTableViewCell.self)) as? ArchiveScreenPendingArchiveDetailsTableViewCell,
                let tableViewData = viewModel?.pendingArchives {
                let archiveVO = tableViewData[indexPath.row]
                tableViewCell.updateCell(withArchiveVO: archiveVO)
                
                tableViewCell.acceptButtonAction = acceptButtonAction()
                
                tableViewCell.declineButtonAction = declineButtonAction()
                
                cell = tableViewCell
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableViewSections[indexPath.section] == .ok {
            let tableViewData = viewModel?.selectableArchives
            if let archive = tableViewData?[indexPath.row], delegate?.archivesViewController(self, shouldChangeToArchive: archive) ?? true {
                switchToArchive(archive)
                
                tableView.deselectRow(at: indexPath, animated: true)
                if !isManaging {
                    dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        tableViewSections = []
        if let pendingArchives = viewModel?.pendingArchives,
            !pendingArchives.isEmpty,
            isManaging {
            tableViewSections.append(ArchiveVOData.Status.pending)
        }
        if let selectableArchives = viewModel?.selectableArchives,
            !selectableArchives.isEmpty {
            tableViewSections.append(ArchiveVOData.Status.ok)
        }
        return tableViewSections.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        if let headerCell = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: ArchiveScreenSectionTitleTableViewCell.self)) as? ArchiveScreenSectionTitleTableViewCell {
            headerCell.updateCell(with: tableViewSections[section])
            headerView.addSubview(headerCell)
        }

        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if tableViewSections[indexPath.section] == .pending {
            return false
        }
        return true
    }
}
