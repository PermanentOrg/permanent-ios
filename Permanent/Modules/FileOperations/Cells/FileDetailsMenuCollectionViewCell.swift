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
        segmentedControl.backgroundColor = UIColor.white.withAlphaComponent(0.32)
        segmentedControl.pillColor = .black
        segmentedControl.titleColor = .white
        segmentedControl.selectedTitleColor = .white
        let tabFont = UIFont(name: "Usual-Medium", size: 10) ?? .systemFont(ofSize: 10, weight: .medium)
        segmentedControl.titleFont = UIFontMetrics(forTextStyle: .caption2).scaledFont(for: tabFont)
        segmentedControl.selectedTitleFont = segmentedControl.titleFont
        segmentedControl.trackHeight = 40
        segmentedControl.trackCornerRadius = 12
        segmentedControl.pillCornerRadius = 8
        segmentedControl.uppercasesTitles = true
        segmentedControl.titleKerning = 1.6
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
