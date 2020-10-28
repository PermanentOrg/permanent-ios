//
//  FileTableViewCell.swift
//  Permanent
//
//  Created by Adrian Creteanu on 13/10/2020.
//

import UIKit

class FileTableViewCell: UITableViewCell {
    @IBOutlet var fileNameLabel: UILabel!
    @IBOutlet var fileDateLabel: UILabel!
    @IBOutlet var moreButton: UIButton!
    @IBOutlet var fileImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        initUI()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func initUI() {
        fileNameLabel.font = Text.style11.font
        fileNameLabel.textColor = .middleGray
        fileDateLabel.font = Text.style12.font
        fileDateLabel.textColor = .middleGray
        fileImageView.clipsToBounds = true
    }
    
    func updateCell(model: FileViewModel) {
        fileNameLabel.text = model.name
        fileDateLabel.text = model.date
        
        if !model.type.isFolder {
            // TODO: See how to handle this better.
            fileImageView.load(urlString: model.thumbnail)
        } else {
            fileImageView.image = UIImage(named: "folder")
        }
    }
    
}
