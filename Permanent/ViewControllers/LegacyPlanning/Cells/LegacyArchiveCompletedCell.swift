//
//  LegacyArchiveCompletedCell.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 16.05.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import UIKit

class LegacyArchiveCompletedCell: UITableViewCell {
    
    func setup(data: (archive: ArchiveVOData, steward: ArchiveSteward?)) {
        archiveName.text = "\(data.archive.fullName ?? "") Archive"
        shortArchiveName.text = data.archive.shortName()
    }
    
    @IBOutlet weak var shortArchiveName: UILabel!
    @IBOutlet weak var archiveName: UILabel!
    @IBOutlet weak var stewardName: UILabel!
    
    @IBAction func turnOff(_ sender: Any) {
    }
    
    @IBAction func editPlan(_ sender: Any) {
    }
}
