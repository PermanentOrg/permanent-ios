//
//  ArchivesViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 20.08.2021.
//

import UIKit

protocol ArchivesViewControllerDelegate: AnyObject {
    func archivesViewControllerDidChangeArchive(_ vc: ArchivesViewController)
}

class ArchivesViewController: BaseViewController<ArchivesViewModel> {
    
    @IBOutlet weak var currentArchiveContainer: UIView!
    @IBOutlet weak var currentArhiveImage: UIImageView!
    @IBOutlet weak var currentArchiveLabel: UILabel!
    @IBOutlet weak var currentArhiveNameLabel: UILabel!
    @IBOutlet weak var createNewArchiveButton: RoundedButton!
    @IBOutlet weak var currentArchiveRightButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: ArchivesViewControllerDelegate?
    var isManaging = true
    
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
            title = "Manage Archives".localized()
        } else {
            title = "Change Archive".localized()
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed(_:)))
        }
    }
    
    private func initUI() {
        currentArchiveContainer.layer.borderWidth = 1
        currentArchiveContainer.layer.borderColor = UIColor.gray.cgColor
        
        currentArchiveLabel.text = "Current Archive".localized()
        currentArchiveLabel.font = Text.style7.font
        currentArchiveLabel.textColor = .darkBlue
        
        currentArhiveNameLabel.text = nil
        currentArhiveNameLabel.font = Text.style17.font
        currentArhiveNameLabel.textColor = .darkBlue
        
        createNewArchiveButton.configureActionButtonUI(title: String("Create new archive".localized()))
        createNewArchiveButton.isHidden = !isManaging
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0.0
    }
    
    fileprivate func setupTableView() {
        tableView.separatorColor = .clear
        
        tableView.register(UINib(nibName: String(describing: ArchiveScreenChooseArchiveDetailsTableViewCell.self), bundle: nil),
                           forCellReuseIdentifier: String(describing: ArchiveScreenChooseArchiveDetailsTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: ArchiveScreenPendingArchiveDetailsTableViewCell.self), bundle: nil),
                           forCellReuseIdentifier: String(describing: ArchiveScreenPendingArchiveDetailsTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: ArchiveScreenSectionTitleTableViewCell.self), bundle: nil),
                           forCellReuseIdentifier: String(describing: ArchiveScreenSectionTitleTableViewCell.self))
    }
    
    // MARK: - Actions
    @IBAction func createNewArchiveAction(_ sender: Any) {
        self.showActionDialog(
            styled: .inputWithDropdown,
            withTitle: "Create new archive".localized(),
            placeholders: ["Archive name".localized(), "Archive Type".localized()],
            dropdownValues: StaticData.archiveTypes,
            positiveButtonTitle: .create,
            positiveAction: {
                if let fieldsInput = self.actionDialog?.fieldsInput,
                    let name = fieldsInput.first,
                    let typeValue = fieldsInput.last,
                    let type = ArchiveType.create(localizedValue: typeValue) {
                    self.viewModel?.createArchive(name: name, type: type.rawValue, { success, error in
                        if success {
                            self.updateArchivesList()
                        } else {
                            self.showAlert(title: .error, message: .errorMessage)
                        }
                        
                        self.actionDialog?.dismiss()
                    })
                }
            },
            overlayView: self.overlayView
        )
    }
    
    @IBAction func currentArchiveRightButtonPressed(_ sender: Any) {
        let actionSheet = PRMNTActionSheetViewController(actions: [
            PRMNTAction(title: "Make Default".localized(), color: .primary, handler: { [self] action in
                guard let archiveId = viewModel?.currentArchive()?.archiveID else { return }
                showSpinner()
                viewModel?.updateAccount(withDefaultArchiveId: archiveId, { accountVO, error in
                    hideSpinner()
                    if error == nil {
                        updateCurrentArchive()
                        tableView.reloadData()
                    } else {
                        showAlert(title: .error, message: .errorMessage)
                    }
                })
            })
        ])
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
            currentArhiveImage.load(urlString: archiveThumbURL)
            
            currentArhiveNameLabel.text = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
            
            currentArchiveRightButton.isHidden = false
            if archive.archiveID == viewModel?.defaultArchiveId {
                if #available(iOS 13.0, *) {
                    currentArchiveRightButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
                } else {
                    currentArchiveRightButton.setImage(UIImage(named: "star.fill"), for: .normal)
                }
                currentArchiveRightButton.isEnabled = false
            } else if isManaging {
                currentArchiveRightButton.setImage(UIImage(named: "more"), for: .normal)
                currentArchiveRightButton.isEnabled = true
            } else {
                currentArchiveRightButton.isHidden = true
            }
        }
    }
    
    func updateArchivesList() {
        showSpinner()
        
        viewModel?.getAccountInfo({ [self] account, error in
            if error == nil {
                viewModel?.getAccountArchives { [self] accountArchives, error in
                    hideSpinner()
                    
                    if error == nil {
                        tableView.reloadData()
                        updateCurrentArchive()
                    } else {
                        showAlert(title: .error, message: .errorMessage)
                    }
                }
            } else {
                showAlert(title: .error, message: .errorMessage)
            }
        })
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
                tableViewCell.rightButtonAction = { [weak self] cell in
                    var actions = [
                        PRMNTAction(title: "Make Default".localized(), color: .primary, handler: { action in
                            guard let archiveId = archiveVO.archiveID else { return }
                            self?.showSpinner()
                            self?.viewModel?.updateAccount(withDefaultArchiveId: archiveId, { accountVO, error in
                                self?.hideSpinner()
                                if error == nil {
                                    self?.updateCurrentArchive()
                                    tableView.reloadData()
                                } else {
                                    self?.showAlert(title: .error, message: .errorMessage)
                                }
                            })
                        })
                    ]
                    
                    if archiveVO.accessRole == "access.role.owner" {
                        actions.insert(PRMNTAction(title: "Delete Archive".localized(), color: .destructive, handler: { [self] action in
                            let description = "Are you sure you want to permanently delete The <ARCHIVE_NAME> Archive?".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveVO.fullName ?? "")
                            
                            self?.showActionDialog(styled: .simpleWithDescription,
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
                                                   overlayView: self?.overlayView)
                            
                        }), at: 0)
                    }
                    
                    let actionSheet = PRMNTActionSheetViewController(actions: actions)
                    self?.present(actionSheet, animated: true)
                }
                
                cell = tableViewCell
            }
            
        } else if tableViewSections[indexPath.section] == .pending {
            if let tableViewCell = tableView.dequeueReusableCell(withIdentifier: String(describing: ArchiveScreenPendingArchiveDetailsTableViewCell.self)) as? ArchiveScreenPendingArchiveDetailsTableViewCell,
               let tableViewData = viewModel?.pendingArchives {
                let archiveVO = tableViewData[indexPath.row]
                tableViewCell.updateCell(withArchiveVO: archiveVO)
                tableViewCell.acceptButtonAction = { [weak self] cell in
                    self?.showSpinner()
                    self?.viewModel?.pendingArchiveOperation(archive: archiveVO, accept: true, { success, error in
                        self?.hideSpinner()
                        if error == nil {
                            self?.updateArchivesList()
                        } else {
                            self?.showAlert(title: .error, message: .errorMessage)
                        }
                    })
                }
                
                tableViewCell.declineButtonAction = { [weak self] cell in
                    self?.showSpinner()
                    self?.viewModel?.pendingArchiveOperation(archive: archiveVO, accept: false, { success, error in
                        self?.hideSpinner()
                        if error == nil {
                            self?.updateArchivesList()
                        } else {
                            self?.showAlert(title: .error, message: .errorMessage)
                        }
                    })
                }
                
                cell = tableViewCell
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableViewSections[indexPath.section] == .ok {
            let tableViewData = viewModel?.selectableArchives
            if let archive = tableViewData?[indexPath.row] {
                switchToArchive(archive)
                
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        tableViewSections = []
        if let pendingArchives = viewModel?.pendingArchives,
           pendingArchives.count > 0,
           isManaging {
            tableViewSections.append(ArchiveVOData.Status.pending)
        }
        if let selectableArchives = viewModel?.selectableArchives,
           selectableArchives.count > 0{
            tableViewSections.append(ArchiveVOData.Status.ok)
        }
        return tableViewSections.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let headerView = UIView()
        if let headerCell = tableView.dequeueReusableCell(withIdentifier: String(describing: ArchiveScreenSectionTitleTableViewCell.self)) as? ArchiveScreenSectionTitleTableViewCell {
            headerCell.updateCell(with: tableViewSections[section])
            headerView.addSubview(headerCell)
        }

        return headerView
    }
}
