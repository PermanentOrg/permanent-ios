//
//  LegacyArchiveCreateCell.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 16.05.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import UIKit

class LegacyArchiveCreateCell: UITableViewCell {
    
    func setup(directive: Directive) {
        name.text = directive.stewardName
    }
    
    @IBOutlet weak var nameAbbreviation: UILabel!
    @IBOutlet weak var name: UILabel!
    
    @IBAction func create(_ sender: Any) {
    }
}
