//
//  TagsNamesCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 13.04.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
                let cellWidth : CGFloat = 50;
        
                let numberOfCells = floor(self.frame.width / cellWidth);
                let edgeInsets = (self.frame.width - (numberOfCells * cellWidth)) / (numberOfCells + 1);
        
                return UIEdgeInsets(top: 0, left: 0, bottom: 60.0, right: 2 * edgeInsets);
  //      return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let letter_number = tagNames?[indexPath.row].count { return CGSize(width: 30 + (letter_number * 8) , height: 30) }
        return CGSize(width: 0, height: 0)
    }
        
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
//
//        let cellWidth : CGFloat = 110;
//
//        let numberOfCells = floor(self.frame.width / cellWidth);
//        let edgeInsets = (self.frame.width - (numberOfCells * cellWidth)) / (numberOfCells + 1);
//
//        return UIEdgeInsets(top: 0, left: edgeInsets, bottom: 60.0, right: edgeInsets);
//    }

}
