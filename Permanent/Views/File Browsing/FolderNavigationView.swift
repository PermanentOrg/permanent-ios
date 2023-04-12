//
//  FolderNavigationView.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 20.10.2022.
//

import UIKit

class FolderNavigationView: UIView {
    var viewModel: FolderNavigationViewModel? {
        didSet {
            let hasBackButton = viewModel?.hasBackButton ?? false
            let folderName = viewModel?.displayName ?? ""
            
            folderTitleLabel.text = hasBackButton ? "<  " + folderName : folderName
            initUI()
        }
    }
    
    let folderTitleLabel = UILabel()
    let segmentedControl = UISegmentedControl(items: ["", ""])
    
    init() {
        super.init(frame: .zero)
        
        NotificationCenter.default.addObserver(forName: FolderNavigationViewModel.didUpdateFolderStackNotification, object: nil, queue: nil) { [weak self] notif in
            guard let self = self
            else {
                return
            }
            
            let hasBackButton = self.viewModel?.hasBackButton ?? false
            let folderName = self.viewModel?.displayName ?? ""
            self.folderTitleLabel.text = hasBackButton ? "<  " + folderName : folderName
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI() {
        backgroundColor = .backgroundPrimary
        
        folderTitleLabel.font = Text.style3.font
        folderTitleLabel.textColor = .primary
        folderTitleLabel.text = viewModel?.displayName
        folderTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(folderTitleLabel)
        
        if let workspace = viewModel?.workspace, (workspace == Workspace.sharedByMeFiles || workspace == Workspace.shareWithMeFiles) {
            segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: Text.style11.font], for: .selected)
            segmentedControl.setTitleTextAttributes([.font: Text.style8.font], for: .normal)
            segmentedControl.setTitle(.sharedByMe, forSegmentAt: 0)
            segmentedControl.setTitle(.sharedWithMe, forSegmentAt: 1)
            
            if #available(iOS 13.0, *) {
                segmentedControl.selectedSegmentTintColor = .primary
            }
            
            segmentedControl.translatesAutoresizingMaskIntoConstraints = false
            addSubview(segmentedControl)
            
            NSLayoutConstraint.activate([
                segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
                segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
                segmentedControl.topAnchor.constraint(equalTo: topAnchor, constant: 20),
                folderTitleLabel.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
                folderTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
                folderTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
                folderTitleLabel.heightAnchor.constraint(equalToConstant: 40),
            ])
            
            segmentedControl.selectedSegmentIndex = 0
            segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
        } else {
            NSLayoutConstraint.activate([
                folderTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                folderTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                folderTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 0),
                folderTitleLabel.heightAnchor.constraint(equalToConstant: 40)
            ])
        }
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:))))
    }
    
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        viewModel?.popFolder()
    }
    
    @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        viewModel?.workspace = sender.selectedSegmentIndex == 0 ? .shareWithMeFiles : .sharedByMeFiles
        NotificationCenter.default.post(name: FolderNavigationViewModel.didChangeSegmentedControlValueNotification, object: self, userInfo: ["workspace": viewModel?.workspace])
    }
}
