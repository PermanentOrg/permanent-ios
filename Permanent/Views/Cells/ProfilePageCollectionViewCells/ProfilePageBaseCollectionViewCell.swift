//
//  ProfilePageBaseCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 10.11.2021.
//

import UIKit

class ProfilePageBaseCollectionViewCell: UICollectionViewCell {
    
    var cellType: ProfilePageViewController.CellType?
    
    var title: String {
        switch cellType {
            
        default: return ""
        }
    }
    
    func configure(type: ProfilePageViewController.CellType) {
        self.cellType = type
    }
}
