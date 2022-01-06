//
//  GridViewCell.swift
//  Permanent
//
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
}
