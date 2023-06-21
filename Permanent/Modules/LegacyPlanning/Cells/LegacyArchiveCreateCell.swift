//
//  LegacyArchiveCreateCell.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 16.05.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import UIKit

class LegacyArchiveCreateCell: UITableViewCell {
    
    var goToCreate: (() -> Void)?
    
    func setup(data: (archive: ArchiveVOData, steward: ArchiveSteward?)) {
        name.text = "\(data.archive.fullName ?? "") Archive"
        loadImage(archive: data.archive)
        if let archiveRole = data.archive.accessRole {
            let accessRole = AccessRole.roleForValue(archiveRole).groupName
            role.text = accessRole.uppercased()
        }
    }
    
    func loadImage(archive: ArchiveVOData) {
        if let imageThumbnail = archive.thumbURL500 {
            icon.sd_setImage(with: URL(string: imageThumbnail))
        }
    }
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var role: UILabel!
    
    @IBAction func create(_ sender: Any) {
        goToCreate?()
    }
}
