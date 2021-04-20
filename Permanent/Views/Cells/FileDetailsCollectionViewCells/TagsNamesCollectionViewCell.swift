//
//  TagsNamesCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 13.04.2021.
//

import UIKit

class TagsNamesCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "TagsNamesCollectionViewCell"
    var tagNames: [String]?
    
    @IBOutlet weak var cellTitleLabel: UILabel!
    @IBOutlet weak var tagsNameCollectionView: UICollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tagsNameCollectionView.register(UINib(nibName: TagCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: TagCollectionViewCell.identifier)
        
        let layout = UICollectionViewFlowLayout()
        self.tagsNameCollectionView?.collectionViewLayout = layout
        
        self.tagsNameCollectionView.dataSource = self
        self.tagsNameCollectionView.delegate = self
        
        tagsNameCollectionView.backgroundColor = .clear
        tagsNameCollectionView.indicatorStyle = .white
        tagsNameCollectionView.isUserInteractionEnabled = false
        
        cellTitleLabel.text = "Tags".localized()
        cellTitleLabel.textColor = .white
        cellTitleLabel.font = Text.style9.font
        
        let columnLayout = CustomViewFlowLayout()
        columnLayout.cellSpacing = 5
        self.tagsNameCollectionView.collectionViewLayout = columnLayout
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
      
    func configure(tagNames: [String]) {
        self.tagNames = tagNames
        tagsNameCollectionView.reloadData()
    }
    
    func setBackgroudColor(color: UIColor = .white) {

    }
}

extension TagsNamesCollectionViewCell: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tagNames?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionViewCell.identifier, for: indexPath) as! TagCollectionViewCell
        
        if let tagName = tagNames?[indexPath.row] {
            cell.configure(name: tagName, font: Text.style8.font, fontColor: .white, cornerRadius: 5)
            cell.setBackgroudColor(color: .darkGray)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if  let name = tagNames?[indexPath.row] {
            
            let attributedName = NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: cellTitleLabel.font as Any])
            let width = attributedName.boundingRect(with: CGSize(width: 300, height: 30), options: [], context: nil).size.width
            return CGSize(width: 15 + width , height: 30)
        }
        return CGSize(width: 0, height: 0)
    }
}
