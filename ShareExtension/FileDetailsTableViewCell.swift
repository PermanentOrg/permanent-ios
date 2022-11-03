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
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var rightImageView: UIImageView!
    
    var rightButtonAction: ((FileDetailsTableViewCell) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        fileNameLabel.font = .systemFont(ofSize: 16)
        fileSizeLabel.font = .systemFont(ofSize: 12)
        fileNameLabel.textColor = .black
        fileSizeLabel.textColor = .dustyGray
        rightImageView.image = UIImage(named: "close")?.templated
        rightImageView.tintColor = .primary
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func configure(with configuration: ShareExtensionCellConfiguration) {
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
    
    @IBAction func rightButtonPressed(_ sender: Any) {
        rightButtonAction?(self)
    }
}
