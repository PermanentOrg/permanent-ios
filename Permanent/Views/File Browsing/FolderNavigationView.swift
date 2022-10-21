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
        }
    }
    
    let folderTitleLabel = UILabel()
    
    init() {
        super.init(frame: .zero)
        
        initUI()
        
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
        
        NSLayoutConstraint.activate([
            folderTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            folderTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 16),
            folderTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            folderTitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        ])
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:))))
    }
    
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        viewModel?.popFolder()
    }
}
