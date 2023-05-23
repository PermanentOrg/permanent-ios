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
        shortArchiveName.text = data.archive.shortName()
        stewardName.text = data.steward?.stewardAccountId
        if let archiveRole = data.archive.accessRole {
            let accessRole = AccessRole.roleForValue(archiveRole).groupName
            role.text = accessRole.uppercased()
        }
    }
    
    @IBOutlet weak var shortArchiveName: UILabel!
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
