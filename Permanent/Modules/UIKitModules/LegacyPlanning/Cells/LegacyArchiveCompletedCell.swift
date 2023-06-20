//
//  LegacyArchiveCompletedCell.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 16.05.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import UIKit

class LegacyArchiveCompletedCell: UITableViewCell {
    
    var goToEdit: (() -> Void)?
    var turnOff: (() -> Void)?
    
    func setup(data: (archive: ArchiveVOData, steward: ArchiveSteward?)) {
        archiveName.text = "\(data.archive.fullName ?? "") Archive"
        loadImage(archive: data.archive)
        stewardName.text = data.steward?.steward?.name
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
    @IBOutlet weak var archiveName: UILabel!
    @IBOutlet weak var stewardName: UILabel!
    @IBOutlet weak var role: UILabel!
    
    @IBAction func turnOff(_ sender: Any) {
        turnOff?()
    }
    
    @IBAction func editPlan(_ sender: Any) {
        goToEdit?()
    }
}
