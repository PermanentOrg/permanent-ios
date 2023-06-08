//
//  LegacyAccountStatusCell.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 16.05.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import UIKit

class LegacyAccountStatusCell: UITableViewCell {
    
    var goToEdit: (() -> Void)?
    var turnOff: (() -> Void)?
    
    func setup(account: AccountSteward?) {
        
        name.text = account?.name != nil ? account?.name : "No Legacy Contact Added"
    }
    
    @IBOutlet weak var name: UILabel!
    
    @IBAction func turnOff(_ sender: Any) {
        turnOff?()
    }
    
    @IBAction func editPlan(_ sender: Any) {
        goToEdit?()
    }
}
