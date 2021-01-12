//  
//  SharePreviewViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 08.01.2021.
//

import UIKit

class SharePreviewViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet var archiveImage: UIImageView!
    @IBOutlet var headerView: UIView!
    @IBOutlet var shareNameLabel: UILabel!
    @IBOutlet var archiveNameLabel: UILabel!
    @IBOutlet var sharedByLabel: UILabel!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var actionButton: RoundedButton!
    
    var viewModel: SharePreviewViewModelDelegate! {
        didSet {
            viewModel.viewDelegate = self
        }
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setupCollectionView()
        viewModel.start()
    }

    fileprivate func configureUI() {
        navigationItem.title = "Share preview"
        view.backgroundColor = .middleGray
     
        headerView.backgroundColor = .backgroundPrimary
        collectionView.backgroundColor = .backgroundPrimary
        
        shareNameLabel.text = "Permanent illustrations"
        shareNameLabel.textColor = .black
        shareNameLabel.font = Text.style18.font
        
        sharedByLabel.text = "Shared by Brandon Wilson"
        sharedByLabel.textColor = .textPrimary
        sharedByLabel.font = Text.style12.font
        
        archiveNameLabel.text = "From the Brandon Wilson Archive"
        archiveNameLabel.textColor = .textPrimary
        archiveNameLabel.font = Text.style19.font
        
        
        archiveImage.backgroundColor = .primary
        archiveImage.clipsToBounds = true
        archiveImage.layer.cornerRadius = 30
        
        actionButton.configureActionButtonUI(title: "request access")
    }
    
    fileprivate func setupCollectionView() {
        collectionView.register(UINib(nibName: FileLargeCollectionViewCell.reuseIdentifier, bundle: nil),
                                forCellWithReuseIdentifier: FileLargeCollectionViewCell.reuseIdentifier)
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets.init(top: 5, left: 2, bottom: 5, right: 2)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        collectionView.collectionViewLayout = flowLayout
    }
    
    // MARK: - Actions
    
    @IBAction func previewAction(_ sender: UIButton) {
        // TODO
    }
    
}

// MARK: - UICollectionView Delegates

extension SharePreviewViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FileLargeCollectionViewCell.reuseIdentifier,
                for: indexPath
        ) as? FileLargeCollectionViewCell else {
            fatalError()
        }
        
        cell.file = viewModel.itemFor(row: indexPath.row)
        return cell
    }
}

extension SharePreviewViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let noOfCellsInRow = Constants.Design.numberOfGridItemsPerRow
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        
        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))
        
        
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))
        
        return CGSize(width: size, height: size)
    }
}

// MARK: ViewModel Delegate

extension SharePreviewViewController: SharePreviewViewModelViewDelegate {
    
    func updateScreen(status: RequestStatus) {
        
        switch status {
        case.success: collectionView.reloadData()
        case .error(let error): print(error)
            // TODO: Move showError alert to UIVC extension
        }
    }
    
}
