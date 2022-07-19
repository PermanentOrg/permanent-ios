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
    
    func configure(with configuration: ConfigurationForShareExtensionCell) {
        fileNameLabel.font = .systemFont(ofSize: 16)
        fileSizeLabel.font = .systemFont(ofSize: 12)
        fileNameLabel.textColor = .black
        fileSizeLabel.textColor = .dustyGray
        
        if let image = configuration.fileImage {
            thumbnailImageView.image = image

        }
        if let name = configuration.fileName, let size = configuration.fileSize {
            fileNameLabel.text = name
            fileSizeLabel.text = size
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
