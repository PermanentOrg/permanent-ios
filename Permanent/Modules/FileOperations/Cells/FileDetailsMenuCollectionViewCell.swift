//
//  FileDetailsMenuCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.03.2021.
//

import UIKit

class FileDetailsMenuCollectionViewCell: FileDetailsBaseCollectionViewCell {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
        
    var segmentedControlAction: ((FileDetailsMenuCollectionViewCell) -> Void)?
    
    static let identifier = "FileDetailsMenuCollectionViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()

        segmentedControl.setTitle("Info".localized(), forSegmentAt: 0)
        segmentedControl.setTitle("Details".localized(), forSegmentAt: 1)
        segmentedControl.backgroundColor = .darkGray
        segmentedControl.tintColor = .clear
        segmentedControl.selectedSegmentTintColor = .black
        
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: TextFontStyle.style9.font], for: .selected)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: TextFontStyle.style9.font], for: .normal)
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
