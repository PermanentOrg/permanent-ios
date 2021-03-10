//
//  FileDetailsMenuCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.03.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class FileDetailsMenuCollectionViewCell: UICollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

    }

    @IBOutlet weak var segmentedControl: UISegmentedControl!
        
    var segmentedControlAction: SegmentedViewValueChanged?
    
    static let identifier = "FileDetailsMenuCollectionViewCell"

    func configure(leftMenuTitle: String,rightMenuTitle: String) {
        
        segmentedControl.setTitle(leftMenuTitle, forSegmentAt: 0)
        segmentedControl.setTitle(rightMenuTitle, forSegmentAt: 1)
        segmentedControl.backgroundColor = .darkGray
        segmentedControl.tintColor = .clear
        if #available(iOS 13.0, *) {
            segmentedControl.selectedSegmentTintColor = .black
        } else {
            // Fallback on earlier versions
        }
        
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: Text.style11.font], for: .selected)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black, .font: Text.style8.font], for: .normal)
        
     //   segmentedControl.layer.cornerRadius = 5.0
     //   segmentedControl.tintColor = .black

    }
    @IBAction func segmentedControlAction(_ sender: Any) {
        segmentedControlAction?(self)
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
