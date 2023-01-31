//
//  ArchiveSettingsTagsHeaderCollectionView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.01.2023.
//

import UIKit

class ArchiveSettingsTagsHeaderCollectionView: UICollectionReusableView {
    static let identifier = "ArchiveSettingsTagsHeaderCollectionView"
    static let kind = UICollectionView.elementKindSectionHeader
    
    @IBOutlet weak var tagsHeaderLabel: UILabel!
    @IBOutlet weak var selectCheckBoxButton: UIButton!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var smallArrowButton: UIButton!
    @IBOutlet weak var sortOrderButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initUI()
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func initUI() {
        tagsHeaderLabel.font = Text.style34.font
        tagsHeaderLabel.textColor = .darkBlue
        
        selectCheckBoxButton.setImage(UIImage(named: "checkBoxChecked")?.withRenderingMode(.alwaysTemplate), for: .normal)
        selectCheckBoxButton.tintColor = .darkBlue
        
        let selectAttributedText = NSAttributedString(string: "Select".localized(), attributes: [.foregroundColor: UIColor.darkBlue, .font: Text.style34.font])
        selectButton.setAttributedTitle(selectAttributedText, for: .normal)
    
        let clearAttributedText = NSAttributedString(string: "Clear".localized(), attributes: [.foregroundColor: UIColor.paleRed, .font: Text.style34.font])
        clearButton.setAttributedTitle(clearAttributedText, for: .normal)
        
        smallArrowButton.setImage(UIImage(named: "arrowDownSmall")?.withRenderingMode(.alwaysTemplate), for: .normal)
        smallArrowButton.tintColor = .darkBlue
        
        sortOrderButton.setImage(UIImage(named: "arrowDownAZ")?.withRenderingMode(.alwaysTemplate), for: .normal)
        sortOrderButton.tintColor = .darkBlue
        
        smallArrowButton.isHidden = true
        sortOrderButton.isHidden = true
        selectCheckBoxButton.isHidden = true
        selectButton.isHidden = true
        clearButton.isHidden = true
    }
    
    func configure() {
        
    }
}