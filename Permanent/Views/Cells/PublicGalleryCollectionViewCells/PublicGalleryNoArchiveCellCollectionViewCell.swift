//
//  PublicGalleryNoArchiveCellCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.05.2022.
//

import UIKit

class PublicGalleryNoArchiveCellCollectionViewCell: UICollectionViewCell {
    static let identifier = "PublicGalleryNoArchiveCellCollectionViewCell"
    
    @IBOutlet weak var backgroudView: UIView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var secondTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure() {
        initUI()
    }
    
    private func initUI() {
        backgroudView.backgroundColor = .galleryGray
        
        textLabel.textColor = .darkGray
        textLabel.font = Text.style32.font
        textLabel.text = "None of your archives are public.".localized()
        
        secondTextLabel.textColor = .primary
        secondTextLabel.font = Text.style9.font
        secondTextLabel.text = "Learn how to publish an archive".localized()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
