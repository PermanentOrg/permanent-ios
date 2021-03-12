//
//  FileDetailsMenuCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.03.2021.
//

import UIKit

class FileDetailsMenuCollectionViewCell: UICollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

    }

    @IBOutlet weak var segmentedControl: UISegmentedControl!
        
    var segmentedControlAction: ((FileDetailsMenuCollectionViewCell) -> Void)?
    
    static let identifier = "FileDetailsMenuCollectionViewCell"

    func configure(leftMenuTitle: String,rightMenuTitle: String) {
        
        segmentedControl.setTitle(leftMenuTitle, forSegmentAt: 0)
        segmentedControl.setTitle(rightMenuTitle, forSegmentAt: 1)
        segmentedControl.backgroundColor = .darkGray
        segmentedControl.tintColor = .clear
        if #available(iOS 13.0, *) {
            segmentedControl.selectedSegmentTintColor = .black
        }
        
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: Text.style9.font], for: .selected)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: Text.style9.font], for: .normal)
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
