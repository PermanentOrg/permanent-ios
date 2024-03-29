//
//  GridViewCell.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 25.08.2021.
//

import UIKit

class GridViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    
    var representedAssetIdentifier: String!
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    
    @IBOutlet weak var selectedImage: UIImageView!
    @IBOutlet weak var selectedView: UIView!
    
    override var isSelected: Bool {
        didSet {
            selectedImage.isHidden = !isSelected
            selectedView.isHidden = !isSelected
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    func configure() {
        selectedImage.image = UIImage(systemName: "checkmark.circle.fill")
        selectedImage.tintColor = .primary
        selectedImage.backgroundColor = .white
        selectedImage.contentMode = .scaleAspectFill
        selectedImage.layer.masksToBounds = true
        selectedImage.layer.shouldRasterize = true
        selectedImage.layer.cornerRadius = selectedImage.frame.height / 2
    }
}
