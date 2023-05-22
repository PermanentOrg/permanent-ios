//
//  LegacyArchiveCompletedCell.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 16.05.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import UIKit

class LegacyArchiveCompletedCell: UITableViewCell {
    
    func setup(directive: Directive) {
        name.text = directive.stewardName
    }
    
    @IBOutlet weak var name: UILabel!
    
    @IBAction func turnOff(_ sender: Any) {
    }
    
    @IBAction func editPlan(_ sender: Any) {
    }
}
