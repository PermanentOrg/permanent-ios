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

    /// Stored so it can be removed — a block observer with a strong capture is retained
    /// (with everything it captures) by NotificationCenter until explicitly removed, so
    /// each reused/reconfigured cell would otherwise leak and keep reloading a dead view.
    private var didChangeQueryObserver: NSObjectProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()

        collectionView.register(UINib(nibName: TagCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: TagCollectionViewCell.identifier)
    }

    func configure(withViewModel viewModel: SearchFilesViewModel) {
        self.viewModel = viewModel

        viewModel.getTags() { [weak self] status in
            self?.collectionView.reloadData()
        }

        // Cells are reused; drop any prior subscription before adding a new one.
        if let observer = didChangeQueryObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        didChangeQueryObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name("SearchFilesViewModel.didChangeQuery"), object: viewModel, queue: nil) { [weak self] _ in
            self?.collectionView.reloadData()
        }
    }

    deinit {
        if let observer = didChangeQueryObserver {
            NotificationCenter.default.removeObserver(observer)
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

            // Full reload, not reloadItems(at:): mutating selectedTagVOs resets the
            // view model's searchQuery, which changes filteredTags.count — a partial
            // reload against a changed item count crashes with NSInternalInconsistencyException.
            collectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        // Read filteredTags (the data source used by numberOfItems/cellForItem), NOT the
        // unfiltered tagVOs — indexing the wrong array desynced sizing from the layout and
        // could read out of bounds when a query is active.
        if let filtered = viewModel?.filteredTags, filtered.indices.contains(indexPath.row) {
            let tag = filtered[indexPath.row]
            let isChecked = viewModel?.selectedTagVOs.map({ $0.name ?? "" }).contains(tag.name) ?? false
            let additionalSpace: CGFloat = isChecked ? ( 45 ) : ( 35 )
            let attributedName = NSAttributedString(string: tag.name ?? "", attributes: [NSAttributedString.Key.font: TextFontStyle.style2.font as Any])
            let width = attributedName.boundingRect(with: CGSize(width: collectionView.bounds.width, height: 30), options: [], context: nil).size.width
            return CGSize(width: additionalSpace + width , height: 40)
        }
        return CGSize(width: 0, height: 0)
    }
}
