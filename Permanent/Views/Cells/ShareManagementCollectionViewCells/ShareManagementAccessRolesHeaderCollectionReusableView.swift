//
//  ShareManagementAccessRolesHeaderCollectionReusableView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.11.2022.
//

import UIKit

class ShareManagementAccessRolesHeaderCollectionReusableView: UICollectionReusableView {
    static let identifier = "ShareManagementAccessRolesHeaderCollectionReusableView"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
