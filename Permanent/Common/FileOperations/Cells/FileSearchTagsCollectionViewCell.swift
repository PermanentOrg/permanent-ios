//
//  FileSearchTagsCollectionViewCell.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 18.11.2021.
//

import UIKit

class FileSearchTagsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var viewModel: SearchFilesViewModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collectionView.register(UINib(nibName: TagCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: TagCollectionViewCell.identifier)
    }
    
    func configure(withViewModel viewModel: SearchFilesViewModel) {
        self.viewModel = viewModel
        
        viewModel.getTags() { status in
            self.collectionView.reloadData()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("SearchFilesViewModel.didChangeQuery"), object: viewModel, queue: nil) { notification in
            self.collectionView.reloadData()
        }
    }
    
}

extension FileSearchTagsCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.filteredTags.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionViewCell.identifier, for: indexPath) as! TagCollectionViewCell
        
        if let tag = viewModel?.filteredTags[indexPath.row] {
            let tagName = tag.name ?? ""
            let isChecked = viewModel?.selectedTagVOs.map({ $0.name ?? "" }).contains(tag.name) ?? false
            cell.configure(name: tagName, isChecked: isChecked, backgroundColor: .lightPurple)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let tag = viewModel?.filteredTags[indexPath.row] {
            if viewModel?.selectedTagVOs.map({ $0.name ?? "" }).contains(tag.name) ?? false {
                viewModel?.selectedTagVOs.removeAll(where: { $0.name == tag.name })
            } else {
                viewModel?.selectedTagVOs.append(tag)
            }
            
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if let tag = viewModel?.tagVOs[indexPath.row],
           let isChecked = viewModel?.selectedTagVOs.map({ $0.name ?? "" }).contains(tag.name) {
            let additionalSpace: CGFloat = isChecked ? ( 45 ) : ( 35 )
            let attributedName = NSAttributedString(string: tag.name ?? "", attributes: [NSAttributedString.Key.font: TextFontStyle.style2.font as Any])
            let width = attributedName.boundingRect(with: CGSize(width: collectionView.bounds.width, height: 30), options: [], context: nil).size.width
            return CGSize(width: additionalSpace + width , height: 40)
        }
        return CGSize(width: 0, height: 0)
    }
}
