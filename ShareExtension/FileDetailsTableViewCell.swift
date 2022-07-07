//
//  FileDetailsTableViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.06.2022.
//

import UIKit

class FileDetailsTableViewCell: UITableViewCell {
    static let identifier = "fileDetailsCell"
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var fileSizeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func configure(fileImage: UIImage?, fileName: String?, fileSize: String?) {
        fileNameLabel.font = .systemFont(ofSize: 16)
        fileSizeLabel.font = .systemFont(ofSize: 12)
        fileSizeLabel.textColor = .dustyGray
        
        if let image = fileImage, let name = fileName, let size = fileSize {
            thumbnailImageView.image = image
            fileNameLabel.text = name
            fileSizeLabel.text = size
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
