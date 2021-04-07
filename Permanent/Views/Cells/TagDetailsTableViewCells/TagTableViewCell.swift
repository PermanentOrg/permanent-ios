//
//  TagTableViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 06.04.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class TagTableViewCell: UITableViewCell {
    
    @IBOutlet weak var tagNameLabel: UILabel!
    
    static let identifier = "TagTableViewCell"
 
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(name: String) {
        self.backgroundColor = .clear
        self.tintColor = .white
        
        tagNameLabel.textColor = .white
        tagNameLabel.font = Text.style9.font
        tagNameLabel.text = name

        
    }
}
