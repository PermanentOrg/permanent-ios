//
//  ArchivesViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 20.08.2021.
//

import UIKit

class ArchivesViewController: BaseViewController<ArchivesViewModel> {
    
    @IBOutlet weak var currentArchiveContainer: UIView!
    @IBOutlet weak var currentArhiveImage: UIImageView!
    @IBOutlet weak var currentArchiveLabel: UILabel!
    @IBOutlet weak var currentArhiveNameLabel: UILabel!
    @IBOutlet weak var chooseArchiveName: UILabel!
    @IBOutlet weak var createNewArchiveButton: RoundedButton!
    @IBOutlet weak var currentArchiveRightButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    private let overlayView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = ArchivesViewModel()
        
        updateArchivesList()
        initUI()
        setupTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }
    
    private func initUI() {
        currentArchiveContainer.layer.borderWidth = 1
        currentArchiveContainer.layer.borderColor = UIColor.gray.cgColor
        
        currentArchiveLabel.text = "Current Archive".localized()
        currentArchiveLabel.font = Text.style7.font
        currentArchiveLabel.textColor = .darkBlue
        
        currentArhiveNameLabel.font = Text.style17.font
        currentArhiveNameLabel.textColor = .darkBlue
        
        chooseArchiveName.text = "Choose Archive:".localized()
        chooseArchiveName.font = Text.style3.font
        chooseArchiveName.textColor = .darkBlue
        
        createNewArchiveButton.configureActionButtonUI(title: String("Create new archive".localized()))
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0.0
    }
    
    fileprivate func setupTableView() {
        tableView.separatorColor = .clear
        
        tableView.register(UINib(nibName: String(describing: ArchiveScreenDetailsTableViewCell.self), bundle: nil),
                           forCellReuseIdentifier: String(describing: ArchiveScreenDetailsTableViewCell.self))
    }
    
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
                    updateCurrentArchive()
                    tableView.reloadData()
                })
            })
        ])
        present(actionSheet, animated: true)
    }
    
    func updateCurrentArchive() {
        if let archive = viewModel?.currentArchive(),
           let archiveName: String = archive.fullName,
           let archiveThumbURL: String = archive.thumbURL500 {
            currentArhiveImage.image = nil
            currentArhiveImage.load(urlString: archiveThumbURL)
            
            currentArhiveNameLabel.text = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
            
            if archive.archiveID == viewModel?.defaultArchiveId {
                if #available(iOS 13.0, *) {
                    currentArchiveRightButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
                } else {
                    currentArchiveRightButton.setImage(UIImage(named: "star.fill"), for: .normal)
                }
                currentArchiveRightButton.isEnabled = false
            } else {
                currentArchiveRightButton.setImage(UIImage(named: "more"), for: .normal)
                currentArchiveRightButton.isEnabled = true
            }
        }
    }
    
    func updateArchivesList() {
        showSpinner()
        
        viewModel?.getAccountInfo({ [self] account, error in
            viewModel?.getAccountArchives { [self] accountArchives, error in
                tableView.reloadData()
                updateCurrentArchive()
                hideSpinner()
            }
        })
    }
    
    func switchToArchive(_ archive: ArchiveVOData) {
        viewModel?.changeArchive(archive, { [self] success, error in
            if success {
                updateCurrentArchive()
                tableView.reloadData()
            }
        })
    }
}

extension ArchivesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.availableArchives.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if let tableViewCell = tableView.dequeueReusableCell(withIdentifier: String(describing: ArchiveScreenDetailsTableViewCell.self)) as? ArchiveScreenDetailsTableViewCell,
           let tableViewData = viewModel?.availableArchives {
            let archiveVO = tableViewData[indexPath.row]
            tableViewCell.updateCell(withArchiveVO: archiveVO, isDefault: archiveVO.archiveID == viewModel?.defaultArchiveId)
            tableViewCell.rightButtonAction = { [weak self] cell in
                let actionSheet = PRMNTActionSheetViewController(actions: [
                    PRMNTAction(title: "Delete Archive".localized(), color: .destructive, handler: { action in
                        print("delete")
                    }),
                    PRMNTAction(title: "Make Default".localized(), color: .primary, handler: { action in
                        guard let archiveId = self?.viewModel?.currentArchive()?.archiveID else { return }
                        self?.showSpinner()
                        self?.viewModel?.updateAccount(withDefaultArchiveId: archiveId, { accountVO, error in
                            self?.hideSpinner()
                            self?.updateCurrentArchive()
                            tableView.reloadData()
                        })
                    })
                ])
                self?.present(actionSheet, animated: true)
            }
            
            cell = tableViewCell
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tableViewData = viewModel?.availableArchives
        if let archive = tableViewData?[indexPath.row],
           let archiveName = archive.fullName {
            let title = "Switch Archive".localized()
            let description = "Switch to The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
            
            self.showActionDialog(styled: .simpleWithDescription,
                                  withTitle: title,
                                  description: description,
                                  positiveButtonTitle: "Switch".localized(),
                                  positiveAction: {
                                    self.actionDialog?.dismiss()
                                    self.switchToArchive(archive)
                                  },
                                  cancelButtonTitle: "Cancel".localized(),
                                  positiveButtonColor: .primary,
                                  cancelButtonColor: .primary,
                                  overlayView: self.overlayView)
            
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
