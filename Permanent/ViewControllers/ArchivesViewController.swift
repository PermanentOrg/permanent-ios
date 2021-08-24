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
    
    private let overlayView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }
    
    private func initUI() {
        currentArchiveLabel.text = "Current Archive".localized()
        currentArchiveLabel.font = Text.style8.font
        currentArchiveLabel.textColor = .darkBlue
        
        currentArhiveNameLabel.font = Text.style16.font
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
            
            currentArhiveNameLabel.text = "<ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
        }
    }
}
