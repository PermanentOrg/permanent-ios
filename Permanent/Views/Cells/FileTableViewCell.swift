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
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var dateStackView: UIStackView!
    
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
        
        statusLabel.font = Text.style12.font
        statusLabel.textColor = .middleGray
        statusLabel.text = Translations.waiting
        
        progressView.progressTintColor = .primary
        progressView.progress = 0.9
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
        
        handleUI(forStatus: model.fileStatus)
    }
    
    fileprivate func handleUI(forStatus status: FileStatus) {
        switch status {
        case .synced:
            progressView.isHidden = true
            statusLabel.isHidden = true
            dateStackView.isHidden = false
        case .waiting:
            dateStackView.isHidden = true
            progressView.isHidden = true
            statusLabel.isHidden = false
            
        case .uploading:
            dateStackView.isHidden = true
            statusLabel.isHidden = true
            progressView.isHidden = false
            progressView.setProgress(0.8, animated: true)
        }
    }
}
