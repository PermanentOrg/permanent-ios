//
//  ArchivesViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 20.08.2021.
//

import UIKit

class ArchivesViewController: BaseViewController<AuthViewModel> {
    @IBOutlet weak var currentArhiveImage: UIImageView!
    @IBOutlet weak var currentArchiveLabel: UILabel!
    @IBOutlet weak var currentArhiveNameLabel: UILabel!
    @IBOutlet weak var chooseArchiveName: UILabel!
    @IBOutlet weak var createNewArchiveButton: RoundedButton!
    @IBOutlet weak var tableView: UITableView!
    
    private let overlayView = UIView()
    
    var tableViewData: [ArchiveVOData]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableViewData = []
        
        viewModel = AuthViewModel()
        
        getAccountArchives()
        
        initUI()
        
        setupTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }
    
    private func initUI() {
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
        
        updateCurrentArchive()
    }
    
    fileprivate func setupTableView() {
        tableView.separatorColor = .clear
        
        tableView.register(UINib(nibName: String(describing: ArchiveScreenDetailsTableViewCell.self), bundle: nil),
                           forCellReuseIdentifier: String(describing: ArchiveScreenDetailsTableViewCell.self))
    }
    
    @IBAction func CreateNewArchiveAction(_ sender: Any) {
        self.showActionDialog(
            styled: .inputWithDropdown,
            withTitle: "Create new archive".localized(),
            placeholders: ["Archive name".localized(), "Archive Type".localized()],
            dropdownValues: StaticData.archiveTypes,
            positiveButtonTitle: .create,
            positiveAction: {
                
            }, overlayView: self.overlayView)
    }
    
    func updateCurrentArchive() {
        if let archiveName: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.archiveName),
           let archiveThumbURL: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.archiveThumbUrl) {
            currentArhiveImage.image = nil
            currentArhiveImage.load(urlString: archiveThumbURL)
            
            currentArhiveNameLabel.text = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
        }
    }
    
    func getAccountArchives() {
        viewModel?.getAccountArchives { accountArchives, error in
            accountArchives?.forEach{ archive in
                if let archiveVOData = archive.archiveVO {
                    self.tableViewData?.append(archiveVOData)
                }
            }
            self.tableView.reloadData()
        }
    }
}

extension ArchivesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return tableViewData?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = ArchiveScreenDetailsTableViewCell()
        if let tableViewCell = tableView.dequeueReusableCell(withIdentifier: String(describing: ArchiveScreenDetailsTableViewCell.self)) as? ArchiveScreenDetailsTableViewCell,
           let archiveThumbString = tableViewData?[indexPath.row].thumbURL500,
           let archiveNameString = tableViewData?[indexPath.row].fullName,
           let archiveAccessString = tableViewData?[indexPath.row].accessRole {
            cell = tableViewCell
            cell.updateCell(with: archiveThumbString, archiveName: archiveNameString, accessLevel: AccessRole.roleForValue(archiveAccessString).groupName)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
