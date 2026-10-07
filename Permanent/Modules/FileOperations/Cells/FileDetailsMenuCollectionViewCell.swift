//
//  FileDetailsMenuCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.03.2021.
//

import UIKit

class FileDetailsMenuCollectionViewCell: FileDetailsBaseCollectionViewCell {

    @IBOutlet weak var segmentedControl: SlidingTabControl!
        
    var segmentedControlAction: ((FileDetailsMenuCollectionViewCell) -> Void)?
    
    static let identifier = "FileDetailsMenuCollectionViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()

        segmentedControl.titles = ["Info".localized(), "Details".localized()]
        segmentedControl.backgroundColor = .darkGray
        segmentedControl.pillColor = .black
        segmentedControl.titleColor = .white
        segmentedControl.titleFont = TextFontStyle.style9.font
        segmentedControl.selectedTitleFont = TextFontStyle.style9.font
        segmentedControl.accessibilityIdentifier = "fileDetailsSegmentedControl"
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
