//
//  ShareManagementEmptySpaceCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.11.2022.
//

import UIKit

class ShareManagementEmptySpaceCollectionViewCell: UICollectionViewCell {
    static let identifier = "ShareManagementEmptySpaceCollectionViewCell"

    @IBOutlet weak var emptyView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .backgroundPrimary
        emptyView.backgroundColor = .backgroundPrimary
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
