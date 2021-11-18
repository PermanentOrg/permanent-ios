//
//  ProfilePageMenuCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 10.11.2021.
//

import UIKit

class ProfilePageMenuCollectionViewCell: ProfilePageBaseCollectionViewCell {
   
    static let identifier = "ProfilePageMenuCollectionViewCell"
    
    var segmentedControlAction: ((ProfilePageMenuCollectionViewCell) -> Void)?
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        segmentedControl.setTitle("Public Archive".localized(), forSegmentAt: 0)
        segmentedControl.setTitle("Public Profile".localized(), forSegmentAt: 1)
        segmentedControl.backgroundColor = .white
        segmentedControl.tintColor = .black
        if #available(iOS 13.0, *) {
            segmentedControl.selectedSegmentTintColor = .primary
        }
        
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: Text.style8.font], for: .selected)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.primary, .font: Text.style8.font], for: .normal)
    }
    
    @IBAction func segmentedControlAction(_ sender: Any) {
        if let segmentedControlAction = segmentedControlAction {
            segmentedControlAction(self)
        }
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
