//
//  LegacyArchiveCreateCell.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 16.05.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import UIKit

class LegacyArchiveCreateCell: UITableViewCell {
    
    func setup(data: (archive: ArchiveVOData, steward: ArchiveSteward?)) {
        name.text = "\(data.archive.fullName ?? "") Archive"
        nameAbbreviation.text = data.archive.shortName()
    }
    
    @IBOutlet weak var nameAbbreviation: UILabel!
    @IBOutlet weak var name: UILabel!
    
    @IBAction func create(_ sender: Any) {
    }
}
